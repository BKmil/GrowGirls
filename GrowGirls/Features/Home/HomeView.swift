import SwiftUI

struct HomeView: View {
    var onStartWorkout: () -> Void
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Home Dashboard")
                    .font(.title2.bold())
                Button("Start workout", action: onStartWorkout)
                    .buttonStyle(.borderedProminent)
                    .tint(.brandPink)
            }
        }
    }
}
