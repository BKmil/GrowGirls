import Foundation

enum TabItem: Int, CaseIterable {
    case home = 0
    case plans = 1
    case calendar = 2
    case profile = 3
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .plans: return "Plans"
        case .calendar: return "Calendar"
        case .profile: return "Profile"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house"
        case .plans: return "dumbbell"
        case .calendar: return "calendar"
        case .profile: return "person"
        }
    }
}