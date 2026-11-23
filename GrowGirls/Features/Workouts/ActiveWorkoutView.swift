import SwiftUI

/// Full-screen entry point opened by the center Start button in the tab bar.
struct ActiveWorkoutView: View {
    var body: some View {
        // ActiveWorkoutView is kept as a wrapper because it may later become
        // the full workout screen. For now, its only content is the timer.
        TimerView()
    }
}
