import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Profile")
                    .font(.title2.bold())

                // This link gives us a simple way to open the new settings screen.
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.brandPink)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(Color.brandPink.opacity(0.25), lineWidth: 1)
                        }
                }
            }
        }
    }
}
