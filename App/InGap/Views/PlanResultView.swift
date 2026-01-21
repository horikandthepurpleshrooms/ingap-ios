import SwiftUI

struct PlanResultView: View {
    @ObservedObject var viewModel: AppViewModel
    @EnvironmentObject var nav: NavigationManager
    @State private var showingAlert = false
    
    private var titleText: String {
        viewModel.planningMode == .week ? "Your Plan" : "Tomorrow"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { nav.pop() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                Spacer()
                Text(titleText)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Spacer()
                Color.clear.frame(width: 24, height: 24)
            }
            .padding()
            .background(DesignSystem.Colors.background)
            
            // Content
            List(viewModel.generatedPlan) { plan in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.date.formatted(.dateTime.weekday().day().month()))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .textCase(.uppercase)
                        Spacer()
                        Text("\(Int(plan.duration/60)) min")
                            .font(DesignSystem.Typography.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.surface)
                            .cornerRadius(4)
                    }
                    
                    Text(plan.activity)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if !plan.details.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(plan.details, id: \.self) { detail in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(DesignSystem.Colors.secondaryText)
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 6)
                                    Text(detail)
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
                .listRowSeparator(.visible)
            }
            .listStyle(.plain)
            
            // Actions
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.saveToCalendar()
                    showingAlert = true
                }) {
                    Text("Add to Calendar")
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Start Over") {
                    withAnimation {
                        viewModel.userTopic = ""
                        viewModel.busySlots = []
                        viewModel.generatedPlan = []
                        nav.popToRoot()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding()
            .background(DesignSystem.Colors.background)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .alert("Saved", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Sessions added to 'InTheGap'.")
        }
    }
}
