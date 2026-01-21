import SwiftUI
import EventKit

struct BusyScheduleView: View {
    @ObservedObject var viewModel: AppViewModel
    @EnvironmentObject var nav: NavigationManager
    @State private var selectedDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Block your busy times")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)

            Toggle(isOn: $viewModel.useCalendarBusy) {
                Text("Use calendar events as busy time")
            }
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            .padding(.horizontal)
            
            List {
                Section(header: Text("Add Busy Slot"), footer: Text("Add any commitments not on your calendar.")) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    
                    Button("Add Busy Time") {
                        let calendar = Calendar.current
                        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
                        
                        let finalStart = calendar.date(bySettingHour: startComponents.hour!, minute: startComponents.minute!, second: 0, of: selectedDate)!
                        var finalEnd = calendar.date(bySettingHour: endComponents.hour!, minute: endComponents.minute!, second: 0, of: selectedDate)!
                        
                        // Handle overnight or end before start
                        if finalEnd < finalStart {
                            finalEnd = finalEnd.addingTimeInterval(86400)
                        }
                        
                        viewModel.addBusySlot(start: finalStart, end: finalEnd)
                    }
                }
                
                Section(header: Text("Your Busy Schedule")) {
                    ForEach(viewModel.busySlots) { slot in
                        HStack {
                            Text(slot.start.formatted(.dateTime.weekday().hour().minute()))
                            Text("-")
                            Text(slot.end.formatted(.dateTime.hour().minute()))
                            Spacer()
                            Text("Manual")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.busySlots.remove(atOffsets: indexSet)
                    }
                }
                
                Section(header: Text("In Your Calendar (Next Week)")) {
                    if viewModel.fetchedEvents.isEmpty {
                        Text("No events found.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(viewModel.fetchedEvents, id: \.eventIdentifier) { event in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(event.title)
                                        .font(.headline)
                                    Text(event.startDate.formatted(.dateTime.weekday().hour().minute()) + " - " + event.endDate.formatted(.dateTime.hour().minute()))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchExistingEventsForNextWeek()
                viewModel.fetchEventsForTomorrow()
            }
            .onChange(of: viewModel.useCalendarBusy) { _, _ in
                viewModel.fetchExistingEventsForNextWeek()
                viewModel.fetchEventsForTomorrow()
            }
            
            Button(action: {
                Task { @MainActor in
                    await viewModel.generateSchedule()
                    withAnimation {
                        nav.push(.planResult)
                    }
                }
            }) {
                if viewModel.isGenerating {
                    ProgressView()
                } else {
                    Text("Generate My Plan")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
            }
            .padding()
            .disabled(viewModel.isGenerating)
        }
    }
}
