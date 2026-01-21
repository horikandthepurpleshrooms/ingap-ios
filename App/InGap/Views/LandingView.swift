import SwiftUI

struct LandingView: View {
    @ObservedObject var viewModel: AppViewModel
    @EnvironmentObject var nav: NavigationManager
    @State private var showSettings = false
    @State private var planningMode: PlanningMode = .week
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(colors: [Color(white: 0.98), Color(white: 0.95)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Mode Selection
                HStack(spacing: 16) {
                    ModeCard(
                        title: "Next Week",
                        icon: "calendar", 
                        isSelected: planningMode == .week
                    ) {
                        withAnimation(.spring()) {
                            planningMode = .week
                            viewModel.planningMode = .week
                        }
                    }
                    
                    ModeCard(
                        title: "Tomorrow",
                        icon: "sun.max.fill",
                        isSelected: planningMode == .tomorrow
                    ) {
                        withAnimation(.spring()) {
                            planningMode = .tomorrow
                            viewModel.planningMode = .tomorrow
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(planningMode == .week ? "What's your focus for next week?" : "What's your goal for tomorrow?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    TextField(planningMode == .week ? "e.g., Master SwiftUI Animations" : "e.g., Review for Biology Exam", text: $viewModel.userTopic)
                        .font(.headline)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                    
                    Text("We'll craft a personalized plan referencing your calendar availability.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal)
                
                Spacer()
                
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
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(planningMode == .week ? "Continue" : "Generate Plan")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        !viewModel.userTopic.isEmpty ? 
                            AnyView(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)) : 
                            AnyView(Color.gray.opacity(0.3))
                    )
                    .cornerRadius(16)
                    .shadow(color: !viewModel.userTopic.isEmpty ? Color.accentColor.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                }
                .disabled(viewModel.userTopic.isEmpty || viewModel.isGenerating)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("InTheGap")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.primary.opacity(0.7))
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

struct ModeCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                isSelected ? 
                    AnyView(Color.accentColor) : 
                    AnyView(Color.white)
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
