import Foundation
import SwiftData

@MainActor
final class DataService {
    static let shared = DataService()
    
    private var container: ModelContainer?
    private var context: ModelContext? { container?.mainContext }
    
    private init() {}
    
    func configure(with container: ModelContainer) {
        self.container = container
    }
    
    // MARK: - Create
    
    func saveSchedule(topic: String, mode: String, sessions: [(date: Date, activity: String, duration: TimeInterval, details: [String])]) {
        guard let context else { return }
        
        let schedule = SavedSchedule(topic: topic, mode: mode)
        
        for session in sessions {
            let savedSession = SavedSession(
                date: session.date,
                activity: session.activity,
                duration: session.duration,
                details: session.details
            )
            savedSession.schedule = schedule
            schedule.sessions.append(savedSession)
        }
        
        context.insert(schedule)
        try? context.save()
    }
    
    // MARK: - Read
    
    func fetchSchedules() -> [SavedSchedule] {
        guard let context else { return [] }
        
        let descriptor = FetchDescriptor<SavedSchedule>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func fetchSchedule(by id: UUID) -> SavedSchedule? {
        guard let context else { return nil }
        
        let predicate = #Predicate<SavedSchedule> { $0.id == id }
        let descriptor = FetchDescriptor<SavedSchedule>(predicate: predicate)
        
        return try? context.fetch(descriptor).first
    }
    
    // MARK: - Delete
    
    func deleteSchedule(_ schedule: SavedSchedule) {
        guard let context else { return }
        context.delete(schedule)
        try? context.save()
    }
    
    func deleteAllSchedules() {
        guard let context else { return }
        
        for schedule in fetchSchedules() {
            context.delete(schedule)
        }
        try? context.save()
    }
}
