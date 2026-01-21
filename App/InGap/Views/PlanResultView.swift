import SwiftUI

struct PlanResultView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showingAlert = false
    
    var body: some View {
        VStack {
            Text("Your 7‑Day Plan")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            List(viewModel.generatedPlan) { plan in
                VStack(alignment: .leading) {
                    Text(plan.date.formatted(.dateTime.weekday().day().month()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(plan.topic)
                        .font(.headline)
                    
                    Text(plan.activity)
                        .font(.subheadline)
                    
                    if !plan.details.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(plan.details, id: \.self) { detail in
                                Text("• \(detail)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    Text("\(plan.date.formatted(date: .omitted, time: .shortened)) • \(Int(plan.duration/60)) min")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Divider()
                .padding(.vertical, 4)
            }
            
            Text("Review each day's steps before adding to Calendar.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            Button(action: {
                viewModel.saveToCalendar()
                showingAlert = true
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Add to Calendar")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(12)
            }
            .padding()
            .alert("Added to Calendar", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your learning plan has been added to the 'InTheGap' calendar.")
            }
            
            Button("Start Over") {
                withAnimation {
                    viewModel.currentStep = 0
                    viewModel.userTopic = ""
                    viewModel.busySlots = []
                    viewModel.generatedPlan = []
                }
            }
            .padding(.bottom)
        }
    }
}
