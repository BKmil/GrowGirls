import Combine
import SwiftUI
import UIKit

/// The two modes available on the timer screen.
enum TimerMode: CaseIterable, Identifiable {
    case stopwatch
    case restTimer

    // SwiftUI uses this value to identify each mode inside ForEach.
    var id: Self { self }

    var title: String {
        switch self {
        case .stopwatch:
            return "Stopwatch"
        case .restTimer:
            return "Rest timer"
        }
    }
}

/*
 TimerView is organized in this reading order:

 1. State          - values remembered by the screen
 2. Screen layout  - the main view hierarchy
 3. Timer actions  - what buttons and timer ticks do
 4. Display values - text calculated from the state
 5. UI sections    - detailed appearance of each section
 */
struct TimerView: View {
    // MARK: - 1. State

    // dismiss() closes the full-screen timer.
    @Environment(\.dismiss) private var dismiss

    // scenePhase tells us when the app returns from the background.
    @Environment(\.scenePhase) private var scenePhase

    // This reads the default chosen on the Settings screen from UserDefaults.
    @AppStorage("defaultRestDuration") private var defaultRestDuration = 90

    // @State values are remembered while this screen is open.
    // Changing one of them causes SwiftUI to redraw the affected interface.
    @State private var selectedMode: TimerMode = .stopwatch
    @State private var timeInSeconds = 0

    // This is the temporary preset used during the current timer session.
    // Changing it here does not overwrite the default saved in Settings.
    @State private var selectedRestDuration = 90
    @State private var isRunning = false
    @State private var hasFinished = false

    // These dates let us calculate the correct time after the app was in the background.
    @State private var stopwatchStartDate: Date?
    @State private var restEndDate: Date?

    // Notification details live in a separate file to keep this screen readable.
    private let notificationManager = RestTimerNotificationManager.shared

    // All preset durations use seconds as their common unit.
    private let restPresets = [30, 60, 90, 120]

    // MARK: - 2. Screen layout

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                modeSelector

