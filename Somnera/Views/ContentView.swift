import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var dashboard = DashboardViewModel()

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
        .sheet(isPresented: $appState.showOnboarding) {
            OnboardingView()
                .environmentObject(appState)
        }
    }
}
