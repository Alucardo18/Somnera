import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var dashboard = DashboardViewModel()
    @AppStorage("somnera_is_mecenas") private var isMecenas = false
    @State private var showSponsorWelcome = false

    var body: some View {
        TabView(selection: $appState.currentTab) {
            DashboardView(viewModel: dashboard)
                .tabItem {
                    Label("Inicio", systemImage: "moon.stars.fill")
                }
                .tag(AppTab.dashboard)

            SessionListView(viewModel: dashboard)
                .tabItem {
                    Label("Sesiones", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(AppTab.sessions)

            SynergyView(viewModel: dashboard)
                .tabItem {
                    Label("Sinergia", systemImage: "sparkles")
                }
                .tag(AppTab.synergy)

            SettingsView(viewModel: dashboard)
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(.somAccent)
        .onAppear { dashboard.load() }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            guard isMecenas else { return }
            guard !showSponsorWelcome else { return }
            showSponsorWelcome = true
        }
        .sheet(isPresented: $appState.showOnboarding) {
            OnboardingView()
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showSponsorWelcome) {
            SponsorWelcomeView(isPresented: $showSponsorWelcome, autoDismissAfter: 10.0)
        }
    }
}
