import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var nav: NavigationManager
    @State private var schedules: [SavedSchedule] = []
    @State private var selectedSchedule: SavedSchedule?
    @State private var showAddToCalendarAlert = false
    
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
                Text("History")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Spacer()
                Color.clear.frame(width: 24, height: 24)
            }
            .padding()
            .background(DesignSystem.Colors.background)
            
            if schedules.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("No saved plans")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("Generated plans will appear here")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                Spacer()
            } else {
                List {
                    ForEach(schedules) { schedule in
                        ScheduleRow(schedule: schedule) {
                            selectedSchedule = schedule
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.visible)
                    }
                    .onDelete(perform: deleteSchedule)
                }
                .listStyle(.plain)
            }
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { loadSchedules() }
        .sheet(item: $selectedSchedule) { schedule in
            ScheduleDetailView(schedule: schedule)
        }
    }
    
    private func loadSchedules() {
        schedules = DataService.shared.fetchSchedules()
    }
    
    private func deleteSchedule(at offsets: IndexSet) {
        for index in offsets {
            DataService.shared.deleteSchedule(schedules[index])
        }
        loadSchedules()
    }
}

// MARK: - Subviews

private struct ScheduleRow: View {
    let schedule: SavedSchedule
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(schedule.topic)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(schedule.mode == "Plan a Week" ? "Week" : "Day")
                        .font(DesignSystem.Typography.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text(schedule.createdAt.formatted(.dateTime.month().day().year()))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("•")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("\(schedule.sessions.count) sessions")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail View

struct ScheduleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let schedule: SavedSchedule
    @State private var showAddedAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Close") { dismiss() }
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Spacer()
                Text(schedule.topic)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                Spacer()
                Button("Add All") { addAllToCalendar() }
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            .padding()
            .background(DesignSystem.Colors.background)
            
            List(schedule.sessions) { session in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(session.date.formatted(.dateTime.weekday().month().day()))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .textCase(.uppercase)
                        Spacer()
                        Text("\(Int(session.duration / 60)) min")
                            .font(DesignSystem.Typography.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.surface)
                            .cornerRadius(4)
                    }
                    
                    Text(session.activity)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if !session.details.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(session.details, id: \.self) { detail in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(DesignSystem.Colors.secondaryText)
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 6)
                                    Text(detail)
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .alert("Added to Calendar", isPresented: $showAddedAlert) {
            Button("OK") {
                if let url = URL(string: "calshow:") {
                    UIApplication.shared.open(url)
                }
                dismiss()
            }
        } message: {
            Text("All sessions added. Opening Calendar...")
        }
    }
    
    private func addAllToCalendar() {
        let calendarManager = CalendarManager()
        for session in schedule.sessions {
            calendarManager.addEvent(
                title: session.activity,
                startDate: session.date,
                duration: session.duration,
                notes: session.details.joined(separator: "\n")
            )
        }
        showAddedAlert = true
    }
}
