import SwiftUI
import Combine

enum AppRoute: Hashable {
    case busySchedule
    case planResult
}

class NavigationManager: ObservableObject {
    @Published var path = NavigationPath()
    
    func push(_ route: AppRoute) {
        path.append(route)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}
