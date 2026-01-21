import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showResetAlert = false
    
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
            
            VStack(spacing: 32) {
                // Actions
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
                
                // About
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
                
                Spacer()
            }
            .padding(.top, 24)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .alert("Reset Onboarding?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                hasCompletedOnboarding = false
                dismiss()
            }
        } message: {
            Text("Onboarding screens will appear on next launch.")
        }
    }
}
