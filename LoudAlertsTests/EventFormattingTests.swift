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

    // MARK: - SnoozeDelay.fireDate

    func testFromNowFireDate() {
        let eventStart = Date().addingTimeInterval(600) // irrelevant for .fromNow
        let before = Date().addingTimeInterval(300)
        let fireDate = EventFormatting.SnoozeDelay.fromNow(seconds: 300).fireDate(eventStart: eventStart)
        let after = Date().addingTimeInterval(300)
        // fireDate should be ~now+300s, bounded by before/after
        XCTAssertGreaterThanOrEqual(fireDate, before)
        XCTAssertLessThanOrEqual(fireDate, after)
    }

    func testBeforeStartFireDateFiveMinutes() {
        let eventStart = Date().addingTimeInterval(600) // 10 min from now
        let fireDate = EventFormatting.SnoozeDelay.beforeStart(seconds: 300).fireDate(eventStart: eventStart)
        // Should fire at eventStart - 300s = now + 300s
        let expected = eventStart.addingTimeInterval(-300)
        XCTAssertEqual(fireDate, expected)
    }

    func testBeforeStartFireDateAtStart() {
        let eventStart = Date().addingTimeInterval(600)
        let fireDate = EventFormatting.SnoozeDelay.beforeStart(seconds: 0).fireDate(eventStart: eventStart)
        // "Start" fires exactly at eventStart
        XCTAssertEqual(fireDate, eventStart)
    }

    func testBeforeStartIsIndependentOfCurrentTime() {
        // The key fix: .beforeStart anchors to eventStart, not to Date()
        let eventStart = Date(timeIntervalSince1970: 1_000_000)
        let delay = EventFormatting.SnoozeDelay.beforeStart(seconds: 120)
        let fireDate1 = delay.fireDate(eventStart: eventStart)
        // Even if we call again later, the result is the same absolute time
        let fireDate2 = delay.fireDate(eventStart: eventStart)
        XCTAssertEqual(fireDate1, fireDate2)
        XCTAssertEqual(fireDate1, eventStart.addingTimeInterval(-120))
    }

    // MARK: - snoozeOptionGroups

    func testSnoozeGroupsStandardAlwaysHasTwoOptions() {
        let groups = EventFormatting.snoozeOptionGroups(minutesUntilStart: 15)
        XCTAssertEqual(groups.standard.count, 2)
        XCTAssertEqual(groups.standard[0].label, "1m")
        XCTAssertEqual(groups.standard[1].label, "5m")
    }

    func testSnoozeGroupsAllRelativeWhenFarFromStart() {
        let groups = EventFormatting.snoozeOptionGroups(minutesUntilStart: 15)
        XCTAssertEqual(groups.relativeToStart.count, 3)
        XCTAssertEqual(groups.relativeToStart[0].label, "5m before")
        XCTAssertEqual(groups.relativeToStart[1].label, "2m before")
        XCTAssertEqual(groups.relativeToStart[2].label, "Start")
    }

    func testSnoozeGroupsFiveMinutesOut() {
        // At exactly 5 min, "5m before" hidden (would fire immediately)
        let groups = EventFormatting.snoozeOptionGroups(minutesUntilStart: 5)
        let labels = groups.relativeToStart.map(\.label)
        XCTAssertFalse(labels.contains("5m before"))
        XCTAssertTrue(labels.contains("2m before"))
        XCTAssertTrue(labels.contains("Start"))
    }

    func testSnoozeGroupsTwoMinutesOut() {
        let groups = EventFormatting.snoozeOptionGroups(minutesUntilStart: 2)
        let labels = groups.relativeToStart.map(\.label)
        XCTAssertFalse(labels.contains("5m before"))
        XCTAssertFalse(labels.contains("2m before"))
        XCTAssertTrue(labels.contains("Start"))
    }

    func testSnoozeGroupsOneMinuteOutNoRelative() {
        // At 1 min, "Start" hidden (would be <=1 min)
        let groups = EventFormatting.snoozeOptionGroups(minutesUntilStart: 1)
        XCTAssertTrue(groups.relativeToStart.isEmpty)
    }

    func testSnoozeGroupsAlreadyStartedNoRelative() {
        let groups = EventFormatting.snoozeOptionGroups(minutesUntilStart: 0)
        XCTAssertTrue(groups.relativeToStart.isEmpty)
        // Standard options still available
        XCTAssertEqual(groups.standard.count, 2)
    }

    func testSnoozeGroupsSixMinutesOutIncludesFiveBefore() {
        let groups = EventFormatting.snoozeOptionGroups(minutesUntilStart: 6)
        let labels = groups.relativeToStart.map(\.label)
        XCTAssertTrue(labels.contains("5m before"))
    }

    func testSnoozeGroupsRelativeDelaysAreBeforeStart() {
        let groups = EventFormatting.snoozeOptionGroups(minutesUntilStart: 15)
        for option in groups.relativeToStart {
            if case .beforeStart = option.delay {
                // expected
            } else {
                XCTFail("Relative option '\(option.label)' should use .beforeStart delay")
            }
        }
    }

    func testSnoozeGroupsStandardDelaysAreFromNow() {
        let groups = EventFormatting.snoozeOptionGroups(minutesUntilStart: 15)
        for option in groups.standard {
            if case .fromNow = option.delay {
                // expected
            } else {
                XCTFail("Standard option '\(option.label)' should use .fromNow delay")
            }
        }
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
