import Combine
import SwiftUI

/// The two modes available on the timer screen.
// CaseIterable gives us TimerMode.allCases for creating the selector buttons.
// Identifiable lets SwiftUI tell the two enum cases apart inside ForEach.
enum TimerMode: CaseIterable, Identifiable {
    case stopwatch
    case restTimer

    // Each enum case can use itself as its unique identifier.
    var id: Self { self }

    // Text displayed inside the mode selector.
    var title: String {
        switch self {
        case .stopwatch:
            return "Stopwatch"
        case .restTimer:
            return "Rest timer"
        }
    }
}

struct TimerView: View {
    // SwiftUI provides dismiss(). Calling it closes this full-screen view.
    @Environment(\.dismiss) private var dismiss

    // These are the values that can change while the screen is open.
    // @State tells SwiftUI to redraw the screen after a value changes.
    @State private var mode: TimerMode = .stopwatch

    // Both modes use the same number. Stopwatch increases it and Rest Timer decreases it.
    @State private var seconds = 0

    // Remember the selected preset so Reset knows which value to restore.
    @State private var selectedRestDuration = 90

    // Controls whether tick() should change the number of seconds.
    @State private var isRunning = false

    // Used to show "Rest complete" after a countdown reaches zero.
    @State private var hasFinished = false

    // Preset values are expressed in seconds: 30s, 1min, 1.5min and 2min.
    private let restPresets = [30, 60, 90, 120]

    var body: some View {
        // ZStack places the interface on top of the background color.
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // VStack places all screen sections vertically from top to bottom.
            VStack(spacing: 0) {
                header
                modeSelector

                // Presets are useful only for a countdown, not for a stopwatch.
                if mode == .restTimer {
                    restPresetButtons
                        // Fade and slide the presets when changing modes.
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                timerReadout
                controlButtons
                Spacer()
            }
        }
        // This publisher sends one signal every second while the screen exists.
        // It keeps sending signals even when paused; tick() ignores them when
        // isRunning is false.
        .onReceive(
            Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        ) { _ in
            tick()
        }
    }

