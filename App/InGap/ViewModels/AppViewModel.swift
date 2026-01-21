import Foundation
import Combine
import SwiftUI
import EventKit
import FoundationModels

class AppViewModel: ObservableObject {
    @Published var currentStep: Int = 0
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
    /// - Returns: A tuple containing the start and end of tomorrow, or nil if calculation fails.
    private func tomorrowRange() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()),
              let interval = calendar.dateInterval(of: .day, for: tomorrow) else {
            return nil
        }
        
        // dateInterval.end is the start of the next day, so subtract 1 second for inclusive range
        let endOfDay = interval.end.addingTimeInterval(-1)
        
        return (start: interval.start, end: endOfDay)
    }

    /// Returns the date range for the next work week (Monday 00:00:00 to Sunday 23:59:59).
    /// - Parameter reference: The reference date to calculate from. Defaults to now.
    /// - Returns: A tuple containing the start and end of the next work week, or nil if calculation fails.
    private func nextWorkWeekRange(from reference: Date = Date()) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        
        // Find the start of the current week (this Monday)
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: reference)?.start else {
            return nil
        }
        
        // Get the Monday of next week
        guard let nextMonday = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else {
            return nil
        }
        
        // Get the end of that week (Sunday)
        guard let nextWeekInterval = calendar.dateInterval(of: .weekOfYear, for: nextMonday) else {
            return nil
        }
        
        // Subtract 1 second to get 23:59:59 of Sunday instead of 00:00:00 of next Monday
        let endOfWeek = nextWeekInterval.end.addingTimeInterval(-1)
        
        return (start: nextMonday, end: endOfWeek)
    }
    
    func fetchEventsForTomorrow() {
        guard let range = tomorrowRange() else { return }
        calendarManager.checkPermission()
        
        let events = calendarManager.fetchEvents(start: range.start, end: range.end)
        DispatchQueue.main.async { [weak self] in
            self?.fetchedEvents = events
        }
    }
    
    func fetchExistingEventsForNextWeek() {
        guard let range = nextWorkWeekRange() else { return }
        calendarManager.checkPermission()
        
        let events = calendarManager.fetchEvents(start: range.start, end: range.end)
        DispatchQueue.main.async { [weak self] in
            self?.fetchedEvents = events
        }
    }
    
    func generateSchedule() {
        isGenerating = true
        let topic = userTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        let busy = busySlots
        let events = fetchedEvents
        
        Task { [weak self] in
            defer { DispatchQueue.main.async { self?.isGenerating = false } }
            // Build a prompt summarizing constraints and desired output
            let instructions = """
            You are an expert learning coach. Create a focused 7-day plan (Monday through Friday) for the upcoming week that helps the user make measurable progress on their specific goal.
            Requirements:
            - Avoid ALL busy intervals provided (calendar events across all calendars).
            - Schedule each day within reasonable study windows (e.g., early morning, lunch time or evening) and include the exact start time.
            - Keep each session 45–90 minutes unless otherwise specified by the user.
            - Use specific, outcome-oriented subtopics that clearly ladder toward the user's stated intent. Avoid generic titles.
            - Provide 3 crisp, actionable bullet points per day that tell the user exactly what to do (e.g., read/watch X, implement Y, practice Z, and a short deliverable or acceptance criteria).
            - Distribute difficulty across the week and include spaced review and a small capstone at the end.
            
            Output strictly as JSON only, no extra commentary, matching this schema:
            {
              "days": [
                {
                  "startISO8601": "<date-time with timezone, ISO8601>",
                  "topic": "<specific subtopic>",
                  "activity": "<what they will do>",
                  "durationMinutes": <integer 45-90>,
                  "details": ["<actionable step 1>", "<actionable step 2>", "<actionable step 3>"]
                }
              ]
            }
            """
            
            struct DayPlanOut: Codable {
                let startISO8601: String
                let topic: String
                let activity: String
                let durationMinutes: Int
                let details: [String]
            }
            
            struct WeekPlanOut: Codable {
                let days: [DayPlanOut]
            }
            
            // Prepare a compact summary of busy intervals
            func intervalString(_ start: Date, _ end: Date) -> String {
                let iso = ISO8601DateFormatter()
                return "\(iso.string(from: start)) to \(iso.string(from: end))"
            }
            
            // Collate manual busy slots + calendar events
            let manualBusy = busy.map { intervalString($0.start, $0.end) }
            let calendarBusy = (self?.useCalendarBusy == true) ? events.map { intervalString($0.startDate, $0.endDate) } : []
            
            // Compute upcoming Mon-Sun in ISO dates
            let calendar = Calendar.current
            guard let range = self?.nextWorkWeekRange() else { return }
            var weekDates: [String] = []
            let iso = ISO8601DateFormatter()
            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: i, to: range.start) {
                    let startOfDay = calendar.startOfDay(for: date)
                    weekDates.append(iso.string(from: startOfDay))
                }
            }
            
            let prompt = """
            User topic/intent: \(topic)
            
            Manual busy intervals (ISO8601):\n\(manualBusy.joined(separator: "\n"))
            Calendar busy intervals (ISO8601):\n\(calendarBusy.joined(separator: "\n"))
            
            Upcoming week dates (start of day ISO8601, Monday–Sunday):\n\(weekDates.joined(separator: "\n"))
            
            Please create a 7-day plan for those dates. Choose specific start times that avoid all busy intervals. Keep sessions 45–90 minutes. Make topics specific and tied directly to the user's intent (avoid generic labels). Provide 3 actionable bullet details each day with concrete tasks and a small deliverable.
            
            Return ONLY JSON that matches the schema provided in the instructions.
            """
            
            // Use Foundation Models to generate a structured plan
            let session = LanguageModelSession(instructions: instructions)
            do {
                let response = try await session.respond(to: prompt)
                let rawContent = response.content
                print("[InTheGap] Raw AI response:\n\(rawContent)")
                
                // Strip markdown code blocks if present (```json ... ```)
                var jsonString = rawContent
                if let startRange = jsonString.range(of: "```json") {
                    jsonString = String(jsonString[startRange.upperBound...])
                } else if let startRange = jsonString.range(of: "```") {
                    jsonString = String(jsonString[startRange.upperBound...])
                }
                if let endRange = jsonString.range(of: "```") {
                    jsonString = String(jsonString[..<endRange.lowerBound])
                }
                jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
                
                print("[InTheGap] Cleaned JSON:\n\(jsonString)")
                
                if let data = jsonString.data(using: .utf8),
                   let week = try? JSONDecoder().decode(WeekPlanOut.self, from: data) {
                    var plans: [DayPlan] = []
                    
                    // Create flexible ISO8601 formatter
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    let isoFormatterNoFrac = ISO8601DateFormatter()
                    isoFormatterNoFrac.formatOptions = [.withInternetDateTime]
                    
                    for day in week.days {
                        // Try multiple date formats
                        let date = isoFormatter.date(from: day.startISO8601)
                        ?? isoFormatterNoFrac.date(from: day.startISO8601)
                        ?? ISO8601DateFormatter().date(from: day.startISO8601)
                        
                        if let date = date {
                            let duration = TimeInterval(day.durationMinutes * 60)
                            let plan = DayPlan(date: date, topic: day.topic, activity: day.activity, duration: duration, details: day.details)
                            plans.append(plan)
                            print("[InTheGap] Parsed day: \(day.topic) at \(date)")
                        } else {
                            print("[InTheGap] Failed to parse date: \(day.startISO8601)")
                        }
                    }
                    
                    print("[InTheGap] Total plans generated: \(plans.count)")
                    DispatchQueue.main.async {
                        self?.generatedPlan = plans
                        withAnimation { self?.currentStep = 2 }
                    }
                } else {
                    print("[InTheGap] Failed to decode JSON")
                    DispatchQueue.main.async {
                        self?.generatedPlan = []
                        withAnimation { self?.currentStep = 2 }
                    }
                }
            } catch {
                print("[InTheGap] Foundation Model error: \(error)")
                DispatchQueue.main.async {
                    self?.generatedPlan = []
                    withAnimation { self?.currentStep = 2 }
                }
            }
        }
    }
    
    func generateTomorrowPlan() {
        isGenerating = true
        
        let topic = userTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        let events = fetchedEvents

        Task { [weak self] in
            defer { DispatchQueue.main.async { self?.isGenerating = false } }
            
            guard let range = self?.tomorrowRange() else { return }
            
            self?.calendarManager.checkPermission()

            let instructions = """
            You're a personal learning coach helping someone make real progress tomorrow on something they care about.

            Your job: Design 3 short learning moments for TOMORROW that fit naturally into their day and build on each other.

            Key considerations:
            - Work around their existing commitments (avoid all busy calendar times)
            - Schedule sessions between 8 AM - 10 PM when they're likely to be alert
            - Keep each session focused: 5-15 minutes
            - Think about natural energy patterns (morning clarity, afternoon slumps, evening reflection)
            - Break their larger goal into 3 meaningful micro-steps that create momentum

            For each session:
            - Give it a clear, motivating name (what they're actually doing, not just "Session 1")
            - Explain the specific outcome they'll achieve
            - Provide 3 concrete actions they can take—make them practical and immediately doable
            - Consider how each session sets up the next one

            Return your plan as clean JSON (no markdown, no extra text):

            {
              "days": [
                {
                  "startISO8601": "<ISO 8601 datetime with timezone>",
                  "topic": "<compelling session name>",
                  "activity": "<what they'll accomplish in plain language>",
                  "durationMinutes": <5-15>,
                  "details": [
                    "<concrete action 1>",
                    "<concrete action 2>",
                    "<concrete action 3>"
                  ]
                }
              ]
            }

            Make it feel like a plan a thoughtful human coach would create—not a generic template.
            """
            
            func intervalString(_ start: Date, _ end: Date) -> String {
                let iso = ISO8601DateFormatter()
                return "\(iso.string(from: start)) to \(iso.string(from: end))"
            }
            
            let calendarBusy = events.map { intervalString($0.startDate, $0.endDate) }
            let iso = ISO8601DateFormatter()
            let tomorrowDateStr = iso.string(from: range.start)
            
            let prompt = """
            User topic/intent: \(topic)
            Calendar busy intervals (ISO8601): \(calendarBusy.joined(separator: "\n"))
            Tomorrow's date (start of day ISO8601): \(tomorrowDateStr)
            
            Please schedule 3 sequential learning sessions for tomorrow regarding this topic, avoiding calendar conflicts.
            
            Return ONLY JSON that matches the schema provided in the instructions.
            """
            
            struct DayPlanOut: Codable {
                let startISO8601: String
                let topic: String
                let activity: String
                let durationMinutes: Int
                let details: [String]
            }
            
            struct WeekPlanOut: Codable {
                let days: [DayPlanOut]
            }
            
            let session = LanguageModelSession(instructions: instructions)
            do {
                let response = try await session.respond(to: prompt)
                let rawContent = response.content
                print("[InTheGap] Raw AI response (tomorrow):\n\(rawContent)")
                
                var jsonString = rawContent
                if let startRange = jsonString.range(of: "```json") {
                    jsonString = String(jsonString[startRange.upperBound...])
                } else if let startRange = jsonString.range(of: "```") {
                    jsonString = String(jsonString[startRange.upperBound...])
                }
                if let endRange = jsonString.range(of: "```") {
                    jsonString = String(jsonString[..<endRange.lowerBound])
                }
                jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let data = jsonString.data(using: .utf8),
                   let week = try? JSONDecoder().decode(WeekPlanOut.self, from: data) {
                    var plans: [DayPlan] = []
                    
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    let isoFormatterNoFrac = ISO8601DateFormatter()
                    isoFormatterNoFrac.formatOptions = [.withInternetDateTime]
                    
                    for day in week.days {
                        let date = isoFormatter.date(from: day.startISO8601)
                            ?? isoFormatterNoFrac.date(from: day.startISO8601)
                            ?? ISO8601DateFormatter().date(from: day.startISO8601)
                        
                        if let date = date {
                            let duration = TimeInterval(day.durationMinutes * 60)
                            let plan = DayPlan(date: date, topic: day.topic, activity: day.activity, duration: duration, details: day.details)
                            plans.append(plan)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self?.generatedPlan = plans
                        withAnimation { self?.currentStep = 2 }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.generatedPlan = []
                        withAnimation { self?.currentStep = 2 }
                    }
                }
            } catch {
                print("[InTheGap] Foundation Model error (tomorrow): \(error)")
                DispatchQueue.main.async {
                    self?.generatedPlan = []
                    withAnimation { self?.currentStep = 2 }
                }
            }
        }
    }
}
