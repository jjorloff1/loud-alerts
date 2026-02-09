import Foundation

extension Date {
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    var relativeFutureString: String {
        let interval = timeIntervalSinceNow
        if interval < 0 { return "now" }
        let minutes = Int(interval / 60)
        if minutes < 1 { return "< 1m" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let remainingMin = minutes % 60
        if remainingMin == 0 { return "\(hours)h" }
        return "\(hours)h \(remainingMin)m"
    }
}
