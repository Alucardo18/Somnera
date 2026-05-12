import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var currentTab: AppTab = .dashboard
    @Published var healthKitAuthorized: Bool = false
    @Published var showOnboarding: Bool = false

    init() {
        showOnboarding = !UserDefaults.standard.bool(forKey: "somnera_onboarding_complete")
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "somnera_onboarding_complete")
        showOnboarding = false
    }
}

enum AppTab: String, CaseIterable {
    case dashboard = "dashboard"
    case sessions  = "sessions"
    case settings  = "settings"
}
