import Foundation

enum EventFormatting {
    static func alarmString(hasAlarms: Bool, alarmOffsets: [TimeInterval]) -> String? {
        guard hasAlarms, let offset = alarmOffsets.first else { return nil }
        let minutes = Int(-offset / 60)
        if minutes <= 0 { return "at start" }
        if minutes < 60 { return "\(minutes)m before" }
        let hours = minutes / 60
        let rem = minutes % 60
        if rem == 0 { return "\(hours)h before" }
        return "\(hours)h \(rem)m before"
    }

    struct SnoozeOption {
        let label: String
        let minutes: Int
    }

    static func snoozeOptions(minutesUntilStart: Int) -> [SnoozeOption] {
        var options: [SnoozeOption] = [SnoozeOption(label: "1m", minutes: 1)]
        if minutesUntilStart > 5 {
            options.append(SnoozeOption(label: "5m before", minutes: minutesUntilStart - 5))
        }
        if minutesUntilStart > 2 {
            options.append(SnoozeOption(label: "2m before", minutes: minutesUntilStart - 2))
        }
        if minutesUntilStart > 1 {
            options.append(SnoozeOption(label: "Start", minutes: minutesUntilStart))
        }
        return options
    }

    static func relativeTime(from startDate: Date, now: Date = Date()) -> String {
        let interval = startDate.timeIntervalSince(now)
        if interval < 0 { return "" }
        let minutes = Int(interval / 60)
        if minutes < 1 { return "now" }
        if minutes < 60 { return "in \(minutes)m" }
        let hours = minutes / 60
        let remainingMin = minutes % 60
        if remainingMin == 0 { return "in \(hours)h" }
        return "in \(hours)h \(remainingMin)m"
    }
}
