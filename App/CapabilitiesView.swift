import SwiftUI

struct CapabilitiesView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Included, free and local") {
                    Label("Brief → six editable storyboard shots", systemImage: "text.alignleft")
                    Label("Photo, still-image and video import", systemImage: "photo.on.rectangle")
                    Label("Camera capture and microphone narration", systemImage: "video")
                    Label("Trims, still-image motion and dissolves", systemImage: "scissors")
                    Label("Caption overlays and two audio tracks", systemImage: "captions.bubble")
                    Label("1080 × 1920 H.264 export, no watermark", systemImage: "square.and.arrow.up")
                }
                Section("On-device AI") {
                    Text("Apple's system text model can draft captions when Apple Intelligence is enabled and available. No cloud-model call or API key is used. The offline storyboard template works without it.")
                    Text("This build does not generate AI video or diffusion images. Import generated stills from another app. No model weights are bundled or downloaded by Studio.")
                }
                Section("Know the limits") {
                    Text("One local project, 1–12 shots, up to 2 minutes. Imports are limited to 200 MB each. Portrait output center-crops media. HDR/color fidelity and unusual codecs require device testing.")
                    Text("Preview renders a 540p review file; final export is 1080p at 30 fps. This first build does not offer 4K, automatic transcription, word timing, waveform analysis, freeform multilayer editing or a PC render node.")
                    Text("Music and narration start at zero and are cut at the film end. Short tracks do not loop. Lower music volume manually under speech. Scene captions are manually authored, not speech-synchronized.")
                    Text("Keep Studio foregrounded while rendering. Files stay on this device; exports and old imported files remain in Files → Nexus Video Studio → Studio until you delete them. Back up that folder before uninstalling.")
                    Text("The free AltStore Classic route requires periodic refresh with AltServer on Windows. Apple account credentials belong only in the official AltStore/AltServer interface, never in this app or GitHub.")
                }
                Section("Credits and licenses") {
                    Text("Video engine: Kadr by Steliyan Hadzhidenev, Apache License 2.0. Source snapshot ff6c4bf2ee6663aa7ce973ee5a678c67f6d63475. Studio uses a local library-only package manifest; engine source is unmodified.")
                    NavigationLink("Kadr — Apache License 2.0") {
                        ScrollView { Text(license).font(.system(.caption, design: .monospaced)).padding() }.navigationTitle("Kadr license")
                    }
                    Text("Interface and procedural keyframes are original work for this project. SF Symbols and Apple frameworks are supplied by the operating system. No paid service or stock-media dependency is included.")
                }
            }.navigationTitle("Inside Studio").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.tint(StudioTheme.mint).preferredColorScheme(.dark)
    }
    private var license: String {
        guard let url = Bundle.main.url(forResource: "Kadr-LICENSE", withExtension: "txt"), let text = try? String(contentsOf: url, encoding: .utf8) else { return "See Vendor/Kadr/LICENSE in the source distribution." }
        return text
    }
}
