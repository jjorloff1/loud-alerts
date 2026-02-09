import Foundation

enum MeetingService: String, CaseIterable {
    case teams = "Microsoft Teams"
    case zoom = "Zoom"
    case googleMeet = "Google Meet"
    case webex = "Webex"
    case slack = "Slack Huddle"

    var iconName: String {
        switch self {
        case .teams: return "video.fill"
        case .zoom: return "video.fill"
        case .googleMeet: return "video.fill"
        case .webex: return "video.fill"
        case .slack: return "headphones"
        }
    }
}

struct MeetingLink: Equatable {
    let url: URL
    let service: MeetingService

    var displayName: String {
        "Join \(service.rawValue)"
    }
}
