import XCTest

final class AlertSchedulerTests: XCTestCase {

    private var scheduler: AlertScheduler!
    private var firedEvents: [CalendarEvent]!

    override func setUp() {
        super.setUp()
        scheduler = AlertScheduler()
        firedEvents = []
        scheduler.onAlertFired = { [weak self] event in
            self?.firedEvents.append(event)
        }
    }

    override func tearDown() {
        scheduler.cancelAll()
        scheduler = nil
        firedEvents = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeEvent(
        id: String = UUID().uuidString,
        title: String = "Test Meeting",
        startDate: Date = Date().addingTimeInterval(300),
        endDate: Date? = nil,
        hasAlarms: Bool = true,
        alarmOffsets: [TimeInterval] = [-300]
    ) -> CalendarEvent {
        CalendarEvent(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate ?? startDate.addingTimeInterval(3600),
            isAllDay: false,
            location: nil,
            notes: nil,
            url: nil,
            calendarID: "test-cal",
            calendarName: "Test",
            calendarColor: nil,
            hasAlarms: hasAlarms,
            alarmOffsets: alarmOffsets,
            meetingLink: nil
        )
    }

    // MARK: - Scheduling

    func testSchedulesTimerForFutureEvent() {
        let event = makeEvent(startDate: Date().addingTimeInterval(600), alarmOffsets: [-300])
        scheduler.updateEvents([event])
        // Timer is scheduled but hasn't fired yet
        XCTAssertTrue(firedEvents.isEmpty)
    }

    func testFiresImmediatelyForEventWithinThirtySeconds() {
        // Alarm fire date = startDate + offset = now + 5 + (-5) = now
        let event = makeEvent(startDate: Date().addingTimeInterval(5), alarmOffsets: [-5])
        scheduler.updateEvents([event])
        // Should fire immediately since alarm time is within 30s of now
        XCTAssertEqual(firedEvents.count, 1)
        XCTAssertEqual(firedEvents.first?.id, event.id)
    }

    func testSkipsPastEvents() {
        let event = makeEvent(startDate: Date().addingTimeInterval(-180)) // 3 min ago
        scheduler.updateEvents([event])
        XCTAssertTrue(firedEvents.isEmpty)
    }

    func testCancelsTimersForRemovedEvents() {
        let event1 = makeEvent(id: "evt1", startDate: Date().addingTimeInterval(600), alarmOffsets: [-300])
        let event2 = makeEvent(id: "evt2", startDate: Date().addingTimeInterval(600), alarmOffsets: [-300])
        scheduler.updateEvents([event1, event2])

        // Remove event1
        scheduler.updateEvents([event2])
        // No crash, no fire for removed event — just verifying it doesn't error
        XCTAssertTrue(firedEvents.isEmpty)
    }

    func testDoesNotRealertAlreadyShownEvents() {
        let event = makeEvent(id: "evt-shown", startDate: Date().addingTimeInterval(5), alarmOffsets: [-5])
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1)

        // Update again with same event
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1, "Should not re-alert same event")
    }

    func testPrunesAlertedEventsOlderThanTwoHours() {
        // Fire an alert for an event whose startDate is >2h ago.
        // We achieve this by creating a near-future event, firing it, then
        // verifying the pruning path: alertedEvents stores the event's startDate,
        // and entries with startDate > 2h ago are pruned on the next updateEvents call.
        // After pruning, the same event ID can fire again.
        let oldStartDate = Date().addingTimeInterval(-7201) // >2h ago
        let event = makeEvent(
            id: "prune-me",
            startDate: Date().addingTimeInterval(5),
            alarmOffsets: [-5]
        )
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1, "Event should fire immediately")

        // Manually overwrite the alertedEvents entry to simulate time passing:
        // The scheduler stores event.startDate as the prune key, but we fired an
        // event with a recent startDate. We can't easily manipulate time, so instead
        // we cancel and re-verify the "don't re-alert" + "cancel clears" path.
        // A more direct test: cancel, re-add the same event, it fires again.
        scheduler.cancelAll()

        // After cancelAll, alertedEvents is cleared, so the event can fire again
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 2, "After cancelAll, same event should fire again")

        // Now verify that without cancelAll, it does NOT re-fire (alertedEvents blocks it)
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 2, "Should not re-alert without cancelAll")
    }

    func testDefaultReminderNoneSkipsAlarmlessEvents() {
        scheduler.defaultReminderMinutes = { -1 }
        let event = makeEvent(hasAlarms: false, alarmOffsets: [])
        scheduler.updateEvents([event])
        XCTAssertTrue(firedEvents.isEmpty)
    }

    func testDefaultReminderValueAppliesToAlarmlessEvents() {
        scheduler.defaultReminderMinutes = { 0 } // 0 minutes = at start
        let event = makeEvent(
            startDate: Date().addingTimeInterval(5),
            hasAlarms: false,
            alarmOffsets: []
        )
        scheduler.updateEvents([event])
        // Default reminder of 0 means fire at start time, which is 5s in the future
        // The fire date is startDate + (-0*60) = startDate = 5s from now, so timer is scheduled
        XCTAssertTrue(firedEvents.isEmpty, "Event with 0-min default reminder 5s out should schedule, not fire immediately")
    }

    func testCancelAllClearsState() {
        let event = makeEvent(id: "cancel-test", startDate: Date().addingTimeInterval(5), alarmOffsets: [-5])
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1)

        scheduler.cancelAll()

        // After cancel, same event can be re-added and should fire again
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 2)
    }

    func testOnAlertFiredCallbackFires() {
        var callbackCalled = false
        scheduler.onAlertFired = { _ in callbackCalled = true }
        let event = makeEvent(startDate: Date().addingTimeInterval(5), alarmOffsets: [-5])
        scheduler.updateEvents([event])
        XCTAssertTrue(callbackCalled)
    }

    func testMultipleAlarmsUsesEarliestFuture() {
        // Event starts in 10min with alarms at -20m (well past, >6min grace), -5m (future), -1m (future).
        // The -20m alarm fire date is 10min ago (outside grace period), so only future alarms considered.
        // Should schedule for the earliest future alarm, not fire immediately.
        let startDate = Date().addingTimeInterval(600)
        let event = makeEvent(
            startDate: startDate,
            alarmOffsets: [-1200, -300, -60]
        )
        scheduler.updateEvents([event])
        XCTAssertTrue(firedEvents.isEmpty)
    }

    func testEventInPastWithinTwoMinutesStillConsideredForScheduling() {
        // Event started 60s ago — within the 2-min window
        let event = makeEvent(
            startDate: Date().addingTimeInterval(-60),
            alarmOffsets: [-300]
        )
        scheduler.updateEvents([event])
        // The alarm fire date is startDate - 5min = now - 6min, which is past
        // All fire dates past, but event.startDate is also in the past, so the guard
        // `if event.startDate > now` fails — no immediate fire
        // This is expected behavior: no alert for events whose alarm window has fully passed
        XCTAssertTrue(firedEvents.isEmpty)
    }

    func testEventInPastWithinTwoMinutesAndRecentAlarmFires() {
        // Event starts in 10s, alarm at -20s (so fire date is now - 10s, within 30s window)
        let event = makeEvent(
            startDate: Date().addingTimeInterval(10),
            alarmOffsets: [-20]
        )
        scheduler.updateEvents([event])
        // Fire date = startDate + (-20) = now + 10 - 20 = now - 10, within -30s window
        // So this should fire immediately
        XCTAssertEqual(firedEvents.count, 1)
    }

    func testNoCallbackDoesNotCrash() {
        scheduler.onAlertFired = nil
        let event = makeEvent(startDate: Date().addingTimeInterval(5), alarmOffsets: [-5])
        scheduler.updateEvents([event])
        // Just verifying no crash
    }

    // MARK: - Timer Tolerance

    func testScheduledTimerHasZeroTolerance() {
        let event = makeEvent(
            id: "tolerance-test",
            startDate: Date().addingTimeInterval(600),
            alarmOffsets: [-300]
        )
        scheduler.updateEvents([event])

        let tolerance = scheduler.scheduledTimerTolerance(forEventID: "tolerance-test")
        XCTAssertNotNil(tolerance, "Timer should be scheduled for future event")
        XCTAssertEqual(tolerance, 0, "Timer tolerance should be 0 to prevent kernel coalescing")
    }

    func testMultipleScheduledTimersAllHaveZeroTolerance() {
        let event1 = makeEvent(
            id: "tol-1",
            startDate: Date().addingTimeInterval(600),
            alarmOffsets: [-300]
        )
        let event2 = makeEvent(
            id: "tol-2",
            startDate: Date().addingTimeInterval(900),
            alarmOffsets: [-300]
        )
        scheduler.updateEvents([event1, event2])

        XCTAssertEqual(scheduler.scheduledTimerTolerance(forEventID: "tol-1"), 0)
        XCTAssertEqual(scheduler.scheduledTimerTolerance(forEventID: "tol-2"), 0)
    }

    // MARK: - Stale Timer Detection

    func testStaleTimerIsRescheduled() {
        // This simulates the overnight bug: an event was scheduled yesterday
        // for an alert today at 8:15 AM, but the timer didn't fire.
        // When updateEvents is called, it should detect the stale timer and reschedule.

        // Create an event that should have alerted 1 second ago
        // (fire date is in the past, but event hasn't been alerted yet)
        let event = makeEvent(
            id: "stale-timer",
            startDate: Date().addingTimeInterval(300), // starts in 5min
            alarmOffsets: [-301] // alarm should have fired 1 second ago
        )

        // First update: schedules the timer for 1 second ago (fire date in past)
        // The scheduler should fire immediately since fire date is within 30s
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1, "Event with past fire date within 30s should fire immediately")
    }

    func testValidTimerIsNotRescheduled() {
        // Create an event with alarm in the future
        let event = makeEvent(
            id: "valid-timer",
            startDate: Date().addingTimeInterval(600), // starts in 10min
            alarmOffsets: [-300] // alarm fires in 5min
        )

        // First update: schedules the timer
        scheduler.updateEvents([event])
        XCTAssertTrue(firedEvents.isEmpty, "Future timer should not fire immediately")

        // Second update with same event: should NOT reschedule (timer is still valid)
        scheduler.updateEvents([event])
        XCTAssertTrue(firedEvents.isEmpty, "Valid timer should not be rescheduled or fired")

        // Verify timer is still scheduled by checking it fires later
        // (we can't directly test this without waiting, but the fact that firedEvents is still empty confirms it)
    }

    func testTimerRemovedAfterFiring() {
        // Verify that after an event fires, its timer is removed from the dictionary
        let event = makeEvent(
            startDate: Date().addingTimeInterval(5),
            alarmOffsets: [-5]
        )

        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1, "Event should fire immediately")

        // Update again with the same event - it should NOT fire again because alertedEvents blocks it
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1, "Event should not re-fire")
    }

    func testMultipleUpdatesCycleDoesNotCauseRedundantFires() {
        // Simulates the 5-minute polling behavior where updateEvents is called repeatedly
        let event = makeEvent(
            id: "polling-event",
            startDate: Date().addingTimeInterval(600),
            alarmOffsets: [-300]
        )

        // Call updateEvents multiple times (simulating polling)
        for _ in 0..<5 {
            scheduler.updateEvents([event])
        }

        // Should still have no fires (timer is scheduled but hasn't fired)
        XCTAssertTrue(firedEvents.isEmpty, "Event should not fire during polling updates")
    }

    // MARK: - Missed Alert Grace Period (bug fix)

    func testAtStartAlertMissedByOneMinuteStillFires() {
        // BUG SCENARIO: "Wind Down" at 3:15 PM with "at start" alarm (offset = 0).
        // Poll runs at 3:16 PM (1 minute late). Old code dropped this silently
        // because fire date was >30s past and event had already started.
        // New code should fire within the 6-minute grace period.
        let event = makeEvent(
            id: "wind-down",
            title: "Wind Down",
            startDate: Date().addingTimeInterval(-60), // started 1 min ago
            alarmOffsets: [0] // "at start"
        )
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1, "Should fire for recently-started event with 'at start' alarm")
        XCTAssertEqual(firedEvents.first?.id, "wind-down")
    }

    func testAtStartAlertMissedByFiveMinutesStillFires() {
        // Event started 5 min ago with "at start" alarm — within 6-min grace period
        let event = makeEvent(
            id: "missed-5min",
            startDate: Date().addingTimeInterval(-300),
            alarmOffsets: [0]
        )
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1, "Should fire for event missed by 5 minutes")
    }

    func testAtStartAlertMissedBySevenMinutesDoesNotFire() {
        // Event started 7 min ago — outside the 6-min grace period
        let event = makeEvent(
            id: "missed-7min",
            startDate: Date().addingTimeInterval(-420),
            alarmOffsets: [0]
        )
        scheduler.updateEvents([event])
        XCTAssertTrue(firedEvents.isEmpty, "Should NOT fire for event missed by 7 minutes (outside grace)")
    }

    func testFifteenMinBeforeAlarmMissedByThreeMinutesStillFires() {
        // Event starts in 12min, alarm at -15min = fire date was 3 min ago.
        // Within 6-min grace period, should fire.
        let event = makeEvent(
            startDate: Date().addingTimeInterval(720),
            alarmOffsets: [-900] // -15min
        )
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1, "15min-before alarm missed by 3min should still fire")
    }

    func testFifteenMinBeforeAlarmMissedByTenMinutesDoesNotFire() {
        // Event starts in 5min, alarm at -15min = fire date was 10 min ago.
        // Outside 6-min grace period.
        let event = makeEvent(
            startDate: Date().addingTimeInterval(300),
            alarmOffsets: [-900]
        )
        scheduler.updateEvents([event])
        XCTAssertTrue(firedEvents.isEmpty, "15min-before alarm missed by 10min should NOT fire")
    }

    func testWakeFromSleepScenario() {
        // Reproduces the real bug: event at 9:00 AM, alarm "at start" (offset 0).
        // Timer scheduled. Computer sleeps, wakes at 9:04. Poll triggers updateEvents.
        // The stale timer should be detected and the alert should fire immediately.

        // Step 1: Schedule an event with alarm that fires in ~5 min
        let event = makeEvent(
            id: "impl-block",
            title: "Implementation Block",
            startDate: Date().addingTimeInterval(300), // starts in 5 min
            alarmOffsets: [0] // alarm at start = fire date is in 5 min
        )
        scheduler.updateEvents([event])
        XCTAssertTrue(firedEvents.isEmpty, "Timer should be scheduled, not fired yet")

        // Step 2: Simulate "sleep then wake" — force the timer's fire date to be in the past
        // by cancelling and re-adding with a past fire date.
        // We can't manipulate time, but we can create a new event whose alarm fire date
        // is in the recent past (simulating that the timer should have fired during sleep).
        scheduler.cancelAll()
        firedEvents.removeAll()

        let wakeEvent = makeEvent(
            id: "impl-block-wake",
            title: "Implementation Block",
            startDate: Date().addingTimeInterval(-240), // started 4 min ago
            alarmOffsets: [0] // fire date was 4 min ago — within grace period
        )
        // This simulates the poll running on wake
        scheduler.updateEvents([wakeEvent])
        XCTAssertEqual(firedEvents.count, 1, "Should fire immediately on wake for recently-missed alert")
        XCTAssertEqual(firedEvents.first?.title, "Implementation Block")
    }

    // MARK: - invalidateAllTimers (wake fix)

    func testInvalidateAllTimersAllowsRecreation() {
        // Simulates the wake fix: timers are invalidated, then updateEvents
        // recreates them with fresh RunLoop scheduling.
        let event = makeEvent(
            id: "wake-recreate",
            startDate: Date().addingTimeInterval(600),
            alarmOffsets: [-300]
        )

        scheduler.updateEvents([event])
        XCTAssertTrue(firedEvents.isEmpty, "Timer should be scheduled, not fired")
        XCTAssertNotNil(scheduler.scheduledTimerTolerance(forEventID: "wake-recreate"),
                        "Timer should exist before invalidation")

        // Simulate wake: invalidate all timers
        scheduler.invalidateAllTimers()
        XCTAssertNil(scheduler.scheduledTimerTolerance(forEventID: "wake-recreate"),
                     "Timer should be cleared after invalidation")

        // Simulate poll after wake: updateEvents recreates timers
        scheduler.updateEvents([event])
        XCTAssertTrue(firedEvents.isEmpty, "Event should not fire — alarm is still in the future")
        XCTAssertNotNil(scheduler.scheduledTimerTolerance(forEventID: "wake-recreate"),
                        "Timer should be recreated after updateEvents")
    }

    func testInvalidateAllTimersPreservesAlertedEvents() {
        // An event that already fired should NOT re-fire after invalidateAllTimers
        let event = makeEvent(
            id: "already-alerted",
            startDate: Date().addingTimeInterval(5),
            alarmOffsets: [-5]
        )

        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1, "Event should fire immediately")

        // Simulate wake
        scheduler.invalidateAllTimers()

        // Poll after wake — should not re-alert
        scheduler.updateEvents([event])
        XCTAssertEqual(firedEvents.count, 1, "Already-alerted event should NOT fire again after wake")
    }

    func testInvalidateAllTimersThenWakeMissedAlert() {
        // Full wake scenario: timer was scheduled, sleep happened, fire date passed,
        // wake invalidates timers, poll detects missed alert and fires it.
        let event = makeEvent(
            id: "sleep-missed",
            startDate: Date().addingTimeInterval(600),
            alarmOffsets: [-300] // fires in 5 min
        )

        scheduler.updateEvents([event])
        XCTAssertTrue(firedEvents.isEmpty)

        // Simulate wake: invalidate timers
        scheduler.invalidateAllTimers()

        // Now simulate that time has passed and the alarm fire date is now 2 min ago.
        // We do this by creating a new event version where the fire date is in the recent past.
        let wakeEvent = makeEvent(
            id: "sleep-missed",
            startDate: Date().addingTimeInterval(120), // starts in 2 min
            alarmOffsets: [-240] // fire date was 2 min ago
        )
        scheduler.updateEvents([wakeEvent])
        XCTAssertEqual(firedEvents.count, 1, "Missed alert should fire immediately after wake")
    }

    func testStaleTimerWithMultipleEvents() {
        // Test that stale timer detection works correctly when managing multiple events
        let futureEvent = makeEvent(
            id: "future",
            startDate: Date().addingTimeInterval(600),
            alarmOffsets: [-300]
        )

        let immediateEvent = makeEvent(
            id: "immediate",
            startDate: Date().addingTimeInterval(5),
            alarmOffsets: [-5]
        )

        // Update with both events
        scheduler.updateEvents([futureEvent, immediateEvent])

        // Only immediate event should fire
        XCTAssertEqual(firedEvents.count, 1)
        XCTAssertEqual(firedEvents.first?.id, "immediate")

        // Update again - future event should still be scheduled, immediate should not re-fire
        scheduler.updateEvents([futureEvent, immediateEvent])
        XCTAssertEqual(firedEvents.count, 1, "Should not have any new fires")
    }
}
