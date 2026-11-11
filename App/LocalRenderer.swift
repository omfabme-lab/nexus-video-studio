import Foundation
import UIKit
import Kadr
import StudioCore

// Boundary for a future render-node adapter. Projects contain relative media IDs;
// no server addresses, API credentials or upload behavior are embedded in the model.
@MainActor
protocol StudioRendering {
    func render(project: StudioProject, directory: URL, preview: Bool,
                progress: @escaping @MainActor (Double) -> Void) async throws -> URL
    func cancel()
}

@MainActor
final class LocalRenderer: StudioRendering {
    private var activeExporter: Exporter?
    func cancel() { activeExporter?.cancel() }
    func render(project: StudioProject, directory: URL, preview: Bool,
                progress: @escaping @MainActor (Double) -> Void) async throws -> URL {
        try project.validate()
        #if targetEnvironment(simulator)
        if project.captionsEnabled {
            throw ProjectError.invalid("Kadr caption export needs a physical device: its upstream Core Animation overlay path is unsupported in Simulator. Disable captions for simulator media checks.")
        }
        #endif
        let width = preview ? 540 : 1080
        let height = preview ? 960 : 1920
        var clips: [any Clip] = []
        for (index, scene) in project.scenes.enumerated() {
            try Task.checkCancellation()
            if index > 0 && project.dissolves {
                clips.append(Transition.dissolve(duration: Timeline.transitionDuration(from: project.scenes[index - 1], to: scene)))
            }
            if let media = scene.media, media.kind == .video {
                let url = try checkedURL(media.filename, in: directory)
                clips.append(VideoClip(url: url)
                    .trimmed(to: scene.trimStart...(scene.trimStart + scene.effectiveDuration))
                    .volume(project.sourceAudio ? 1 : 0))
            } else {
                let image: UIImage
                if let media = scene.media {
                    let url = try checkedURL(media.filename, in: directory)
                    guard let loaded = UIImage(contentsOfFile: url.path) else { throw ProjectError.invalid("A photo could not be loaded. Import it again.") }
                    image = loaded
                } else { image = KeyframeArt.image(index: scene.artwork) }
                let startScale: Double = scene.motion == .pull ? 1.12 : 1
                let endScale: Double = scene.motion == .push ? 1.12 : (scene.motion == .drift ? 1.08 : 1)
                let endPosition: Position = scene.motion == .drift ? .normalized(x: 0.53, y: 0.5) : .center
                let animation = Kadr.Animation<Transform>.keyframes([
                    .at(0, value: Transform(scale: startScale)),
                    .at(scene.effectiveDuration, value: Transform(center: endPosition, scale: endScale))
                ], timing: .easeInOut)
                clips.append(ImageClip(image, duration: scene.effectiveDuration).transform(Transform(scale: startScale), animation: animation))
            }
        }
        var video = Video { for clip in clips { clip } }
            .preset(.custom(width: width, height: height, frameRate: 30, codec: .h264))
            // Force the full composition path even for one still. Kadr's single-
            // image shortcut does not apply motion or a complete multi-track mix.
            .crop(at: .center, size: .normalized(width: 1, height: 1))
        if project.captionsEnabled {
            for (scene, window) in zip(project.scenes, project.timeline) where !scene.caption.isEmpty {
                video = video.overlay(TextOverlay(Self.wrapped(String(scene.caption.prefix(80))), style: TextStyle(
                    fontSize: Double(width) * 0.042, color: .white, alignment: .center, weight: .bold,
                    shadow: TextShadow(offset: CGSize(width: 0, height: 2), blur: 6, color: .black)
                )).size(.normalized(width: 0.88, height: 0.18))
                    .position(.normalized(x: 0.5, y: 0.80)).visible(during: window.start...window.captionEnd))
            }
        }
        if let name = project.music {
            let url = try checkedURL(name, in: directory)
            video = video.audio { AudioTrack(url: url).volume(project.musicVolume).duration(project.duration).fadeIn(0.5).fadeOut(1.0) }
        }
        if let name = project.narration {
            let url = try checkedURL(name, in: directory)
            video = video.audio { AudioTrack(url: url).volume(project.narrationVolume).duration(project.duration) }
        }
        let output = directory.appendingPathComponent("\(preview ? "Review" : "NexusFilm")-\(UUID().uuidString).mp4")
        let exporter = video.exporter(to: output)
        activeExporter = exporter
        defer { activeExporter = nil }
        do {
            for try await state in exporter.run() {
                try Task.checkCancellation(); progress(state.fractionCompleted)
            }
            try Task.checkCancellation()
            progress(1); return output
        } catch {
            exporter.cancel(); try? FileManager.default.removeItem(at: output); throw error
        }
    }
    private func checkedURL(_ name: String, in directory: URL) throws -> URL {
        guard StudioProject.safeFilename(name) else { throw ProjectError.invalid("Invalid media path.") }
        let url = directory.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else { throw ProjectError.invalid("Missing media: \(name). Reimport it into the scene.") }
        return url
    }
    static func wrapped(_ text: String) -> String {
        var lines: [String] = []; var line = ""
        for word in text.split(separator: " ") {
            if line.count + word.count + 1 > 32 && !line.isEmpty { lines.append(line); line = "" }
            line += (line.isEmpty ? "" : " ") + word
        }
        if !line.isEmpty { lines.append(line) }
        return lines.joined(separator: "\n")
    }
}
