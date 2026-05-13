import SwiftUI
import SwiftData

@main
struct SomneraApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [SleepSession.self])
    }
}
