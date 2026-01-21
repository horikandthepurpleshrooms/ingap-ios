import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            ZStack {
                switch viewModel.currentStep {
                case 0:
                    LandingView(viewModel: viewModel)
                        .transition(.slide)
                case 1:
                    BusyScheduleView(viewModel: viewModel)
                        .transition(.opacity)
                case 2:
                    PlanResultView(viewModel: viewModel)
                        .transition(.move(edge: .trailing))
                default:
                    EmptyView()
                }
            }
            .animation(.default, value: viewModel.currentStep)
        }
    }
}

#Preview {
    ContentView()
}
