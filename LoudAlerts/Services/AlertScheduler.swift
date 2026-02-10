import Foundation

class AlertScheduler: ObservableObject {
    private var timers: [String: Timer] = [:] // eventID -> timer
    private var alertedEvents: [String: Date] = [:] // eventID -> startDate, for pruning

    var onAlertFired: ((CalendarEvent) -> Void)?

    /// Returns default reminder minutes from settings (-1 = None)
    var defaultReminderMinutes: () -> Int = { -1 }

    func updateEvents(_ events: [CalendarEvent]) {
        // Cancel timers for events that no longer exist
        let currentIds = Set(events.map { $0.id })
        for (id, timer) in timers where !currentIds.contains(id) {
            timer.invalidate()
            timers.removeValue(forKey: id)
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

    func cancelAll() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
        alertedEvents.removeAll()
    }

    private func scheduleIfNeeded(_ event: CalendarEvent) {
        // Don't reschedule if already has an active timer
        if timers[event.id] != nil { return }

        // Don't re-alert events we've already shown
        if alertedEvents[event.id] != nil { return }

        // Skip past events (started more than 2 minutes ago)
        if event.startDate.timeIntervalSinceNow < -120 { return }

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

        // Find the next fire date that's in the future (or within the last 30 seconds)
        let now = Date()
        let validFireDates = fireDates.filter { $0.timeIntervalSince(now) > -30 }

        guard let nextFireDate = validFireDates.min() else {
            // All fire dates are past — fire immediately if event hasn't started yet
            if event.startDate > now {
                fireAlert(for: event)
            }
            return
        }

        if nextFireDate <= now {
            // Fire immediately
            fireAlert(for: event)
        } else {
            // Schedule timer
            let timer = Timer(fire: nextFireDate, interval: 0, repeats: false) { [weak self] _ in
                self?.fireAlert(for: event)
            }
            RunLoop.main.add(timer, forMode: .common)
            timers[event.id] = timer
        }
    }

    private func fireAlert(for event: CalendarEvent) {
        alertedEvents[event.id] = event.startDate
        timers.removeValue(forKey: event.id)
        onAlertFired?(event)
    }
}
