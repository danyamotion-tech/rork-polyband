import SwiftUI

@main
struct DuoApp: App {
    @State private var store = ProjectStore()
    @State private var engine = AudioEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(engine)
                .preferredColorScheme(.dark)
                .tint(DuoTheme.accent)
        }
    }
}
