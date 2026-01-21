import Foundation

/// PlanGenerator is deprecated.
/// Actual plan generation now happens via Foundation Models in AppViewModel.
/// This returns an empty array - no mocked data.
class PlanGenerator {
    static func generatePlan(topic: String, busySlots: [BusySlot], completion: @escaping ([DayPlan]) -> Void) {
        // No fallback data - return empty
        completion([])
    }
}
