import Foundation
import SwiftUI
import Combine

@MainActor
final class RateLimitService: ObservableObject {
    static let shared = RateLimitService()
    
    /// Maximum generations allowed per week for free users
    static let maxGenerationsPerWeek = 10
    
    @AppStorage("generationCount") private var generationCount: Int = 0
    @AppStorage("weekStartTimestamp") private var weekStartTimestamp: Double = Date().timeIntervalSince1970
    @AppStorage("isPremium") var isPremium: Bool = false
    
    private init() {
        resetIfNewWeek()
    }
    
    private var weekStartDate: Date {
        get { Date(timeIntervalSince1970: weekStartTimestamp) }
        set { weekStartTimestamp = newValue.timeIntervalSince1970 }
    }
    
    var resetDate: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate
    }
    
    /// Check if a new week has started and reset the counter
    func resetIfNewWeek() {
        let now = Date()
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: weekStartDate, to: now).day ?? 0
        
        if daysSinceStart >= 7 {
            generationCount = 0
            weekStartDate = now
        }
    }
    
    /// Whether the user can generate a new schedule
    var canGenerate: Bool {
        if isPremium { return true }
        resetIfNewWeek()
        return generationCount < RateLimitService.maxGenerationsPerWeek
    }
    
    /// Number of remaining generations this week
    var remainingGenerations: Int {
        if isPremium { return .max }
        resetIfNewWeek()
        return max(0, RateLimitService.maxGenerationsPerWeek - generationCount)
    }
    
    /// Record a successful generation
    func recordGeneration() {
        guard !isPremium else { return }
        resetIfNewWeek()
        generationCount += 1
        objectWillChange.send()
    }
    
    /// Reset generations to max (for testing/admin)
    func resetGenerations() {
        generationCount = 0
        weekStartDate = Date()
        objectWillChange.send()
    }
    
    /// Unlock premium (called after successful purchase)
    func unlockPremium() {
        isPremium = true
        objectWillChange.send()
    }
}
