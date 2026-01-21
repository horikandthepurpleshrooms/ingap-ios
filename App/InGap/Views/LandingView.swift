import SwiftUI

struct LandingView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            
            Text("What do you want to get better at this week?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
            
            TextField("Describe your focus (e.g., Build a SwiftUI app with Charts)", text: $viewModel.userTopic)
                .font(.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.next)
                .onSubmit {
                    if !viewModel.userTopic.isEmpty {
                        withAnimation {
                            viewModel.currentStep = 1
                        }
                    }
                }
            
            Text("Be specific so we can craft focused, actionable steps.")
                .font(.footnote)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    viewModel.currentStep = 1
                }
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(!viewModel.userTopic.isEmpty ? Color.accentColor : Color.gray.opacity(0.4))
                    .cornerRadius(10)
            }
            .disabled(viewModel.userTopic.isEmpty)
            .padding(.bottom)
        }
        .padding()
        .padding(.horizontal)
    }
}
