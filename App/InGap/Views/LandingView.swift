import SwiftUI

struct LandingView: View {
    @ObservedObject var viewModel: AppViewModel
    @EnvironmentObject var nav: NavigationManager
    @State private var showSettings = false
    @State private var planningMode: PlanningMode = .week
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            HStack {
                Text("InGap")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            // Mode Selection
            HStack(spacing: 12) {
                ModeCard(
                    title: "Next Week",
                    isSelected: planningMode == .week
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        planningMode = .week
                        viewModel.planningMode = .week
                    }
                }
                
                ModeCard(
                    title: "Tomorrow",
                    isSelected: planningMode == .tomorrow
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        planningMode = .tomorrow
                        viewModel.planningMode = .tomorrow
                    }
                }
            }
            .padding(.horizontal)
            
            // Input Section
            VStack(alignment: .leading, spacing: 20) {
                Text(planningMode == .week ? "Focus?" : "Goal?")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                TextField(planningMode == .week ? "Master SwiftUI..." : "Biology Exam...", text: $viewModel.userTopic)
                    .textFieldStyle(MinimalTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                
                Text("We'll align this with your calendar availability.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action Button
            Button(action: {
                isTextFieldFocused = false
                Task { @MainActor in
                    if planningMode == .week {
                        withAnimation {
                            nav.push(.busySchedule)
                        }
                    } else {
                        await viewModel.generateTomorrowPlan()
                        withAnimation {
                            nav.push(.planResult)
                        }
                    }
                }
            }) {
                HStack {
                    if viewModel.isGenerating {
                        ProgressView().tint(.white)
                    } else {
                        Text(planningMode == .week ? "Next" : "Generate")
                        Image(systemName: "arrow.right")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: !viewModel.userTopic.isEmpty && !viewModel.isGenerating))
            .disabled(viewModel.userTopic.isEmpty || viewModel.isGenerating)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

struct ModeCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                        .fill(isSelected ? DesignSystem.Colors.primaryText : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                        .stroke(DesignSystem.Colors.border, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}
