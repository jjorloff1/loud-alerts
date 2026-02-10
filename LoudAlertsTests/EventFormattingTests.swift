import XCTest

final class EventFormattingTests: XCTestCase {

    // MARK: - alarmString

    func testAlarmString5MinutesBefore() {
        let result = EventFormatting.alarmString(hasAlarms: true, alarmOffsets: [-300])
        XCTAssertEqual(result, "5m before")
    }

    func testAlarmStringAtStart() {
        let result = EventFormatting.alarmString(hasAlarms: true, alarmOffsets: [0])
        XCTAssertEqual(result, "at start")
    }

    func testAlarmString60MinutesBefore() {
        let result = EventFormatting.alarmString(hasAlarms: true, alarmOffsets: [-3600])
        XCTAssertEqual(result, "1h before")
    }

    func testAlarmString90MinutesBefore() {
        let result = EventFormatting.alarmString(hasAlarms: true, alarmOffsets: [-5400])
        XCTAssertEqual(result, "1h 30m before")
    }

    func testAlarmStringNoAlarms() {
        let result = EventFormatting.alarmString(hasAlarms: false, alarmOffsets: [])
        XCTAssertNil(result)
    }

    func testAlarmStringHasAlarmsButEmptyOffsets() {
        let result = EventFormatting.alarmString(hasAlarms: true, alarmOffsets: [])
        XCTAssertNil(result)
    }

    func testAlarmStringPositiveOffsetTreatedAsAtStart() {
        // Positive offset means alarm fires after start (unusual but possible)
        let result = EventFormatting.alarmString(hasAlarms: true, alarmOffsets: [300])
        XCTAssertEqual(result, "at start")
    }

    func testAlarmString15MinutesBefore() {
        let result = EventFormatting.alarmString(hasAlarms: true, alarmOffsets: [-900])
        XCTAssertEqual(result, "15m before")
    }

    func testAlarmString2HoursBefore() {
        let result = EventFormatting.alarmString(hasAlarms: true, alarmOffsets: [-7200])
        XCTAssertEqual(result, "2h before")
    }

    func testAlarmString2Hours30MinBefore() {
        let result = EventFormatting.alarmString(hasAlarms: true, alarmOffsets: [-9000])
        XCTAssertEqual(result, "2h 30m before")
    }

    // MARK: - relativeTime

    /// Helper that pins `now` to a single Date, avoiding flaky timing between two Date() calls.
    private func relativeTime(secondsFromNow interval: TimeInterval) -> String {
        let now = Date()
        return EventFormatting.relativeTime(from: now.addingTimeInterval(interval), now: now)
    }

    func testRelativeTime30Seconds() {
        XCTAssertEqual(relativeTime(secondsFromNow: 30), "now")
    }

    func testRelativeTime5Minutes() {
        XCTAssertEqual(relativeTime(secondsFromNow: 300), "in 5m")
    }

    func testRelativeTime90Minutes() {
        XCTAssertEqual(relativeTime(secondsFromNow: 5400), "in 1h 30m")
    }

    func testRelativeTime2Hours() {
        XCTAssertEqual(relativeTime(secondsFromNow: 7200), "in 2h")
    }

    func testRelativeTimePastDate() {
        XCTAssertEqual(relativeTime(secondsFromNow: -60), "")
    }

    func testRelativeTime1Minute() {
        XCTAssertEqual(relativeTime(secondsFromNow: 60), "in 1m")
    }
}
