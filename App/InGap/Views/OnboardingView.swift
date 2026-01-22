import SwiftUI
import EventKit

enum OnboardingStep: Int, CaseIterable {
    case value = 0
    case privacy
    case aiDisclaimer
    case permissions
    case legal
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentStep: OnboardingStep = .value
    @State private var hasAcceptedTerms = false
    @StateObject private var calendarManager = CalendarManager()
    @Environment(\.scenePhase) var scenePhase
    
    // Animation States
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            
            VStack {
                // Main Content Area
                ZStack {
                    switch currentStep {
                    case .value:
                        valueStep
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    case .privacy:
                        privacyStep
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    case .aiDisclaimer:
                        aiStep
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    case .permissions:
                        permissionsStep
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    case .legal:
                        legalStep
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }
                .frame(maxHeight: .infinity)
                .id(currentStep) // Force transition on change
                
                // Footer
                VStack(spacing: 24) {
                    if currentStep == .legal {
                        Toggle(isOn: $hasAcceptedTerms) {
                            Text("I accept the Terms of Service and Privacy Policy")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        .padding(.horizontal, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(OnboardingStep.allCases, id: \.self) { step in
                            Circle()
                                .fill(step == currentStep ? DesignSystem.Colors.primaryText : DesignSystem.Colors.border)
                                .frame(width: 8, height: 8)
                                .animation(.spring, value: currentStep)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    Button(action: handleNext) {
                        Text(currentStep == .legal ? "Let's Start" : "Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: canProceed))
                    .disabled(!canProceed)
                }
                .padding(.bottom, 40)
                .padding(.horizontal, 24)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: currentStep)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                calendarManager.updateAuthorizationStatus()
            }
        }
    }
    
    // MARK: - Step Views
    
    private var valueStep: some View {
        OnboardingPageContent(
            systemIcon: "sparkles",
            headline: "Reclaim Your Time",
            bodyText: "InGap spots the hidden moments in your week to help you learn, move, and grow."
        )
    }
    
    private var privacyStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(DesignSystem.Colors.accent)
                    .symbolEffect(.bounce, value: isAnimating)
                
                Text("ON DEVICE")
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(DesignSystem.Colors.primaryText)
                    .foregroundColor(DesignSystem.Colors.background)
                    .clipShape(Capsule())
                    .offset(x: 20, y: 10)
            }
            .padding(.bottom, 20)
            .onAppear { isAnimating.toggle() }
            
            VStack(spacing: 16) {
                Text("Private by Design")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("No servers. No cloud. Your calendar data never leaves your iPhone.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            Spacer()
        }
    }
    
    private var aiStep: some View {
        OnboardingPageContent(
            systemIcon: "slider.horizontal.3",
            headline: "You're the Boss",
            bodyText: "Our AI drafts the plan, but you sign off on it. Nothing goes on your calendar without your say-so."
        )
    }
    
    private var permissionsStep: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: permissionIcon)
                .font(.system(size: 70))
                .foregroundColor(calendarManager.authStatus == .denied ? .red : DesignSystem.Colors.primaryText)
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: 16) {
                Text(permissionTitle)
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(permissionDescription)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            if calendarManager.authStatus == .denied || calendarManager.authStatus == .restricted {
                Button(action: openSettings) {
                    HStack {
                        Text("Open Settings")
                        Image(systemName: "arrow.up.forward.app")
                    }
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.accent)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(20)
                }
            } else {
                Button(action: requestPermissions) {
                    HStack {
                        Text(calendarManager.isAuthorized ? "Access Granted" : "Give Access")
                        if calendarManager.isAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(calendarManager.isAuthorized ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.accent)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(calendarManager.isAuthorized ? DesignSystem.Colors.border : Color.clear, lineWidth: 1)
                    )
                }
                .disabled(calendarManager.isAuthorized)
            }
            
            Spacer()
        }
    }
    
    private var permissionIcon: String {
        switch calendarManager.authStatus {
        case .denied, .restricted: return "hand.raised.slash.fill"
        case .authorized, .fullAccess: return "calendar.badge.checkmark"
        default: return "calendar.badge.exclamationmark"
        }
    }
    
    private var permissionTitle: String {
        switch calendarManager.authStatus {
        case .denied, .restricted: return "Access Denied"
        case .authorized, .fullAccess: return "All Set!"
        default: return "Full Calendar Access"
        }
    }
    
    private var permissionDescription: String {
        switch calendarManager.authStatus {
        case .denied, .restricted: 
            return "Calendar access was denied. Please enable it in Settings to allow the App to find gaps and write your plans."
        case .authorized, .fullAccess:
            return "Permissions granted! The App is ready to find the perfect gaps in your schedule locally on your device."
        default: 
            return "The App needs full access to find the best gaps and write your plans directly to your calendar. All processing happens locally on your device."
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private var legalStep: some View {
        OnboardingPageContent(
            systemIcon: "doc.text.fill",
            headline: "The Fine Print",
            bodyText: "Just a quick agreement to keep us both safe. Simple and standard."
        )
    }
    
    // MARK: - Logic
    
    private var canProceed: Bool {
        if currentStep == .permissions {
            return calendarManager.isAuthorized
        }
        if currentStep == .legal {
            return hasAcceptedTerms
        }
        return true
    }
    
    private func handleNext() {
        if currentStep == .legal {
            withAnimation {
                hasCompletedOnboarding = true
            }
        } else {
            let nextIndex = currentStep.rawValue + 1
            if let nextStep = OnboardingStep(rawValue: nextIndex) {
                 currentStep = nextStep
            }
        }
    }
    
    private func requestPermissions() {
        // Request Calendar
        calendarManager.requestAccess()
    }
}

// MARK: - Helper Views

struct OnboardingPageContent: View {
    let systemIcon: String
    let headline: String
    let bodyText: String
    
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: systemIcon)
                .font(.system(size: 70))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .scaleEffect(appear ? 1.0 : 0.8)
                .opacity(appear ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: appear)
            
            VStack(spacing: 16) {
                Text(headline)
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .opacity(appear ? 1.0 : 0.0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)
                
                Text(bodyText)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
                    .opacity(appear ? 1.0 : 0.0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appear)
            }
            Spacer()
        }
        .onAppear {
            appear = true
        }
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
