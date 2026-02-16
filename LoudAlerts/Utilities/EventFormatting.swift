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

    enum SnoozeDelay {
        case fromNow(seconds: TimeInterval)
        case beforeStart(seconds: TimeInterval)

        func fireDate(eventStart: Date) -> Date {
            switch self {
            case .fromNow(let s): return Date().addingTimeInterval(s)
            case .beforeStart(let s): return eventStart.addingTimeInterval(-s)
            }
        }
    }

    struct SnoozeOption {
        let label: String
        let delay: SnoozeDelay
    }

    struct SnoozeOptionGroups {
        let standard: [SnoozeOption]
        let relativeToStart: [SnoozeOption]
    }

    static func snoozeOptionGroups(minutesUntilStart: Int) -> SnoozeOptionGroups {
        let standard: [SnoozeOption] = [
            SnoozeOption(label: "1m", delay: .fromNow(seconds: 60)),
            SnoozeOption(label: "5m", delay: .fromNow(seconds: 300)),
        ]

        var relative: [SnoozeOption] = []
        if minutesUntilStart > 5 {
            relative.append(SnoozeOption(label: "5m before", delay: .beforeStart(seconds: 300)))
        }
        if minutesUntilStart > 2 {
            relative.append(SnoozeOption(label: "2m before", delay: .beforeStart(seconds: 120)))
        }
        if minutesUntilStart > 1 {
            relative.append(SnoozeOption(label: "Start", delay: .beforeStart(seconds: 0)))
        }

        return SnoozeOptionGroups(standard: standard, relativeToStart: relative)
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
