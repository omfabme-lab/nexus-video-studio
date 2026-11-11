import SwiftUI

@main
struct StudioApp: App {
    @StateObject private var studio = StudioStore()
    var body: some Scene {
        WindowGroup {
            StudioView().environmentObject(studio)
                .preferredColorScheme(.dark).tint(StudioTheme.mint)
        }
    }
}
