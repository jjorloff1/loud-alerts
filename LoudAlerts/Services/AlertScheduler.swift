import Foundation

private let logger = AppLogger(category: "AlertScheduler")

class AlertScheduler: ObservableObject {
    private var timers: [String: Timer] = [:] // eventID -> timer
    private var timerFireDates: [String: Date] = [:] // eventID -> fire date, for staleness detection
    private var alertedEvents: [String: Date] = [:] // eventID -> startDate, for pruning

    var onAlertFired: ((CalendarEvent) -> Void)?

    /// Returns default reminder minutes from settings (-1 = None)
    var defaultReminderMinutes: () -> Int = { -1 }

    /// Grace period for catching missed fire dates — matches poll interval plus buffer
    private let missedAlertGracePeriod: TimeInterval = 360 // 6 minutes (poll=5min + 1min buffer)

    func updateEvents(_ events: [CalendarEvent]) {
        // Cancel timers for events that no longer exist
        let currentIds = Set(events.map { $0.id })
        for (id, timer) in timers where !currentIds.contains(id) {
            logger.debug("Cancelling timer for removed event: \(id)")
            timer.invalidate()
            timers.removeValue(forKey: id)
            timerFireDates.removeValue(forKey: id)
        }

        // Prune alerted events whose start date is more than 2 hours ago
        let pruneThreshold = Date().addingTimeInterval(-7200)
        alertedEvents = alertedEvents.filter { $0.value > pruneThreshold }

        // Schedule new timers
        for event in events {
            scheduleIfNeeded(event)
        }
    }

    // Snooze is now handled by OverlayWindowManager directly

    /// Invalidate all timers so they get recreated on next poll.
    /// Preserves alertedEvents so we don't re-alert events already shown.
    /// Call this on system wake — sleep silently breaks RunLoop timer scheduling.
    func invalidateAllTimers() {
        let count = timers.count
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
        timerFireDates.removeAll()
        if count > 0 {
            logger.info("Invalidated \(count) timers for recreation after wake.")
        }
    }

    func cancelAll() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
        timerFireDates.removeAll()
        alertedEvents.removeAll()
    }

    private func scheduleIfNeeded(_ event: CalendarEvent) {
        // Don't re-alert events we've already shown
        if alertedEvents[event.id] != nil { return }

        // Check if existing timer is stale (fire date passed but event wasn't alerted)
        let now = Date()
        if let existingTimer = timers[event.id],
           let fireDate = timerFireDates[event.id] {
            if fireDate > now {
                // Timer is still valid and hasn't fired yet
                return
            } else {
                // Timer fire date has passed but event wasn't alerted - reschedule
                logger.warning("Stale timer detected for '\(event.title)' (fire date \(fireDate) passed). Rescheduling.")
                existingTimer.invalidate()
                timers.removeValue(forKey: event.id)
                timerFireDates.removeValue(forKey: event.id)
            }
        }

        // Skip past events (started more than grace period ago)
        let timeSinceStart = event.startDate.timeIntervalSince(now)
        if timeSinceStart < -missedAlertGracePeriod {
            logger.debug("Skipping '\(event.title)' — started \(Int(-timeSinceStart))s ago (beyond grace period).")
            return
        }

        // Determine alarm offsets
        let offsets: [TimeInterval]
        if event.hasAlarms {
            offsets = event.alarmOffsets
        } else {
            // Event has no alarms — check default reminder setting
            let defaultMinutes = defaultReminderMinutes()
            if defaultMinutes < 0 { return } // "None" — don't alert
            offsets = [TimeInterval(-defaultMinutes * 60)]
        }
        let fireDates = offsets.map { event.startDate.addingTimeInterval($0) }

        // Find the next fire date that's in the future or was recently missed (within grace period)
        let validFireDates = fireDates.filter { $0.timeIntervalSince(now) > -missedAlertGracePeriod }

        guard let nextFireDate = validFireDates.min() else {
            // All fire dates are beyond the grace period — truly missed
            logger.warning("All fire dates for '\(event.title)' are beyond grace period. Alert missed.")
            return
        }

        if nextFireDate <= now {
            // Fire date is in the past but within grace period — fire immediately
            let missedBy = Int(now.timeIntervalSince(nextFireDate))
            logger.info("Firing late alert for '\(event.title)' (missed by \(missedBy)s).")
            fireAlert(for: event)
        } else {
            // Schedule timer for future fire date
            let secondsUntilFire = nextFireDate.timeIntervalSince(now)
            logger.info("Scheduling alert for '\(event.title)' at \(nextFireDate) (\(Int(secondsUntilFire))s from now).")
            let timer = Timer(fire: nextFireDate, interval: 0, repeats: false) { [weak self] _ in
                logger.info("Timer fired for '\(event.title)'.")
                self?.fireAlert(for: event)
            }
            timer.tolerance = 0
            RunLoop.main.add(timer, forMode: .common)
            timers[event.id] = timer
            timerFireDates[event.id] = nextFireDate
        }
    }

    /// Test-only: returns the tolerance of the scheduled timer for the given event ID
    func scheduledTimerTolerance(forEventID id: String) -> TimeInterval? {
        timers[id]?.tolerance
    }

    private func fireAlert(for event: CalendarEvent) {
        logger.info("Alert firing for '\(event.title)' (start: \(event.startDate)).")
        alertedEvents[event.id] = event.startDate
        timers.removeValue(forKey: event.id)
        timerFireDates.removeValue(forKey: event.id)
        onAlertFired?(event)
    }
}
