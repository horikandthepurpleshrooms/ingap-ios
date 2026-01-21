import Foundation
import SwiftData

@Model
final class SavedSchedule {
    @Attribute(.unique) var id: UUID
    var topic: String
    var mode: String // "week" or "tomorrow"
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \SavedSession.schedule)
    var sessions: [SavedSession] = []
    
    init(id: UUID = UUID(), topic: String, mode: String, createdAt: Date = Date()) {
        self.id = id
        self.topic = topic
        self.mode = mode
        self.createdAt = createdAt
    }
}

@Model
final class SavedSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var activity: String
    var duration: TimeInterval
    var details: [String]
    
    var schedule: SavedSchedule?
    
    init(id: UUID = UUID(), date: Date, activity: String, duration: TimeInterval, details: [String] = []) {
        self.id = id
        self.date = date
        self.activity = activity
        self.duration = duration
        self.details = details
    }
}
