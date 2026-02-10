import Foundation

struct MeetingLinkDetector {
    // Pre-compiled patterns based on MeetingBar's open-source detection
    private static let patterns: [(MeetingService, NSRegularExpression)] = {
        let raw: [(MeetingService, String)] = [
            (.teams, #"https?://teams\.microsoft\.com/l/meetup-join/[^\s<\"]+"#),
            (.teams, #"https?://teams\.live\.com/meet/[^\s<\"]+"#),
            (.zoom, #"https?://[\w.-]*zoom\.us/[jw]/[^\s<\"]+"#),
            (.googleMeet, #"https?://meet\.google\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}[^\s<\"]*"#),
            (.webex, #"https?://[\w.-]*\.webex\.com/(?:meet|join)/[^\s<\"]+"#),
            (.slack, #"https?://app\.slack\.com/huddle/[^\s<\"]+"#),
        ]
        return raw.compactMap { service, pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
            return (service, regex)
        }
    }()

    static func detect(url: URL?, location: String?, notes: String?) -> MeetingLink? {
        if let url, let link = findLink(in: url.absoluteString) {
            return link
        }
        if let location, let link = findLink(in: location) {
            return link
        }
        if let notes, let link = findLink(in: stripHTML(notes)) {
            return link
        }
        return nil
    }

    private static func findLink(in text: String) -> MeetingLink? {
        let range = NSRange(text.startIndex..., in: text)
        for (service, regex) in patterns {
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
