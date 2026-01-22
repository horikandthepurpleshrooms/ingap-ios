import Foundation
import Combine
import SwiftUI
import EventKit
import FoundationModels

class AppViewModel: ObservableObject {
    // @Published var currentStep: Int = 0 - Removed for NavigationManager
    @Published var userTopic: String = ""
    @Published var busySlots: [BusySlot] = []
    @Published var generatedPlan: [DayPlan] = []
    @Published var isGenerating: Bool = false
    @Published var fetchedEvents: [EKEvent] = []
    @Published var useCalendarBusy: Bool = true
    
    @Published var planningMode: PlanningMode = .week
        
    let calendarManager = CalendarManager()
    
    func addBusySlot(start: Date, end: Date) {
        let slot = BusySlot(start: start, end: end)
        busySlots.append(slot)
    }
    
    func saveToCalendar() {
        for plan in generatedPlan {
            let notes = plan.details.map { "• \($0)" }.joined(separator: "\n")
            calendarManager.addEvent(
                title: "\(plan.topic)",
                startDate: plan.date,
                duration: plan.duration,
                notes: notes
            )
        }
    }
    
    /// Returns the date range for tomorrow (00:00:00 to 23:59:59).
    /// This is the NEXT calendar day after today, not the current day.
    /// - Returns: A tuple containing the start and end of tomorrow, or nil if calculation fails.
    func tomorrowRange() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
              let interval = calendar.dateInterval(of: .day, for: tomorrow) else {
            return nil
        }
        
        let endOfDay = interval.end.addingTimeInterval(-1)
        return (start: interval.start, end: endOfDay)
    }

    /// Returns the date range for the next work week (Monday 00:00:00 to Sunday 23:59:59).
    /// This finds the upcoming Monday (not today even if today is Monday) through the following Sunday.
    /// - Parameter reference: The reference date to calculate from. Defaults to now.
    /// - Returns: A tuple containing the start and end of the next work week, or nil if calculation fails.
    func nextWorkWeekRange(from reference: Date = Date()) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        
        // Get the current weekday (1 = Sunday, 2 = Monday, etc.)
        let currentWeekday = calendar.component(.weekday, from: reference)
        
        // Calculate days until next Monday
        // If today is Sunday (1), next Monday is 1 day away
        // If today is Monday (2), next Monday is 7 days away (we want NEXT week)
        // If today is Tuesday (3), next Monday is 6 days away
        var daysUntilMonday: Int
        if currentWeekday == 1 { // Sunday
            daysUntilMonday = 1
        } else { // Monday through Saturday
            daysUntilMonday = (9 - currentWeekday) % 7
            // Ensure if it's Monday, we get next Monday (7 days)
            if daysUntilMonday == 0 {
                daysUntilMonday = 7
            }
        }
        
        let adjustedDays = daysUntilMonday == 0 ? 7 : daysUntilMonday
        
        guard let nextMonday = calendar.date(byAdding: .day, value: adjustedDays, to: calendar.startOfDay(for: reference)),
              let nextMondayInterval = calendar.dateInterval(of: .day, for: nextMonday) else {
            return nil
        }
        
        // Get Sunday of that week (6 days after Monday)
        guard let nextSunday = calendar.date(byAdding: .day, value: 6, to: nextMondayInterval.start),
              let sundayInterval = calendar.dateInterval(of: .day, for: nextSunday) else {
            return nil
        }
        
        let endOfWeek = sundayInterval.end.addingTimeInterval(-1)
        return (start: nextMondayInterval.start, end: endOfWeek)
    }
    
    func fetchEventsForTomorrow() {
        guard let range = tomorrowRange() else { return }
        calendarManager.updateAuthorizationStatus()
        
        let events = calendarManager.fetchEvents(start: range.start, end: range.end)
        DispatchQueue.main.async { [weak self] in
            self?.fetchedEvents = events
        }
    }
    
    func fetchExistingEventsForNextWeek() {
        guard let range = nextWorkWeekRange() else { return }
        calendarManager.updateAuthorizationStatus()
        
        let events = calendarManager.fetchEvents(start: range.start, end: range.end)
        DispatchQueue.main.async { [weak self] in
            self?.fetchedEvents = events
        }
    }
        
    // MARK: - Helper Methods
     static func cleanJSONResponse(_ rawContent: String) -> String {
        var jsonString = rawContent
        if let startRange = jsonString.range(of: "```json") {
            jsonString = String(jsonString[startRange.upperBound...])
        } else if let startRange = jsonString.range(of: "```") {
            jsonString = String(jsonString[startRange.upperBound...])
        }
        if let endRange = jsonString.range(of: "```") {
            jsonString = String(jsonString[..<endRange.lowerBound])
        }
        return jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
     static func parseISO8601Date(_ dateString: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let isoFormatterNoFrac = ISO8601DateFormatter()
        isoFormatterNoFrac.formatOptions = [.withInternetDateTime]
        
        return isoFormatter.date(from: dateString)
            ?? isoFormatterNoFrac.date(from: dateString)
            ?? ISO8601DateFormatter().date(from: dateString)
    }
    
     static func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
