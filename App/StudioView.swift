import SwiftUI
import AVKit
import UniformTypeIdentifiers
import ImageIO
import StudioCore

struct StudioView: View {
    @EnvironmentObject private var studio: StudioStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var editing: StudioCore.Scene?
    @State private var showInfo = false
    @State private var showFiles = false
    @State private var showPhotos = false
    @State private var showCamera = false
    @State private var showShare = false
    @State private var replaceAction: String?
    @State private var audioImport: String?
    @State private var importTarget: UUID?
    private var locked: Bool { studio.busy || studio.isRecording }
    var body: some View {
        ZStack {
            StudioTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 15) {
                    header
                    briefPanel
                    storyboardPanel
                    cameraPanel
                    aiPanel
                    renderPanel
                    editPanel
                    Text("LOCAL BY DESIGN  /  MADE FOR YOUR NEXT FILM")
                        .font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1.5)
                        .foregroundStyle(StudioTheme.muted).padding(.vertical, 12)
                }.padding(.horizontal, 18).padding(.vertical, 18)
            }
        }.foregroundStyle(StudioTheme.ivory)
            .onChange(of: studio.project) { _, _ in studio.changed() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { studio.save(); studio.player?.pause() }
            }
            .sheet(item: $editing) { scene in SceneEditor(sceneID: scene.id).environmentObject(studio) }
            .sheet(isPresented: $showInfo) { CapabilitiesView() }
            .sheet(isPresented: $showShare) { if let url = studio.exportURL { ShareSheet(url: url) } }
            .sheet(isPresented: $showPhotos) {
                PhotoLibraryPicker { result in
                    showPhotos = false
                    if let result {
                        switch result {
                        case .success(let url): Task { await studio.importFile(url, target: importTarget); try? FileManager.default.removeItem(at: url) }
                        case .failure(let error): studio.error = error.localizedDescription
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCapture { url in
                    showCamera = false
                    if let url { Task { await studio.importFile(url, target: importTarget) } }
                }.ignoresSafeArea()
            }
            .fileImporter(isPresented: $showFiles, allowedContentTypes: audioImport == nil ? [.image, .movie] : [.audio], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls): if let url = urls.first { Task { await studio.importFile(url, audio: audioImport, target: importTarget) } }
                case .failure(let error): studio.error = error.localizedDescription
                }
            }
            .alert("Studio needs your attention", isPresented: Binding(get: { studio.error != nil }, set: { if !$0 { studio.error = nil } })) {
                Button("OK", role: .cancel) { studio.error = nil }
            } message: { Text(studio.error ?? "") }
            .confirmationDialog("Replace the current storyboard? Imported files stay in the Studio folder.", isPresented: Binding(get: { replaceAction != nil }, set: { if !$0 { replaceAction = nil } }), titleVisibility: .visible) {
                Button("Replace storyboard", role: .destructive) {
                    let action = replaceAction; replaceAction = nil
                    if action == "ai" { Task { await studio.assist() } }
                    else if action == "new" { studio.startNew() }
                    else { studio.generateStoryboard() }
                }
            }
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("PRIVATE WORKSPACE", systemImage: "circle.fill")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.6).foregroundStyle(StudioTheme.mint)
                Spacer()
                Button { showInfo = true } label: { Image(systemName: "info.circle").frame(width: 44, height: 44) }.accessibilityLabel("Capabilities and limitations")
            }
            HStack(spacing: 13) {
                Image(systemName: "square.3.layers.3d").font(.system(size: 38, weight: .light)).foregroundStyle(StudioTheme.mint)
                VStack(alignment: .leading, spacing: 1) {
                    Text("NEXUS").font(.system(size: 25, weight: .heavy, design: .rounded)).tracking(3)
                    Text("VIDEO STUDIO").font(.system(size: 21, weight: .bold, design: .rounded)).tracking(2).foregroundStyle(StudioTheme.amber)
                }
                Spacer(minLength: 0)
            }
            HStack {
                Text("From a spark to a finished film.").font(.subheadline).foregroundStyle(StudioTheme.muted)
                Spacer()
                Menu { Button("New project", role: .destructive) { replaceAction = "new" } } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }.disabled(locked)
            }
        }
    }
    private var briefPanel: some View {
        StudioPanel("BRIEF", detail: "01 / THE IDEA") {
            TextField("Describe your film…", text: $studio.project.brief, axis: .vertical)
                .lineLimit(3...6).font(.subheadline).padding(12)
                .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel("Film brief").disabled(locked)
            HStack {
                Label("9:16 · 30 FPS", systemImage: "rectangle.portrait").font(.caption.monospaced()).foregroundStyle(StudioTheme.muted)
                Spacer()
                Button("Build storyboard") { replaceAction = "template" }.buttonStyle(StudioButton(prominent: true)).disabled(locked)
            }
        }
    }
    private var storyboardPanel: some View {
        StudioPanel("STORYBOARD", detail: "\(studio.project.scenes.count) SHOTS") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                ForEach(Array(studio.project.scenes.enumerated()), id: \.element.id) { index, scene in
                    Button {
                        studio.selectedID = scene.id; editing = scene
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            SceneThumbnail(scene: scene, root: studio.root)
                                .frame(height: 83).clipped()
                                .overlay(alignment: .topLeading) {
                                    Text(String(format: "%02d", index + 1)).font(.system(size: 9, weight: .bold, design: .monospaced)).padding(5).background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 4)).padding(5)
                                }
                            Text(scene.title).font(.system(size: 10, weight: .semibold)).lineLimit(1).padding(.horizontal, 6)
                            HStack(spacing: 4) {
                                Circle().fill(StudioTheme.mint).frame(width: 4, height: 4)
                                Text(String(format: "%.1fs", scene.effectiveDuration)).font(.system(size: 9, design: .monospaced))
                                Spacer(minLength: 0)
                                Image(systemName: scene.media?.kind == .video ? "film" : "photo").font(.system(size: 9))
                            }.foregroundStyle(StudioTheme.muted).padding(.horizontal, 6).padding(.bottom, 8)
                        }.background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(studio.selectedID == scene.id ? StudioTheme.mint : StudioTheme.mint.opacity(0.2), lineWidth: 0.8))
                    }.buttonStyle(.plain).disabled(locked).accessibilityLabel("Edit shot \(index + 1), \(scene.title)")
                }
            }
            HStack {
                Text("Tap a shot to trim, caption or reorder.").font(.caption2).foregroundStyle(StudioTheme.muted)
                Spacer()
                Button { studio.addScene() } label: { Image(systemName: "plus").frame(width: 44, height: 44) }.disabled(locked || studio.project.scenes.count >= 12).accessibilityLabel("Add scene")
            }
        }
    }
    private var cameraPanel: some View {
        StudioPanel("CAMERA", detail: "02 / YOUR FOOTAGE") {
            HStack(spacing: 8) {
                Button { Task { await openCamera() } } label: { Label("Capture", systemImage: "video") }
                Button { importTarget = studio.selectedID; showPhotos = true } label: { Label("Photos", systemImage: "photo.on.rectangle") }
                Button { audioImport = nil; importTarget = studio.selectedID; showFiles = true } label: { Image(systemName: "folder") }.accessibilityLabel("Import photo or video from Files")
            }.buttonStyle(StudioButton()).disabled(locked)
            Text("Imports replace the selected shot. Generated stills can be imported from Photos or Files.").font(.caption2).foregroundStyle(StudioTheme.muted)
        }
    }
    private var aiPanel: some View {
        StudioPanel("ON-DEVICE AI", detail: "OPTIONAL") {
            HStack(spacing: 12) {
                Image(systemName: "cpu").font(.title).foregroundStyle(StudioTheme.mint)
                VStack(alignment: .leading, spacing: 5) {
                    Text(BriefAssistant.available ? "Text assistant ready" : "Offline template ready").font(.subheadline.weight(.semibold))
                    Text("Script ideas, not generated video.").font(.caption2).foregroundStyle(StudioTheme.muted)
                }
                Spacer(minLength: 0)
                Button { replaceAction = "ai" } label: { Image(systemName: "sparkles").frame(width: 24) }.buttonStyle(StudioButton()).disabled(locked || !BriefAssistant.available).accessibilityLabel("Draft captions with Apple on-device model")
            }
        }
    }
    private var renderPanel: some View {
        StudioPanel("RENDER", detail: "03 / THE FINAL CUT") {
            if let player = studio.player {
                VideoPlayer(player: player).aspectRatio(9 / 16, contentMode: .fit).frame(maxHeight: 340)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            HStack {
                Image(systemName: "play.rectangle.fill").font(.title).foregroundStyle(StudioTheme.mint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("PORTRAIT MASTER").font(.subheadline.weight(.bold)).foregroundStyle(StudioTheme.amber)
                    Text(String(format: "1080p  /  %.2f SEC  /  H.264", studio.project.duration)).font(.system(size: 10, design: .monospaced)).foregroundStyle(StudioTheme.muted)
                }
                Spacer()
            }
            Text(studio.notice).font(.caption).foregroundStyle(StudioTheme.muted).accessibilityAddTraits(.updatesFrequently)
            if studio.busy {
                if studio.rendering {
                    ProgressView(value: studio.progress)
                    Button("Cancel render") { studio.cancelRender() }.buttonStyle(StudioButton())
                } else { ProgressView("Preparing…") }
            } else {
                HStack {
                    Button { studio.render(preview: true) } label: { Label("Preview", systemImage: "play.fill") }
                    Button { studio.render(preview: false) } label: { Label("Export", systemImage: "arrow.up.right") }.buttonStyle(StudioButton(prominent: true))
                    if studio.exportURL != nil {
                        Button { showShare = true } label: { Image(systemName: "square.and.arrow.up") }.accessibilityLabel("Share exported film")
                    }
                }.buttonStyle(StudioButton()).disabled(studio.isRecording)
            }
        }
    }
    private var editPanel: some View {
        StudioPanel("EDIT", detail: "04 / FIND THE RHYTHM") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(studio.project.scenes) { scene in
                        Button { studio.selectedID = scene.id; editing = scene } label: {
                            SceneThumbnail(scene: scene, root: studio.root).frame(width: max(52, scene.effectiveDuration * 22), height: 52).clipped()
                                .overlay(alignment: .bottomLeading) { Text(String(format: "%.1fs", scene.effectiveDuration)).font(.system(size: 9, design: .monospaced)).padding(3).background(.black.opacity(0.7)) }
                        }.buttonStyle(.plain)
                    }
                }
            }.clipShape(RoundedRectangle(cornerRadius: 7)).disabled(locked)
            Toggle("Burn in captions", isOn: $studio.project.captionsEnabled).disabled(locked)
            Toggle("Soft dissolves", isOn: $studio.project.dissolves).disabled(locked)
            Toggle("Keep clip audio", isOn: $studio.project.sourceAudio).disabled(locked)
            audioRow("Music", name: studio.project.music, value: $studio.project.musicVolume, kind: "music")
            audioRow("Narration", name: studio.project.narration, value: $studio.project.narrationVolume, kind: "narration")
            Button { Task { await studio.toggleRecording() } } label: {
                Label(studio.isRecording ? "Stop recording" : "Record narration", systemImage: studio.isRecording ? "stop.circle.fill" : "mic")
            }.buttonStyle(StudioButton()).disabled(studio.busy)
            Text("Audio begins at 0:00 and ends with the film. Short tracks are not looped. Captions use your scene text; automatic transcription is not included.")
                .font(.caption2).foregroundStyle(StudioTheme.muted)
        }.font(.subheadline)
    }
    private func audioRow(_ title: String, name: String?, value: Binding<Double>, kind: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(title, systemImage: kind == "music" ? "waveform" : "mic.fill")
                Spacer()
                Button(name == nil ? "Add" : "Replace") { audioImport = kind; showFiles = true }
                if name != nil { Button("Remove") { if kind == "music" { studio.project.music = nil } else { studio.project.narration = nil } } }
            }
            if name != nil { Slider(value: value, in: 0...1).accessibilityLabel("\(title) volume") }
        }.disabled(locked)
    }
    private func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { studio.error = "Camera capture needs a physical iPhone."; return }
        guard await AVCaptureDevice.requestAccess(for: .video), await AVAudioApplication.requestRecordPermission() else {
            studio.error = "Allow camera and microphone access in Settings to capture video."; return
        }
        importTarget = studio.selectedID; showCamera = true
    }
}

struct SceneThumbnail: View {
    let scene: StudioCore.Scene
    let root: URL
    @State private var thumbnail: UIImage?
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: thumbnail ?? KeyframeArt.image(index: scene.artwork, size: CGSize(width: 180, height: 320)))
                .resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
        }.task(id: scene.media) {
            thumbnail = nil
            guard let media = scene.media else { return }
            let url = root.appendingPathComponent(media.filename)
            if media.kind == .image {
                if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                   let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 360
                   ] as CFDictionary) { thumbnail = UIImage(cgImage: cg) }
            }
            else {
                let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
                generator.appliesPreferredTrackTransform = true; generator.maximumSize = CGSize(width: 320, height: 320)
                do {
                    let result = try await generator.image(at: .zero)
                    thumbnail = UIImage(cgImage: result.image)
                } catch { thumbnail = nil }
            }
        }
    }
}
