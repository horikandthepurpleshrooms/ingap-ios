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
        OnboardingPage(
            imageName: "brain.head.profile",
            title: "Learn Smarter",
            description: "InTheGap uses on-device AI to create personalized learning plans tailored to your goals and schedule."
        ),
        OnboardingPage(
            imageName: "calendar.badge.clock",
            title: "Fits Your Life",
            description: "We analyze your calendar and busy times to find the perfect learning windows throughout your week."
        ),
        OnboardingPage(
            imageName: "chart.line.uptrend.xyaxis",
            title: "Stay Consistent",
            description: "Get reminders 10 minutes before each session. Build habits that stick with daily or weekly plans."
        ),
        OnboardingPage(
            imageName: "lock.shield",
            title: "Your Privacy Matters",
            description: "All AI processing happens on your device. Your learning goals and calendar data never leave your phone."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: page.imageName)
                            .font(.system(size: 80))
                            .foregroundStyle(.accent)
                            .padding(.bottom, 16)
                        
                        Text(page.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(page.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            VStack(spacing: 16) {
                if currentPage == pages.count - 1 {
                    Toggle(isOn: $hasAccepted) {
                        Text("I accept the terms and agree to use this app responsibly")
                            .font(.footnote)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.horizontal, 24)
                }
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else if hasAccepted {
                        hasCompletedOnboarding = true
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            (currentPage == pages.count - 1 && !hasAccepted)
                                ? Color.gray.opacity(0.4)
                                : Color.accentColor
                        )
                        .cornerRadius(12)
                }
                .disabled(currentPage == pages.count - 1 && !hasAccepted)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .font(.title2)
                .foregroundStyle(configuration.isOn ? Color.accentColor : Color.secondary)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}
