import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import ImageIO
import StudioCore

@MainActor
final class StudioStore: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var project = StudioProject()
    @Published var selectedID: UUID?
    @Published var error: String?
    @Published var notice = "Your private, offline workspace"
    @Published var busy = false
    @Published var rendering = false
    @Published var progress = 0.0
    @Published var player: AVPlayer?
    @Published var exportURL: URL?
    @Published var isRecording = false
    let root: URL
    private var recorder: AVAudioRecorder?
    private var recordingName: String?
    private var job: Task<Void, Never>?
    private let renderer = LocalRenderer()
    private var saveTask: Task<Void, Never>?
    private var canSave = true

    override init() {
        root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Studio", isDirectory: true)
        super.init()
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let url = root.appendingPathComponent("project.json")
            if FileManager.default.fileExists(atPath: url.path) {
                let decoded = try JSONDecoder().decode(StudioProject.self, from: Data(contentsOf: url))
                try decoded.validate(forRendering: false); project = decoded
            }
        } catch {
            canSave = false
            self.error = "The saved project could not be opened. It has been preserved in Files → Nexus Video Studio → Studio. Start a new project to recover. \(error.localizedDescription)"
        }
        selectedID = project.scenes.first?.id
    }
    func changed() {
        player?.pause(); player = nil; exportURL = nil
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            save()
        }
    }
    func save() {
        guard canSave else { return }
        do {
            let data = try JSONEncoder().encode(project)
            try data.write(to: root.appendingPathComponent("project.json"), options: .atomic)
        } catch { self.error = "Could not save: \(error.localizedDescription)" }
    }
    func startNew() {
        guard !busy, !isRecording else { return }
        if !canSave {
            let old = root.appendingPathComponent("project.json")
            let backup = root.appendingPathComponent("recovery-\(UUID().uuidString).json")
            do { try FileManager.default.copyItem(at: old, to: backup) }
            catch { self.error = error.localizedDescription; return }
        }
        canSave = true; project = StudioProject(); selectedID = project.scenes.first?.id; changed()
    }
    func generateStoryboard() {
        project.scenes = Storyboard.make(brief: project.brief)
        selectedID = project.scenes.first?.id; notice = "Six editable shots · offline template"; changed()
    }
    func move(_ id: UUID, by offset: Int) {
        guard let index = project.scenes.firstIndex(where: { $0.id == id }),
              project.scenes.indices.contains(index + offset) else { return }
        project.scenes.swapAt(index, index + offset); changed()
    }
    func remove(_ id: UUID) {
        guard project.scenes.count > 1 else { return }
        project.scenes.removeAll { $0.id == id }; selectedID = project.scenes.first?.id; changed()
    }
    func addScene() {
        guard project.scenes.count < 12 else { return }
        let scene = StudioCore.Scene(title: "New scene", caption: "Your next moment", artwork: project.scenes.count)
        project.scenes.append(scene); selectedID = scene.id; changed()
    }
    func importFile(_ url: URL, audio: String? = nil, target: UUID? = nil) async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        var copied: URL?
        do {
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
            guard (values.fileSize ?? 0) < 200_000_000 else { throw ProjectError.invalid("Import a file smaller than 200 MB for this first cut.") }
            let type = values.contentType ?? UTType(filenameExtension: url.pathExtension)
            let isImage = type?.conforms(to: .image) == true
            let filename = UUID().uuidString + "." + (isImage ? "jpg" : url.pathExtension)
            let destination = root.appendingPathComponent(filename)
            copied = destination
            if isImage && audio == nil {
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceCreateThumbnailWithTransform: true,
                        kCGImageSourceThumbnailMaxPixelSize: 2400
                      ] as CFDictionary), let data = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.9) else {
                    throw ProjectError.invalid("This image could not be decoded.")
                }
                try data.write(to: destination, options: .atomic)
            } else { try FileManager.default.copyItem(at: url, to: destination) }
            if let audio {
                let asset = AVURLAsset(url: destination)
                guard !(try await asset.loadTracks(withMediaType: .audio)).isEmpty else { throw ProjectError.invalid("This file has no audio track.") }
                if audio == "music" { project.music = filename } else { project.narration = filename }
            } else {
                guard let index = project.scenes.firstIndex(where: { $0.id == (target ?? selectedID) }) else { throw ProjectError.invalid("Select a scene first.") }
                var duration = 0.0
                if !isImage {
                    let asset = AVURLAsset(url: destination)
                    guard !(try await asset.loadTracks(withMediaType: .video)).isEmpty else { throw ProjectError.invalid("Choose a photo or a video.") }
                    duration = try await asset.load(.duration).seconds
                    guard duration.isFinite, duration >= 0.5 else { throw ProjectError.invalid("Video must be at least half a second long.") }
                }
                project.scenes[index].media = Media(filename: filename, kind: isImage ? .image : .video, duration: duration)
                project.scenes[index].trimStart = 0
                if !isImage { project.scenes[index].duration = min(3.5, duration) }
            }
            notice = "Media copied safely into this project"; changed()
        } catch {
            if let copied { try? FileManager.default.removeItem(at: copied) }
            self.error = error.localizedDescription
        }
    }
    func render(preview: Bool) {
        guard !busy, !isRecording else { return }
        save(); busy = true; rendering = true; progress = 0; player?.pause()
        let snapshot = project
        notice = preview ? "Rendering a 540p review copy…" : "Rendering your 1080p film…"
        job = Task {
            defer { busy = false; rendering = false; job = nil }
            do {
                let url = try await renderer.render(project: snapshot, directory: root, preview: preview) { [weak self] fraction in
                    self?.progress = fraction
                }
                try Task.checkCancellation()
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
                try AVAudioSession.sharedInstance().setActive(true)
                player = AVPlayer(url: url)
                if !preview { exportURL = url }
                notice = preview ? "Review copy ready · captions and audio included" : "Export ready · 1080 × 1920 · no watermark"
                if preview { player?.play() }
            } catch is CancellationError { notice = "Render cancelled" }
            catch {
                if Task.isCancelled { notice = "Render cancelled" }
                else { self.error = error.localizedDescription; notice = "Render stopped" }
            }
        }
    }
    func cancelRender() { renderer.cancel(); job?.cancel() }
    func toggleRecording() async {
        if isRecording { recorder?.stop(); finishRecording(); return }
        guard !busy else { return }
        guard await AVAudioApplication.requestRecordPermission() else { error = "Allow microphone access in Settings to record narration."; return }
        do {
            player?.pause()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let name = UUID().uuidString + ".m4a"
            let recorder = try AVAudioRecorder(url: root.appendingPathComponent(name), settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            recorder.delegate = self
            guard recorder.record(forDuration: 120) else { throw ProjectError.invalid("Could not start recording.") }
            self.recorder = recorder; recordingName = name; isRecording = true
            notice = "Recording narration · stop when finished (2 minute maximum)"
        } catch { self.error = error.localizedDescription }
    }
    private func finishRecording() {
        guard isRecording else { return }
        project.narration = recordingName; isRecording = false; recorder = nil
        notice = "Narration saved · starts at the beginning of your film"; changed()
    }
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let finishedURL = recorder.url
        Task { @MainActor in
            guard self.recorder?.url == finishedURL else { return }
            if flag { finishRecording() }
            else { isRecording = false; self.recorder = nil; self.error = "Recording was interrupted. Try again." }
        }
    }
    func assist() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do {
            let captions = try await BriefAssistant.captions(for: project.brief)
            var scenes = Storyboard.make(brief: project.brief)
            for index in scenes.indices { scenes[index].caption = captions[index] }
            project.scenes = scenes; selectedID = scenes.first?.id
            notice = "On-device draft ready · review every caption"; changed()
        } catch { self.error = error.localizedDescription }
    }
}
