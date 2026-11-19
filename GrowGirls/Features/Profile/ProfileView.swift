import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Profile").font(.title2.bold())
        }
    }
}
