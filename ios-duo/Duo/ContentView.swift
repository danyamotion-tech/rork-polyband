import SwiftUI

/// Root tab container: Projects, Instruments, Loops.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Projects", systemImage: "folder") {
                ProjectsView()
            }
            Tab("Instruments", systemImage: "pianokeys") {
                InstrumentsView()
            }
            Tab("Loops", systemImage: "repeat") {
                LoopsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(ProjectStore())
        .environment(AudioEngine())
        .preferredColorScheme(.dark)
}
