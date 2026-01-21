import Foundation
import Combine
import SwiftUI
import EventKit
import FoundationModels


// MARK: - Prompt Engineering Helpers
extension AppViewModel {
    /// Formats a list of dates into a compact, human-readable string for the LLM to process logic easily.
    private func formatBusySlots(_ events: [EKEvent], range: (start: Date, end: Date)) -> String {
        let relevantEvents = events.filter { $0.startDate < range.end && $0.endDate > range.start }
        if relevantEvents.isEmpty { return "No conflicts - the user is completely free." }
        
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d (HH:mm"
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm)"
        
        return relevantEvents.map {
            "- \(df.string(from: $0.startDate)) to \(tf.string(from: $0.endDate))"
        }.joined(separator: "\n")
    }
    
    private func getTimezoneOffset() -> String {
        let seconds = TimeZone.current.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds / 60) % 60
        return String(format: "%+03d:%02d", hours, minutes)
    }
    
    // MARK: - Main Generation Logic
    
    @MainActor
    func generateSchedule() async {
        isGenerating = true
        defer { isGenerating = false }
        
        let topic = userTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Note: nextWorkWeekRange needs to be accessible. Since it's in the main file, it should be fine.
        guard let range = self.nextWorkWeekRange() else { return }
        
        let tzOffset = self.getTimezoneOffset()
        let busyList = self.formatBusySlots(self.fetchedEvents, range: range)
        
        let instructions = """
        You are a professional learning coach. Your task is to generate a 7-day study plan.
        
        CRITICAL INSTRUCTIONS:
        1. Return ONLY valid JSON. No markdown, no "```json" blocks, no conversational text.
        2. Follow the schema:
            {
                "days": [
                    {
                        "startISO8601": "YYYY-MM-DDTHH:MM:SS+/-HH:MM",
                        "topic": "string",
                        "activity": "string",
                        "durationMinutes": 5-15,
                        "details": ["string", "string", "string"]
                    }
                ]
            } 
        3. Use Timezone Offset: \(tzOffset)
        4. THOUGHT PROCESS: Before writing the JSON, internally verify that no session overlaps with the provided busy slots.
        """
        
        let prompt = """
        # OBJECTIVE
        Create a 7-day plan for: "\(topic)"
        Week Range: \(Self.formatDateForDisplay(range.start)) to \(Self.formatDateForDisplay(range.end))
        
        # CALENDAR CONFLICTS (DO NOT OVERLAP)
        \(busyList)
        
        # STRICT RULES
        - Exactly 7 sessions (one per day).
        - Hours: 07:00 to 21:00 only.
        - Duration: 45-90 minutes.
        - Format: YYYY-MM-DDTHH:MM:SS\(tzOffset)
        - Progression: Days 1-2 (Basics), 3-5 (Practice), 6-7 (Advanced/Project).
        
        # VALIDATION
        Ensure every "startISO8601" date actually falls on the correct day of that week.
        """
        
        await performGeneration(instructions: instructions, prompt: prompt, range: range)
    }
    
    @MainActor
    func generateTomorrowPlan() async {
        isGenerating = true
        defer { isGenerating = false }
        
        let topic = userTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let range = self.tomorrowRange() else { return }
        
        let tzOffset = self.getTimezoneOffset()
        let busyList = self.formatBusySlots(self.fetchedEvents, range: range)
        let tomorrowDate = Self.formatDateForDisplay(range.start)
        
        let instructions = """
        You are a micro-learning coach. Create 3 short sessions for tomorrow.
        
        CRITICAL: 
        - Return ONLY valid JSON.
        - Schema:
            {
                "days": [
                    {
                        "startISO8601": "YYYY-MM-DDTHH:MM:SS+/-HH:MM",
                        "topic": "string",
                        "activity": "string",
                        "durationMinutes": 5-15,
                        "details": ["string", "string", "string"]
                    }
                ]
            } 
        - Timezone: \(tzOffset)
        """
        
        let prompt = """
        # OBJECTIVE
        3 Micro-sessions for tomorrow (\(tomorrowDate)) regarding: "\(topic)"
        
        # UNAVAILABLE TIMES
        \(busyList)
        
        # WINDOWS
        1. Morning (08:00-10:00) - 15 mins
        2. Midday (12:00-14:00) - 15 mins
        3. Evening (19:00-21:00) - 10 mins
        
        # RULES
        - All sessions MUST occur on \(tomorrowDate).
        - Avoid all conflicts with a 5-minute buffer.
        - Use ISO8601 with offset \(tzOffset).
        """
        
        await performGeneration(instructions: instructions, prompt: prompt, range: range)
    }
    
    // MARK: - Private Execution Engine
    
    @MainActor
    private func performGeneration(instructions: String, prompt: String, range: (start: Date, end: Date)) async {
        let session = LanguageModelSession(instructions: instructions)
        
        do {
            let response = try await session.respond(to: prompt)
            let rawContent = response.content
            
            // Log for debugging
            print("[InTheGap] AI Response received. Processing...")
            
            let jsonString = Self.cleanJSONResponse(rawContent)
            
            // Use your existing WeekPlanOut struct (matching your current schema)
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
            
            guard let data = jsonString.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(WeekPlanOut.self, from: data) else {
                print("[InTheGap] Error: Could not decode JSON into existing schema.")
                return
            }
            
            let plans: [DayPlan] = decoded.days.compactMap { session in
                guard let date = Self.parseISO8601Date(session.startISO8601) else { return nil }
                
                // Final safety check: ensure AI didn't hallucinate a date outside the range
                if date >= range.start && date <= range.end {
                    return DayPlan(
                        date: date,
                        topic: session.topic,
                        activity: session.activity,
                        duration: TimeInterval(session.durationMinutes * 60),
                        details: session.details
                    )
                }
                return nil
            }
            
            self.generatedPlan = plans
            
        } catch {
            print("[InTheGap] Foundation Model Error: \(error)")
            self.generatedPlan = []
        }
    }
}
