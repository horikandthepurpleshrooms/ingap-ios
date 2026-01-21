import Foundation

enum PlanningMode: String, CaseIterable {
    case week = "Plan a Week"
    case tomorrow = "Plan Tomorrow"
}

struct BusySlot: Identifiable, Equatable {
    let id = UUID()
    var start: Date
    var end: Date
}

struct DayPlan: Identifiable {
    let id = UUID()
    let date: Date
    let topic: String
    let activity: String
    let duration: TimeInterval // in seconds
    let details: [String]
}
