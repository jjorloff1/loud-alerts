import Foundation

enum MeetingService: String, CaseIterable {
    case teams = "Microsoft Teams"
    case zoom = "Zoom"
    case googleMeet = "Google Meet"
    case webex = "Webex"
    case slack = "Slack Huddle"

    var iconName: String {
        self == .slack ? "headphones" : "video.fill"
    }
}

struct MeetingLink: Equatable {
    let url: URL
    let service: MeetingService

    var displayName: String {
        "Join \(service.rawValue)"
    }
}
