import SwiftUI

final class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isLoggedIn: Bool = false
    
    private init() {}
}