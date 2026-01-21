//
//  InGapApp.swift
//  InGap
//
//  Created by Horik on 21.01.2026.
//

import SwiftUI
import SwiftData

@main
struct InGapApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: SavedSchedule.self, SavedSession.self)
            DataService.shared.configure(with: container)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
