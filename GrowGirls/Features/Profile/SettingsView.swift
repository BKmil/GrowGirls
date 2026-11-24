import SwiftUI

// These are the rest timer choices shown on the settings screen.
enum RestTimerPreset: Int, CaseIterable, Identifiable {
    case thirtySeconds = 30
    case oneMinute = 60
    case ninetySeconds = 90
    case twoMinutes = 120

    // Identifiable lets SwiftUI use each preset inside ForEach.
    var id: Int {
        rawValue
    }

    var title: String {
        switch self {
        case .thirtySeconds:
            return "30s"
        case .oneMinute:
            return "1 min"
        case .ninetySeconds:
            return "1.5 min"
        case .twoMinutes:
            return "2 min"
        }
    }
}

struct SettingsView: View {
    // The file is divided into five numbered sections:
    // 1. values needed by the screen
    // 2. the main screen layout
    // 3. actions started by the user
    // 4. the large visual sections
    // 5. small reusable UI elements

    // MARK: - 1. Screen data and dependencies

    // dismiss() closes SettingsView and returns to ProfileView.
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    // @AppStorage saves these values in UserDefaults automatically.
    // They stay saved after the application is closed and opened again.
    @AppStorage("appleHealthEnabled") private var isAppleHealthEnabled = false
    @AppStorage("defaultRestDuration") private var selectedRestDuration = 90

    private let healthKitManager = HealthKitManager()

    @State private var isShowingHealthKitError = false

    // MARK: - 2. Main screen layout

    // body is the table of contents for the whole screen.
    // The detailed appearance of every section is defined further below.
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    connectionsSection
                    workoutDefaultsSection
                    logOutButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Apple Health unavailable", isPresented: $isShowingHealthKitError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("GrowGirls could not get permission to use Apple Health.")
        }
    }

    // MARK: - 3. Screen actions

    // Starts the Apple Health permission request without freezing the screen.
    private func askForHealthKitPermission() {
        Task {
            let requestSucceeded = await healthKitManager.requestAuthorization()

            if !requestSucceeded {
                isAppleHealthEnabled = false
                isShowingHealthKitError = true
            }
        }
    }

    // MARK: - 4. Screen sections

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 34, height: 34)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    }
            }

            Text("Settings")
                .font(.system(size: 18, weight: .bold))
        }
        .padding(.bottom, 2)
    }

    private var connectionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("CONNECTIONS")

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.brandPink.opacity(0.10))
                        .frame(width: 42, height: 42)

                    Image(systemName: "heart.fill")
                        .foregroundColor(.brandPink)
                        .font(.system(size: 19))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Apple Health")
                        .font(.system(size: 15, weight: .semibold))

                    Text("Sync workouts and activity")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("Apple Health", isOn: $isAppleHealthEnabled)
                    .labelsHidden()
                    .tint(.brandPink)
                    .onChange(of: isAppleHealthEnabled) { _, isEnabled in
                        if isEnabled {
                            askForHealthKitPermission()
                        }
                    }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.brandPink.opacity(0.12), lineWidth: 1)
            }
        }
    }

    private var workoutDefaultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("WORKOUT DEFAULTS")

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Default rest time")
                        .font(.system(size: 15, weight: .semibold))

                    Text("Used when you open the rest timer")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    ForEach(RestTimerPreset.allCases) { preset in
                        presetButton(for: preset)
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.brandPink.opacity(0.12), lineWidth: 1)
            }
        }
    }

    private var logOutButton: some View {
        Button {
            appState.logOut()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log out")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.brandPink)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white.opacity(0.45))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.brandPink.opacity(0.35), lineWidth: 1)
            }
        }
    }

    // MARK: - 5. Small reusable views

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .tracking(0.4)
    }

    private func presetButton(for preset: RestTimerPreset) -> some View {
        let isSelected = selectedRestDuration == preset.rawValue

        return Button {
            selectedRestDuration = preset.rawValue
        } label: {
            Text(preset.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? Color.brandPink : Color.white)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(
                            isSelected ? Color.brandPink : Color.brandPink.opacity(0.18),
                            lineWidth: 1
                        )
                }
        }
    }

}

// MARK: - Xcode preview

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState.shared)
    }
}
