import SwiftUI
import EventKit

struct BusyScheduleView: View {
    @ObservedObject var viewModel: AppViewModel
    @EnvironmentObject var nav: NavigationManager
    @State private var selectedDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    
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
                Text("Availability")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Spacer()
                // Empty view for centering title
                Color.clear.frame(width: 24, height: 24)
            }
            .padding()
            .background(DesignSystem.Colors.background)
            
            List {
                Section {
                    Toggle("Integrate Calendar", isOn: $viewModel.useCalendarBusy)
                        .tint(DesignSystem.Colors.accent)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } header: {
                    Text("AUTOMATION")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        HStack {
                            DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                        }
                        
                        Button("Add Block") {
                            let calendar = Calendar.current
                            let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                            let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
                            
                            let finalStart = calendar.date(bySettingHour: startComponents.hour!, minute: startComponents.minute!, second: 0, of: selectedDate)!
                            var finalEnd = calendar.date(bySettingHour: endComponents.hour!, minute: endComponents.minute!, second: 0, of: selectedDate)!
                            
                            if finalEnd < finalStart {
                                finalEnd = finalEnd.addingTimeInterval(86400)
                            }
                            
                            viewModel.addBusySlot(start: finalStart, end: finalEnd)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } header: {
                    Text("MANUAL BLOCKS")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                if !viewModel.busySlots.isEmpty {
                    Section {
                        ForEach(viewModel.busySlots) { slot in
                            HStack {
                                Text(slot.start.formatted(.dateTime.weekday().hour().minute()))
                                Spacer()
                                Text(slot.end.formatted(.dateTime.hour().minute()))
                            }
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { indexSet in
                            viewModel.busySlots.remove(atOffsets: indexSet)
                        }
                    } header: {
                        Text("ADDED BLOCKS")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                if !viewModel.fetchedEvents.isEmpty {
                    Section {
                        ForEach(viewModel.fetchedEvents, id: \.eventIdentifier) { event in
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(DesignSystem.Typography.headline)
                                Text(event.startDate.formatted(.dateTime.weekday().hour().minute()) + " - " + event.endDate.formatted(.dateTime.hour().minute()))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text("CALENDAR EVENTS")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            .listStyle(.plain)
            
            // Generate Button
            Button(action: {
                Task { @MainActor in
                    await viewModel.generateSchedule()
                    withAnimation {
                        nav.push(.planResult)
                    }
                }
            }) {
                if viewModel.isGenerating {
                    ProgressView().tint(.white)
                } else {
                    Text("Create Plan")
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: !viewModel.isGenerating))
            .disabled(viewModel.isGenerating)
            .padding()
            .background(DesignSystem.Colors.background)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            viewModel.fetchExistingEventsForNextWeek()
            viewModel.fetchEventsForTomorrow()
        }
        .onChange(of: viewModel.useCalendarBusy) { _, _ in
            viewModel.fetchExistingEventsForNextWeek()
            viewModel.fetchEventsForTomorrow()
        }
    }
}