    // MARK: - Screen sections

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                // Close the full-screen timer and return to the tab screen.
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.brandPink.opacity(0.12), lineWidth: 1)
                    }
            }
            .accessibilityLabel("Close timer")

            Text("Timer")
                .font(.headline)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }

    private var modeSelector: some View {
        HStack(spacing: 6) {
            // This loop creates one button for Stopwatch and one for Rest Timer.
            ForEach(TimerMode.allCases) { availableMode in
                // The local value makes the styling conditions easier to read.
                let isSelected = mode == availableMode

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        // The helper stops and resets the timer before changing mode.
                        selectMode(availableMode)
                    }
                } label: {
                    Text(availableMode.title)
                        .font(.system(size: 13, weight: .medium))
                        // Selected buttons use white text on a pink background.
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(isSelected ? Color.brandPink : Color.white)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(Color.brandPink.opacity(0.16), lineWidth: 1)
                        }
                }
                // VoiceOver announces which mode is currently selected.
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.brandPink.opacity(0.06))
        .clipShape(Capsule())
    }

    private var restPresetButtons: some View {
        HStack(spacing: 8) {
            // id: \.self means each unique number is also the button's identity.
            ForEach(restPresets, id: \.self) { duration in
                let isSelected = selectedRestDuration == duration

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        // Set both the selected preset and the visible countdown value.
                        selectRestDuration(duration)
                    }
                } label: {
                    Text(presetLabel(for: duration))
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .padding(.horizontal, 13)
                        .frame(height: 34)
                        .background(isSelected ? Color.brandPink : Color.white)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(Color.brandPink.opacity(0.14), lineWidth: 1)
                        }
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.top, 18)
    }

    private var timerReadout: some View {
        VStack(spacing: 10) {
            // formattedTime changes an integer such as 90 into the text "01:30".
            Text(formattedTime)
                .font(.system(size: 58, weight: .bold, design: .rounded))
                // Every digit receives the same width, so the clock does not jump.
                .monospacedDigit()
                // Animate a number changing into the next number.
                .contentTransition(.numericText())
                .foregroundStyle(Color.primary)
                .accessibilityLabel("Timer")
                .accessibilityValue(formattedTime)

            // Explain the current state: ready, running, paused or finished.
            Text(statusText)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.secondary)
                .animation(.easeInOut(duration: 0.2), value: statusText)
        }
        .padding(.top, mode == .restTimer ? 42 : 58)
    }

    private var controlButtons: some View {
        HStack(spacing: 18) {
            // The smaller button stops the timer and restores its starting value.
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    resetTimer()
                }
            } label: {
                Text("Reset")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .frame(width: 58, height: 58)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.brandPink.opacity(0.14), lineWidth: 1)
                    }
            }

            // The larger button changes between Start, Pause and Resume.
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    startOrPauseTimer()
                }
            } label: {
                Text(mainButtonTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 76, height: 76)
                    .background(Color.brandPink)
                    .clipShape(Circle())
                    .shadow(color: Color.brandPink.opacity(0.28), radius: 12, y: 8)
            }
        }
        .padding(.top, 48)
    }

    // MARK: - Timer information

    // Computed properties do not store new data. They calculate an answer
    // from the @State values every time SwiftUI reads them.
    private var formattedTime: String {
        // Integer division returns the number of complete minutes.
        let minutes = seconds / 60

        // The remainder operator (%) returns the seconds left after full minutes.
        // Example: 90 / 60 = 1 minute, and 90 % 60 = 30 seconds.
        let remainingSeconds = seconds % 60

        // %02d displays at least two digits, adding a leading zero when needed.
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    // Decide which explanatory message appears below the clock.
    private var statusText: String {
        if hasFinished {
            return "Rest complete"
        }

        if isRunning {
            if mode == .stopwatch {
                return "Workout in progress"
            } else {
                return "Resting..."
            }
        }

        if timerHasStarted {
            return "Paused"
        }

        return "Ready when you are"
    }

    // Decide which label appears inside the large pink button.
    private var mainButtonTitle: String {
        if isRunning {
            return "Pause"
        }

        if timerHasStarted {
            return "Resume"
        }

        return "Start"
    }

    // This helps distinguish a fresh timer from a timer that was paused.
    private var timerHasStarted: Bool {
        if mode == .stopwatch {
            return seconds > 0
        } else {
            return seconds < selectedRestDuration && seconds > 0
        }
    }

    // MARK: - Timer actions

    private func selectMode(_ newMode: TimerMode) {
        // Do nothing when the user taps the already selected mode.
        guard mode != newMode else { return }

        mode = newMode

        // Stopwatch starts at 0. Rest Timer starts at the selected preset.
        resetTimer()
    }

    private func selectRestDuration(_ duration: Int) {
        // Selecting a new preset stops any countdown already in progress.
        isRunning = false
        hasFinished = false

        // Store the preset for future resets and show it immediately.
        selectedRestDuration = duration
        seconds = duration
    }

    private func startOrPauseTimer() {
        // Restart a completed rest timer from its selected duration.
        if mode == .restTimer && seconds == 0 {
            seconds = selectedRestDuration
        }

        hasFinished = false

        // toggle() changes false to true or true to false.
        isRunning.toggle()
    }

    private func resetTimer() {
        // Reset always stops the current timer first.
        isRunning = false
        hasFinished = false

        // Each mode has a different starting value.
        if mode == .stopwatch {
            seconds = 0
        } else {
            seconds = selectedRestDuration
        }
    }

    private func tick() {
        // The one-second publisher still calls tick() while paused.
        // guard exits early unless the timer is actively running.
        guard isRunning else { return }

        if mode == .stopwatch {
            // Stopwatch counts upward.
            seconds += 1
            return
        }

        // Rest Timer counts downward. max prevents a negative result.
        seconds = max(0, seconds - 1)

        // Stop automatically and update the message when countdown reaches zero.
        if seconds == 0 {
            isRunning = false
            hasFinished = true
        }
    }

    // Convert raw seconds into short labels used by the preset buttons.
    private func presetLabel(for duration: Int) -> String {
        switch duration {
        case 30:
            return "30s"
        case 60:
            return "1 min"
        case 90:
            return "1.5 min"
        case 120:
            return "2 min"
        default:
            return "\(duration)s"
        }
    }
}

#Preview {
    // Preview displays this screen in Xcode without running the whole application.
    TimerView()
}
