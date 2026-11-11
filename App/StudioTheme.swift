import SwiftUI

enum StudioTheme {
    static let background = Color(red: 0.012, green: 0.035, blue: 0.030)
    static let panel = Color(red: 0.02, green: 0.075, blue: 0.060)
    static let mint = Color(red: 0.28, green: 0.86, blue: 0.71)
    static let amber = Color(red: 1, green: 0.72, blue: 0.35)
    static let ivory = Color(red: 0.95, green: 0.94, blue: 0.83)
    static let muted = Color(red: 0.53, green: 0.66, blue: 0.60)
}
struct StudioPanel<Content: View>: View {
    let title: String
    let detail: String
    @ViewBuilder var content: () -> Content
    init(_ title: String, detail: String = "", @ViewBuilder content: @escaping () -> Content) {
        self.title = title; self.detail = detail; self.content = content
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(.headline, design: .rounded, weight: .bold)).tracking(2).foregroundStyle(StudioTheme.amber)
                Spacer()
                Text(detail).font(.caption2.monospaced()).foregroundStyle(StudioTheme.muted)
            }
            content()
        }.padding(16).background(StudioTheme.panel.opacity(0.75), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(StudioTheme.mint.opacity(0.34), lineWidth: 0.7))
    }
}
struct StudioButton: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).padding(.horizontal, 13).frame(minHeight: 44)
            .foregroundStyle(prominent ? StudioTheme.background : StudioTheme.mint)
            .background(prominent ? StudioTheme.mint : StudioTheme.mint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(StudioTheme.mint.opacity(0.5), lineWidth: 0.7))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
