import XCTest

final class MeetingLinkModelTests: XCTestCase {

    // MARK: - MeetingService iconName

    func testIconNameForVideoServices() {
        XCTAssertEqual(MeetingService.teams.iconName, "video.fill")
        XCTAssertEqual(MeetingService.zoom.iconName, "video.fill")
        XCTAssertEqual(MeetingService.googleMeet.iconName, "video.fill")
        XCTAssertEqual(MeetingService.webex.iconName, "video.fill")
    }

    func testIconNameForSlack() {
        XCTAssertEqual(MeetingService.slack.iconName, "headphones")
    }

    // MARK: - MeetingLink displayName

    func testDisplayNameFormatsCorrectly() {
        let link = MeetingLink(url: URL(string: "https://zoom.us/j/123")!, service: .zoom)
        XCTAssertEqual(link.displayName, "Join Zoom")
    }

    func testDisplayNameForAllServices() {
        let services: [(MeetingService, String)] = [
            (.teams, "Join Microsoft Teams"),
            (.zoom, "Join Zoom"),
            (.googleMeet, "Join Google Meet"),
            (.webex, "Join Webex"),
            (.slack, "Join Slack Huddle"),
        ]
        for (service, expected) in services {
            let link = MeetingLink(url: URL(string: "https://example.com")!, service: service)
            XCTAssertEqual(link.displayName, expected)
        }
    }

    // MARK: - CaseIterable

    func testAllCasesContainsAllFiveServices() {
        XCTAssertEqual(MeetingService.allCases.count, 5)
        XCTAssertTrue(MeetingService.allCases.contains(.teams))
        XCTAssertTrue(MeetingService.allCases.contains(.zoom))
        XCTAssertTrue(MeetingService.allCases.contains(.googleMeet))
        XCTAssertTrue(MeetingService.allCases.contains(.webex))
        XCTAssertTrue(MeetingService.allCases.contains(.slack))
    }
}
