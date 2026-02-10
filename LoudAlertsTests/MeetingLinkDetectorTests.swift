import XCTest

final class MeetingLinkDetectorTests: XCTestCase {

    // MARK: - Microsoft Teams

    func testTeamsStandardURL() {
        let url = URL(string: "https://teams.microsoft.com/l/meetup-join/19%3ameeting_abc123")!
        let result = MeetingLinkDetector.detect(url: url, location: nil, notes: nil)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .teams)
    }

    func testTeamsLiveURL() {
        let result = MeetingLinkDetector.detect(
            url: nil,
            location: "https://teams.live.com/meet/abc123",
            notes: nil
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .teams)
    }

    func testTeamsWithQueryParams() {
        let url = URL(string: "https://teams.microsoft.com/l/meetup-join/19%3ameeting_abc?context=%7B%22Tid%22%7D")!
        let result = MeetingLinkDetector.detect(url: url, location: nil, notes: nil)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .teams)
    }

    // MARK: - Zoom

    func testZoomStandardURL() {
        let result = MeetingLinkDetector.detect(
            url: URL(string: "https://zoom.us/j/1234567890"),
            location: nil,
            notes: nil
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .zoom)
    }

    func testZoomWebinarURL() {
        let result = MeetingLinkDetector.detect(
            url: URL(string: "https://zoom.us/w/1234567890"),
            location: nil,
            notes: nil
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .zoom)
    }

    func testZoomSubdomainURL() {
        let result = MeetingLinkDetector.detect(
            url: URL(string: "https://company.zoom.us/j/9876543210"),
            location: nil,
            notes: nil
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .zoom)
    }

    // MARK: - Google Meet

    func testGoogleMeetStandardURL() {
        let result = MeetingLinkDetector.detect(
            url: URL(string: "https://meet.google.com/abc-defg-hij"),
            location: nil,
            notes: nil
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .googleMeet)
    }

    func testGoogleMeetWithTrailingParams() {
        let result = MeetingLinkDetector.detect(
            url: URL(string: "https://meet.google.com/abc-defg-hij?authuser=0"),
            location: nil,
            notes: nil
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .googleMeet)
    }

    // MARK: - Webex

    func testWebexMeetURL() {
        let result = MeetingLinkDetector.detect(
            url: URL(string: "https://company.webex.com/meet/john.doe"),
            location: nil,
            notes: nil
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .webex)
    }

    func testWebexJoinURL() {
        let result = MeetingLinkDetector.detect(
            url: URL(string: "https://company.webex.com/join/john.doe"),
            location: nil,
            notes: nil
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .webex)
    }

    func testWebexSubdomainURL() {
        let result = MeetingLinkDetector.detect(
            url: URL(string: "https://acme.my.webex.com/meet/user123"),
            location: nil,
            notes: nil
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .webex)
    }

    // MARK: - Slack

    func testSlackHuddleURL() {
        let result = MeetingLinkDetector.detect(
            url: URL(string: "https://app.slack.com/huddle/T12345/C67890"),
            location: nil,
            notes: nil
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .slack)
    }

    // MARK: - Priority: URL > location > notes

    func testURLFieldTakesPriority() {
        let teamsURL = URL(string: "https://teams.microsoft.com/l/meetup-join/test")!
        let result = MeetingLinkDetector.detect(
            url: teamsURL,
            location: "https://zoom.us/j/111",
            notes: "https://meet.google.com/abc-defg-hij"
        )
        XCTAssertEqual(result?.service, .teams)
    }

    func testLocationTakesPriorityOverNotes() {
        let result = MeetingLinkDetector.detect(
            url: nil,
            location: "https://zoom.us/j/111",
            notes: "https://meet.google.com/abc-defg-hij"
        )
        XCTAssertEqual(result?.service, .zoom)
    }

    func testNotesUsedAsFallback() {
        let result = MeetingLinkDetector.detect(
            url: nil,
            location: nil,
            notes: "Join at https://meet.google.com/abc-defg-hij"
        )
        XCTAssertEqual(result?.service, .googleMeet)
    }

    // MARK: - HTML stripping

    func testHTMLNotesLinkExtracted() {
        // Real calendar notes often contain URLs as visible text within HTML tags
        let html = "<html><body>Join the meeting: <a href=\"https://zoom.us/j/123456\">https://zoom.us/j/123456</a></body></html>"
        let result = MeetingLinkDetector.detect(url: nil, location: nil, notes: html)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .zoom)
    }

    // MARK: - No match

    func testPlainTextReturnsNil() {
        let result = MeetingLinkDetector.detect(
            url: nil,
            location: "Conference Room B",
            notes: "Bring your laptop"
        )
        XCTAssertNil(result)
    }

    func testEmptyInputsReturnsNil() {
        let result = MeetingLinkDetector.detect(url: nil, location: nil, notes: nil)
        XCTAssertNil(result)
    }

    func testEmptyStringsReturnNil() {
        let result = MeetingLinkDetector.detect(url: nil, location: "", notes: "")
        XCTAssertNil(result)
    }

    // MARK: - Multiple links

    func testFirstMatchWins() {
        let notes = "Zoom: https://zoom.us/j/111 or Teams: https://teams.microsoft.com/l/meetup-join/222"
        let result = MeetingLinkDetector.detect(url: nil, location: nil, notes: notes)
        // The detector iterates patterns in order (Teams first), so Teams should match first
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .teams)
    }

    // MARK: - Case insensitive

    func testCaseInsensitiveURLs() {
        let result = MeetingLinkDetector.detect(
            url: URL(string: "HTTPS://ZOOM.US/j/1234567890"),
            location: nil,
            notes: nil
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.service, .zoom)
    }

    // MARK: - Edge cases

    func testPartialURLDoesNotMatch() {
        let result = MeetingLinkDetector.detect(
            url: nil,
            location: "zoom.us without protocol",
            notes: nil
        )
        XCTAssertNil(result)
    }
}
