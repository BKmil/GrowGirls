import UserNotifications

// This class has one job: manage the Rest Timer's local notification.
// Keeping it separate prevents notification code from filling TimerView.
final class RestTimerNotificationManager {
    static let shared = RestTimerNotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationIdentifier = "rest-timer-complete"

    // The task is stored so Pause or Reset can cancel it, even while the
    // user is still deciding whether to allow notifications.
    private var schedulingTask: Task<Void, Never>?

    private init() {}

    /// Asks for permission when necessary, then schedules one notification.
    func scheduleNotification(at endDate: Date) {
        cancelNotification()

        schedulingTask = Task {
            let permissionGranted = await requestPermissionIfNeeded()

            guard permissionGranted, !Task.isCancelled else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Rest complete"
            content.body = "Time to continue your workout."
            content.sound = .default

            // Calculate this after the permission question is closed.
            // This keeps the original finish time even if the user answers slowly.
            let secondsUntilFinish = max(1, endDate.timeIntervalSinceNow)

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: secondsUntilFinish,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: notificationIdentifier,
                content: content,
                trigger: trigger
            )

            try? await notificationCenter.add(request)
        }
    }

    /// Removes the pending notification when the timer is paused or reset.
    func cancelNotification() {
        schedulingTask?.cancel()
        schedulingTask = nil

        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier]
        )
    }

    /// Requests permission only the first time. Later calls use the saved decision.
    private func requestPermissionIfNeeded() async -> Bool {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await notificationCenter.requestAuthorization(
                options: [.alert, .sound]
            )) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
}
