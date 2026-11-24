import SwiftUI
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isLoggedIn: Bool = false
    
    private init() {}

    // For now this updates the local app state. When the backend is connected,
    // this method will also call the logout endpoint before clearing the session.
    func logOut() {
        isLoggedIn = false
    }
}
