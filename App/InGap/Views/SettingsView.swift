import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @StateObject private var rateLimit = RateLimitService.shared
    @State private var showResetAlert = false
    @State private var showPaywall = false
    @State private var showResetGenerationsAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text("Settings")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            }
            .padding()
            .background(DesignSystem.Colors.background)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Premium Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SUBSCRIPTION")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(.horizontal)
                        
                        if rateLimit.isPremium {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(DesignSystem.Colors.accent)
                                Text("Premium Active")
                                Spacer()
                            }
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                                    .stroke(DesignSystem.Colors.accent, lineWidth: 1)
                            )
                            .padding(.horizontal)
                        } else {
                            Button(action: { showPaywall = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Go Premium")
                                            .font(DesignSystem.Typography.headline)
                                        Text("Unlimited generations")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "sparkles")
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                                        .stroke(DesignSystem.Colors.accent, lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(rateLimit.remainingGenerations) / 10 generations")
                                    Spacer()
                                    Button("Reset") { showResetGenerationsAlert = true }
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.accent)
                                }
                                Text("Resets on \(rateLimit.resetDate.formatted(.dateTime.weekday().month().day().year().hour(.twoDigits(amPM: .abbreviated)).minute())).")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                                    .stroke(DesignSystem.Colors.border, lineWidth: DesignSystem.strokeWidth)
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                    // General Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GENERAL")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(.horizontal)
                        
                        Button(action: { showResetAlert = true }) {
                            HStack {
                                Text("Reset Onboarding")
                                Spacer()
                                Image(systemName: "arrow.counterclockwise")
                            }
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                                    .stroke(DesignSystem.Colors.border, lineWidth: DesignSystem.strokeWidth)
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ABOUT")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(.horizontal)
                        
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                                .stroke(DesignSystem.Colors.border, lineWidth: DesignSystem.strokeWidth)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 24)
            }
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Reset Onboarding?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                hasCompletedOnboarding = false
                dismiss()
            }
        } message: {
            Text("Onboarding screens will appear on next launch.")
        }
        .alert("Reset Generations?", isPresented: $showResetGenerationsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                rateLimit.resetGenerations()
            }
        } message: {
            Text("This will reset your weekly count to 10.")
        }
    }
}
