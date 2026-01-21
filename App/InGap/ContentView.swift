import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var navigationManager = NavigationManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            NavigationStack(path: $navigationManager.path) {
                LandingView(viewModel: viewModel)
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .busySchedule:
                            BusyScheduleView(viewModel: viewModel)
                        case .planResult:
                            PlanResultView(viewModel: viewModel)
                        case .history:
                            HistoryView()
                        }
                    }
            }
            .environmentObject(navigationManager)
        }
    }
}

#Preview {
    ContentView()
}
