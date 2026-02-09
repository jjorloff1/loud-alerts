import EventKit
import Foundation
import Combine

class CalendarService: ObservableObject {
    private let store = EKEventStore()
    private var pollTimer: Timer?
    private var notificationObserver: Any?

    @Published var events: [CalendarEvent] = []
    @Published var hasAccess = false
    @Published var calendars: [EKCalendar] = []

    var onEventsUpdated: (([CalendarEvent]) -> Void)?
    var disabledCalendarIDs: () -> Set<String> = { [] }

    private let pollInterval: TimeInterval = 300 // 5 minutes

    func requestAccessAndStart() {
        store.requestFullAccessToEvents { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasAccess = granted
                if granted {
                    self?.loadCalendars()
                    self?.fetchEvents()
                    self?.startPolling()
                    self?.observeCalendarChanges()
                } else if let error {
                    print("Calendar access denied: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadCalendars() {
        calendars = store.calendars(for: .event)
    }

    func fetchEvents() {
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: 24, to: now)!

        let predicate = store.predicateForEvents(
            withStart: now.addingTimeInterval(-3600), // include events that started up to 1hr ago
            end: endDate,
            calendars: nil // all calendars
        )

        let disabled = disabledCalendarIDs()
        let ekEvents = store.events(matching: predicate)
        let calendarEvents = ekEvents
            .map { CalendarEvent.from(ekEvent: $0) }
            .filter { !disabled.contains($0.calendarID) }
            .sorted { $0.startDate < $1.startDate }

        DispatchQueue.main.async { [weak self] in
            self?.events = calendarEvents
            self?.onEventsUpdated?(calendarEvents)
        }
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.fetchEvents()
        }
    }

    private func observeCalendarChanges() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.loadCalendars()
            self?.fetchEvents()
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    deinit {
        stopPolling()
    }
}
