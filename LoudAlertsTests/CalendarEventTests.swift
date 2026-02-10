import XCTest

final class CalendarEventTests: XCTestCase {

    // MARK: - Helpers

    private func makeEvent(
        id: String = "test-id",
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(3600),
        isAllDay: Bool = false,
        hasAlarms: Bool = false,
        alarmOffsets: [TimeInterval] = [],
        meetingLink: MeetingLink? = nil
    ) -> CalendarEvent {
        CalendarEvent(
            id: id,
            title: "Test Event",
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: nil,
            notes: nil,
            url: nil,
            calendarID: "cal-1",
            calendarName: "Calendar",
            calendarColor: nil,
            hasAlarms: hasAlarms,
            alarmOffsets: alarmOffsets,
            meetingLink: meetingLink
        )
    }

    // MARK: - isHappeningNow

    func testIsHappeningNowTrueWhenCurrentlyInProgress() {
        let event = makeEvent(
            startDate: Date().addingTimeInterval(-600), // started 10m ago
            endDate: Date().addingTimeInterval(600) // ends in 10m
        )
        XCTAssertTrue(event.isHappeningNow)
    }

    func testIsHappeningNowFalseWhenInFuture() {
        let event = makeEvent(
            startDate: Date().addingTimeInterval(600),
            endDate: Date().addingTimeInterval(3600)
        )
        XCTAssertFalse(event.isHappeningNow)
    }

    func testIsHappeningNowFalseWhenInPast() {
        let event = makeEvent(
            startDate: Date().addingTimeInterval(-7200),
            endDate: Date().addingTimeInterval(-3600)
        )
        XCTAssertFalse(event.isHappeningNow)
    }

    func testIsHappeningNowTrueAtExactStartTime() {
        let now = Date()
        let event = makeEvent(
            startDate: now,
            endDate: now.addingTimeInterval(3600)
        )
        XCTAssertTrue(event.isHappeningNow)
    }

    func testIsHappeningNowFalseAtExactEndTime() {
        let now = Date()
        let event = makeEvent(
            startDate: now.addingTimeInterval(-3600),
            endDate: now
        )
        // endDate > now is required, so exactly at end time it's false
        XCTAssertFalse(event.isHappeningNow)
    }

    // MARK: - Equality

    func testEqualityBasedOnIDOnly() {
        let event1 = makeEvent(id: "same-id", startDate: Date())
        let event2 = makeEvent(id: "same-id", startDate: Date().addingTimeInterval(100))
        XCTAssertEqual(event1, event2)
    }

    func testInequalityWithDifferentIDs() {
        let event1 = makeEvent(id: "id-1")
        let event2 = makeEvent(id: "id-2")
        XCTAssertNotEqual(event1, event2)
    }

    // MARK: - testEvent()

    func testTestEventReturnsValidFields() {
        let event = CalendarEvent.testEvent()
        XCTAssertTrue(event.id.hasPrefix("test-"))
        XCTAssertEqual(event.title, "Test Meeting — Loud Alerts Demo")
        XCTAssertFalse(event.isAllDay)
        XCTAssertTrue(event.hasAlarms)
        XCTAssertEqual(event.alarmOffsets, [-300])
        XCTAssertEqual(event.calendarName, "Test Calendar")
    }

    func testTestEventHasMeetingLink() {
        let event = CalendarEvent.testEvent()
        XCTAssertNotNil(event.meetingLink)
        XCTAssertEqual(event.meetingLink?.service, .teams)
    }

    func testTestEventUniqueIDs() {
        let event1 = CalendarEvent.testEvent()
        let event2 = CalendarEvent.testEvent()
        XCTAssertNotEqual(event1.id, event2.id)
    }
}
