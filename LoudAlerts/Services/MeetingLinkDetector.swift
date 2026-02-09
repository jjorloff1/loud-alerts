import Foundation

struct MeetingLinkDetector {
    // Patterns based on MeetingBar's open-source detection
    private static let patterns: [(MeetingService, String)] = [
        (.teams, #"https?://teams\.microsoft\.com/l/meetup-join/[^\s<\"]+"#),
        (.teams, #"https?://teams\.live\.com/meet/[^\s<\"]+"#),
        (.zoom, #"https?://[\w.-]*zoom\.us/[jw]/[^\s<\"]+"#),
        (.googleMeet, #"https?://meet\.google\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}[^\s<\"]*"#),
        (.webex, #"https?://[\w.-]*\.webex\.com/(?:meet|join)/[^\s<\"]+"#),
        (.slack, #"https?://app\.slack\.com/huddle/[^\s<\"]+"#),
    ]

    static func detect(url: URL?, location: String?, notes: String?) -> MeetingLink? {
        // Check URL field first
        if let url {
            let urlString = url.absoluteString
            if let link = findLink(in: urlString) {
                return link
            }
        }

        // Check location field
        if let location {
            if let link = findLink(in: location) {
                return link
            }
        }

        // Check notes field (may contain HTML)
        if let notes {
            let stripped = stripHTML(notes)
            if let link = findLink(in: stripped) {
                return link
            }
        }

        return nil
    }

    private static func findLink(in text: String) -> MeetingLink? {
        for (service, pattern) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range),
               let matchRange = Range(match.range, in: text),
               let url = URL(string: String(text[matchRange])) {
                return MeetingLink(url: url, service: service)
            }
        }
        return nil
    }

    private static func stripHTML(_ html: String) -> String {
        guard let data = html.data(using: .utf8) else { return html }
        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) {
            return attributed.string
        }
        // Fallback: simple regex strip
        return html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
    }
}