                // Countdown presets are hidden in Stopwatch mode.
                if selectedMode == .restTimer {
                    restPresetButtons
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                timerReadout
                controlButtons
                Spacer()
            }
        }
        // Every time a new timer screen opens, begin with the saved default.
        .onAppear {
            loadDefaultRestDuration()
        }
        // Timers may stop receiving ticks while iOS keeps the app in the background.
        // When the app becomes active, calculate the correct time from the saved date.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshTimerAfterReturningToApp()
            }
        }
        // The publisher sends one signal every second.
        // handleTimerTick() ignores the signal while the timer is paused.
        .onReceive(
            Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        ) { _ in
            handleTimerTick()
        }
    }

    // MARK: - 3. Timer actions

    /// Loads the preference saved by Settings into this timer session.
    private func loadDefaultRestDuration() {
        selectedRestDuration = defaultRestDuration
    }

    /// Changes between Stopwatch and Rest Timer, then resets the clock.
    private func selectMode(_ newMode: TimerMode) {
        guard selectedMode != newMode else { return }

        selectedMode = newMode
        resetTimer()
    }

    /// Selects a Rest Timer preset and immediately displays its duration.
    private func selectRestDuration(_ duration: Int) {
        notificationManager.cancelNotification()
        isRunning = false
        hasFinished = false
        restEndDate = nil
        selectedRestDuration = duration
        timeInSeconds = duration
    }

    /// Starts a stopped timer or pauses a running timer.
    private func startOrPauseTimer() {
        if isRunning {
            pauseTimer()
            return
        }

        // Starting a completed countdown should begin again from its preset.
        if selectedMode == .restTimer && timeInSeconds == 0 {
            timeInSeconds = selectedRestDuration
        }

        hasFinished = false
        isRunning = true

        if selectedMode == .stopwatch {
            startStopwatch()
        } else {
            startRestTimer()
        }
    }

    /// Starts the stopwatch from its currently displayed time.
    private func startStopwatch() {
        stopwatchStartDate = Date().addingTimeInterval(-Double(timeInSeconds))
    }

    /// Starts the countdown and schedules its completion notification.
    private func startRestTimer() {
        let endDate = Date().addingTimeInterval(Double(timeInSeconds))

        restEndDate = endDate
        notificationManager.scheduleNotification(at: endDate)
    }

    /// Pauses either timer and remembers the time currently displayed.
    private func pauseTimer() {
        updateDisplayedTime()

        isRunning = false
        stopwatchStartDate = nil
        restEndDate = nil
        notificationManager.cancelNotification()
    }

    /// Stops the timer and restores the starting value for the selected mode.
    private func resetTimer() {
        notificationManager.cancelNotification()
        isRunning = false
        hasFinished = false
        stopwatchStartDate = nil
        restEndDate = nil

        if selectedMode == .stopwatch {
            timeInSeconds = 0
        } else {
            timeInSeconds = selectedRestDuration
        }
    }

    /// Moves the active timer forward by one second.
    private func handleTimerTick() {
        // The publisher also sends signals while paused, so exit unless running.
        guard isRunning else { return }

        updateDisplayedTime()
    }

    /// Calculates the current display from the timer's start or end date.
    private func updateDisplayedTime() {
        if selectedMode == .stopwatch {
            updateStopwatchTime()
        } else {
            updateRestTimerTime()
        }
    }

    /// Calculates how much time has passed since the stopwatch started.
    private func updateStopwatchTime() {
        guard let stopwatchStartDate else { return }

        timeInSeconds = Int(Date().timeIntervalSince(stopwatchStartDate))
    }

    /// Calculates how much time remains before the rest period ends.
    private func updateRestTimerTime() {
        guard let restEndDate else { return }

        let remainingTime = restEndDate.timeIntervalSinceNow
        timeInSeconds = max(0, Int(ceil(remainingTime)))

        if timeInSeconds == 0 {
            finishRestTimer()
        }
    }

    /// Finishes the countdown and gives feedback when the app is visible.
    private func finishRestTimer() {
        isRunning = false
        hasFinished = true
        restEndDate = nil
        notificationManager.cancelNotification()

        if scenePhase == .active {
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
        }
    }

    /// Corrects the display after iOS brings the app back from the background.
    private func refreshTimerAfterReturningToApp() {
        guard isRunning else { return }
        updateDisplayedTime()
    }

    // MARK: - 4. Display values

    /// Converts an integer such as 90 into the text "01:30".
    private var formattedTime: String {
        let minutes = timeInSeconds / 60
        let seconds = timeInSeconds % 60

        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Text shown directly below the digital clock.
    private var statusText: String {
        if hasFinished {
            return "Rest complete"
        }

        if isRunning {
            if selectedMode == .stopwatch {
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

    /// Text shown inside the large pink control button.
    private var mainButtonTitle: String {
        if isRunning {
            return "Pause"
        }

        if timerHasStarted {
            return "Resume"
        }

        return "Start"
    }

    /// Helps distinguish a new timer from one that has been paused.
    private var timerHasStarted: Bool {
        if selectedMode == .stopwatch {
            return timeInSeconds > 0
        } else {
            return timeInSeconds < selectedRestDuration && timeInSeconds > 0
        }
    }

    /// Converts preset seconds into short labels used by the buttons.
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

    // MARK: - 5. UI sections

    /// Back button and screen title.
    private var header: some View {
        HStack(spacing: 12) {
            Button {
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

    /// Buttons for choosing Stopwatch or Rest Timer.
    private var modeSelector: some View {
        HStack(spacing: 6) {
            ForEach(TimerMode.allCases) { availableMode in
                let isSelected = selectedMode == availableMode

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectMode(availableMode)
                    }
                } label: {
                    Text(availableMode.title)
                        .font(.system(size: 13, weight: .medium))
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
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.brandPink.opacity(0.06))
        .clipShape(Capsule())
    }

    /// Quick duration buttons displayed only in Rest Timer mode.
    private var restPresetButtons: some View {
        HStack(spacing: 8) {
            ForEach(restPresets, id: \.self) { duration in
                let isSelected = selectedRestDuration == duration

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
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

    /// Large clock and short status message.
    private var timerReadout: some View {
        VStack(spacing: 10) {
            Text(formattedTime)
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(Color.primary)
                .accessibilityLabel("Timer")
                .accessibilityValue(formattedTime)

            Text(statusText)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.secondary)
                .animation(.easeInOut(duration: 0.2), value: statusText)
        }
        .padding(.top, selectedMode == .restTimer ? 42 : 58)
    }

    /// Reset button and the main Start/Pause/Resume button.
    private var controlButtons: some View {
        HStack(spacing: 18) {
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
}

#Preview {
    TimerView()
}
