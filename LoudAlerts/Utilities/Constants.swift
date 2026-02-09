import Foundation

enum Constants {
    static let appName = "Loud Alerts"
    static let bundleIdentifier = "com.loudalerts.app"

    enum Defaults {
        static let reminderMinutes = 5
        static let pollIntervalSeconds: TimeInterval = 300
        static let eventLookAheadHours = 24
    }

    enum Snooze {
        static let options = [1, 5, 10] // minutes
    }
}
