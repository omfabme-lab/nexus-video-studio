import SwiftUI
import StudioCore

struct SceneEditor: View {
    @EnvironmentObject private var studio: StudioStore
    @Environment(\.dismiss) private var dismiss
    let sceneID: UUID
    var body: some View {
        NavigationStack {
            if let index = studio.project.scenes.firstIndex(where: { $0.id == sceneID }) {
                editor(index: index)
            } else { Text("This shot was removed.") }
        }.tint(StudioTheme.mint).preferredColorScheme(.dark)
    }
    private func editor(index: Int) -> some View {
        let scene = studio.project.scenes[index]
        let maximum = scene.media?.kind == .video ? min(30, (scene.media?.duration ?? 0) - scene.trimStart) : 30
        return Form {
            Section {
                SceneThumbnail(scene: scene, root: studio.root).frame(height: 210).clipped()
                TextField("Shot title", text: $studio.project.scenes[index].title)
                TextField("Caption", text: $studio.project.scenes[index].caption, axis: .vertical).lineLimit(2...4)
                    .onChange(of: studio.project.scenes[index].caption) { _, new in
                        if new.count > 80 { studio.project.scenes[index].caption = String(new.prefix(80)) }
                    }
            } header: { Text("SHOT \(index + 1)") }
            Section("Timing") {
                Text(String(format: "Duration  %.1f seconds", scene.effectiveDuration))
                Slider(value: $studio.project.scenes[index].duration, in: 0.5...max(0.51, maximum), step: 0.1)
                    .accessibilityLabel("Scene duration")
                if let media = scene.media, media.kind == .video, media.duration > 0.6 {
                    Text(String(format: "Start in source  %.1f seconds", scene.trimStart))
                    Slider(value: $studio.project.scenes[index].trimStart, in: 0...max(0.1, media.duration - 0.5), step: 0.1)
                        .accessibilityLabel("Trim start")
                        .onChange(of: studio.project.scenes[index].trimStart) { _, _ in
                            studio.project.scenes[index].duration = studio.project.scenes[index].effectiveDuration
                        }
                }
            }
            if scene.media?.kind != .video {
                Section("Camera motion") {
                    Picker("Motion", selection: $studio.project.scenes[index].motion) {
                        ForEach(CameraMotion.allCases, id: \.self) { motion in Text(motion.rawValue).tag(motion) }
                    }
                }
            }
            Section("Sequence") {
                HStack {
                    Button("Move earlier") { studio.move(sceneID, by: -1) }.disabled(index == 0)
                    Spacer()
                    Button("Move later") { studio.move(sceneID, by: 1) }.disabled(index == studio.project.scenes.count - 1)
                }.buttonStyle(.borderless)
                Button("Remove shot", role: .destructive) { studio.remove(sceneID); dismiss() }.disabled(studio.project.scenes.count == 1)
            }
            Section {
                Text(scene.media == nil ? "Original procedural keyframe. This is illustrative artwork, not an AI-generated photograph. Import footage from the CAMERA panel to replace it." : "Media is stored locally. Portrait export uses a centered crop; check the preview before sharing.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.scrollContentBackground(.hidden).background(StudioTheme.background)
            .navigationTitle("Shape the shot").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { studio.save(); dismiss() } } }
    }
}
