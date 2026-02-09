import Foundation

enum AlertState: Equatable {
    case pending
    case scheduled(fireDate: Date)
    case showing
    case snoozed(until: Date)
    case dismissed
}
