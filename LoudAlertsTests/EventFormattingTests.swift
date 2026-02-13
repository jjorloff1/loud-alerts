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

    // MARK: - Custom "now" parameter tests

    func testRelativeTimeWithCustomNowParameter() {
        // Create a fixed "yesterday" time and an event that's today
        let yesterday = Date().addingTimeInterval(-86400) // 24 hours ago
        let today = Date()

        // Event is "today" from the perspective of "yesterday"
        let result = EventFormatting.relativeTime(from: today, now: yesterday)

        // Should show "in 24h" since event is 24 hours in the future from yesterday
        XCTAssertEqual(result, "in 24h")
    }

    func testRelativeTimeWithDifferentNowValues() {
        // Use a fixed base time to avoid timing issues between Date() calls
        let baseNow = Date()
        let eventDate = baseNow.addingTimeInterval(7200) // 2 hours from base

        // Calculate from base now - should show "in 2h"
        let resultFromNow = EventFormatting.relativeTime(from: eventDate, now: baseNow)
        XCTAssertEqual(resultFromNow, "in 2h")

        // Calculate from 1 hour in the future - should show "in 1h"
        let futureNow = baseNow.addingTimeInterval(3600)
        let resultFromFuture = EventFormatting.relativeTime(from: eventDate, now: futureNow)
        XCTAssertEqual(resultFromFuture, "in 1h")
    }

    // MARK: - snoozeOptions

    func testSnoozeOptionsAllFourWhenFarFromStart() {
        let options = EventFormatting.snoozeOptions(minutesUntilStart: 15)
        XCTAssertEqual(options.count, 4)
        XCTAssertEqual(options[0].label, "1m")
        XCTAssertEqual(options[0].minutes, 1)
        XCTAssertEqual(options[1].label, "5m before")
        XCTAssertEqual(options[1].minutes, 10) // 15 - 5
        XCTAssertEqual(options[2].label, "2m before")
        XCTAssertEqual(options[2].minutes, 13) // 15 - 2
        XCTAssertEqual(options[3].label, "Start")
        XCTAssertEqual(options[3].minutes, 15)
    }

    func testSnoozeOptionsThreeWhenFiveMinutesOut() {
        // At exactly 5 min, "5m before" would be 0-minute snooze, so it's hidden
        let options = EventFormatting.snoozeOptions(minutesUntilStart: 5)
        XCTAssertEqual(options.count, 3)
        XCTAssertEqual(options[0].label, "1m")
        XCTAssertEqual(options[1].label, "2m before")
        XCTAssertEqual(options[1].minutes, 3) // 5 - 2
        XCTAssertEqual(options[2].label, "Start")
        XCTAssertEqual(options[2].minutes, 5)
    }

    func testSnoozeOptionsTwoWhenTwoMinutesOut() {
        // At exactly 2 min, "2m before" would be 0 min, so hidden
        let options = EventFormatting.snoozeOptions(minutesUntilStart: 2)
        XCTAssertEqual(options.count, 2)
        XCTAssertEqual(options[0].label, "1m")
        XCTAssertEqual(options[1].label, "Start")
        XCTAssertEqual(options[1].minutes, 2)
    }

    func testSnoozeOptionsOnlyOneMinuteWhenOneMinuteOut() {
        // At 1 min, "Start" would be same as 1m, so hidden
        let options = EventFormatting.snoozeOptions(minutesUntilStart: 1)
        XCTAssertEqual(options.count, 1)
        XCTAssertEqual(options[0].label, "1m")
    }

    func testSnoozeOptionsOnlyOneMinuteWhenAlreadyStarted() {
        let options = EventFormatting.snoozeOptions(minutesUntilStart: 0)
        XCTAssertEqual(options.count, 1)
        XCTAssertEqual(options[0].label, "1m")
        XCTAssertEqual(options[0].minutes, 1)
    }

    func testSnoozeOptionsFiveMinBeforeShownAtSixMinutes() {
        // At 6 min out, "5m before" = 1 min snooze — just barely worth showing
        let options = EventFormatting.snoozeOptions(minutesUntilStart: 6)
        let labels = options.map(\.label)
        XCTAssertTrue(labels.contains("5m before"))
        let fiveBefore = options.first { $0.label == "5m before" }!
        XCTAssertEqual(fiveBefore.minutes, 1) // 6 - 5
    }

    func testSnoozeOptionsMinutesCalculation() {
        let options = EventFormatting.snoozeOptions(minutesUntilStart: 30)
        XCTAssertEqual(options.count, 4)
        XCTAssertEqual(options[1].minutes, 25) // 30 - 5
        XCTAssertEqual(options[2].minutes, 28) // 30 - 2
        XCTAssertEqual(options[3].minutes, 30)
    }

    func testRelativeTimeStaleViewBehavior() {
        // Simulates the bug: view was rendered yesterday but is showing times as if it's still yesterday
        let baseNow = Date()
        let yesterdayNow = baseNow.addingTimeInterval(-18 * 3600) // 18 hours ago
        let eventTime = baseNow // Event is at "current" time

        // If we calculate relative time using yesterday's "now", it shows as future
        let staleResult = EventFormatting.relativeTime(from: eventTime, now: yesterdayNow)
        XCTAssertEqual(staleResult, "in 18h")

        // But with current "now", it should show as "now" (within 1 minute)
        let freshResult = EventFormatting.relativeTime(from: eventTime, now: baseNow)
        XCTAssertEqual(freshResult, "now")
    }
}
