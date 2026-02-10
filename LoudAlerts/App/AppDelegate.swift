import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    let calendarService = CalendarService()
    let alertScheduler = AlertScheduler()
    let overlayManager = OverlayWindowManager()
    let settingsManager = SettingsManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure alert scheduler callbacks
        alertScheduler.onAlertFired = { [weak self] event in
            self?.showAlert(for: event)
        }

        // Start calendar service and connect to scheduler
        calendarService.onEventsUpdated = { [weak self] events in
            self?.alertScheduler.updateEvents(events)
        }

        // Wire up disabled calendar filtering
        calendarService.disabledCalendarIDs = { [weak self] in
            self?.settingsManager.disabledCalendarIDs ?? []
        }

        // Wire up default reminder setting
        alertScheduler.defaultReminderMinutes = { [weak self] in
            self?.settingsManager.defaultReminderMinutes ?? -1
        }

        // Re-fetch events when calendar selection changes in settings
        settingsManager.onCalendarsChanged = { [weak self] in
            self?.calendarService.fetchEvents()
        }

        calendarService.requestAccessAndStart()
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlayManager.dismissAll()
        alertScheduler.cancelAll()
    }

    private func showAlert(for event: CalendarEvent) {
        guard settingsManager.alertsEnabled else { return }

        if settingsManager.skipAllDayEvents && event.isAllDay {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.overlayManager.showAlert(
                for: event,
                playSound: settingsManager.playSoundOnAlert,
                onDismiss: {},
                onJoinCall: { _ in }
            )
        }
    }

    func testAlert() {
        let testEvent = CalendarEvent.testEvent()
        showAlert(for: testEvent)
    }
}
