import Foundation

class AlertScheduler: ObservableObject {
    private var timers: [String: Timer] = [:] // eventID -> timer
    private var alertedEvents: Set<String> = [] // events already alerted

    var onAlertFired: ((CalendarEvent) -> Void)?

    /// Default reminder offset if event has no alarms (in seconds before start, negative)
    @Published var defaultReminderOffset: TimeInterval = -300 // 5 minutes

    func updateEvents(_ events: [CalendarEvent]) {
        // Cancel timers for events that no longer exist
        let currentIds = Set(events.map { $0.id })
        for (id, timer) in timers where !currentIds.contains(id) {
            timer.invalidate()
            timers.removeValue(forKey: id)
        }

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
        if alertedEvents.contains(event.id) { return }

        // Skip past events (started more than 2 minutes ago)
        if event.startDate.timeIntervalSinceNow < -120 { return }

        // Skip events with no alarms — the user set alert to "None"
        if !event.hasAlarms { return }

        // Use the event's alarm offsets
        let offsets = event.alarmOffsets
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
        alertedEvents.insert(event.id)
        timers.removeValue(forKey: event.id)
        onAlertFired?(event)
    }
}
