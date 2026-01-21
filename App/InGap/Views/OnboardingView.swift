import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var hasAccepted = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(imageName: "brain.head.profile", title: "Learn Smarter", description: "Personalized plans powered by on-device AI."),
        OnboardingPage(imageName: "calendar.badge.clock", title: "Fits Your Life", description: "Seamlessly integrates with your calendar."),
        OnboardingPage(imageName: "lock.shield", title: "Private", description: "Processing stays on your device. Your data is yours.")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: page.imageName)
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        VStack(spacing: 12) {
                            Text(page.title)
                                .font(DesignSystem.Typography.largeTitle)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text(page.description)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            VStack(spacing: 20) {
                if currentPage == pages.count - 1 {
                    Toggle(isOn: $hasAccepted) {
                        Text("I accept the terms of service")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.horizontal, 32)
                }
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else if hasAccepted {
                        withAnimation { hasCompletedOnboarding = true }
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: currentPage != pages.count - 1 || hasAccepted))
                .disabled(currentPage == pages.count - 1 && !hasAccepted)
            }
            .padding(.bottom, 40)
            .padding(.horizontal, 24)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .font(.system(size: 20))
                .foregroundColor(configuration.isOn ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText)
                .onTapGesture { configuration.isOn.toggle() }
            
            configuration.label
        }
    }
}
