import AppKit
import SwiftUI

private let logger = AppLogger(category: "AppDelegate")

class AppDelegate: NSObject, NSApplicationDelegate {
    let calendarService = CalendarService()
    let alertScheduler = AlertScheduler()
    let overlayManager = OverlayWindowManager()
    let settingsManager = SettingsManager()
    private var activityToken: NSObjectProtocol?
    private var wakeObserver: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent App Nap — this app has time-sensitive timer work
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Loud Alerts needs precise timer firing for calendar alerts"
        )
        logger.info("App Nap prevention active.")

        // Immediately poll on wake from sleep — timers don't fire during sleep
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            logger.info("System wake detected — polling immediately for missed alerts.")
            self?.calendarService.fetchEvents()
        }

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
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        overlayManager.dismissAll()
        alertScheduler.cancelAll()
    }

    private func showAlert(for event: CalendarEvent) {
        guard settingsManager.alertsEnabled else {
            logger.warning("Alert suppressed for '\(event.title)' — alerts disabled in settings.")
            return
        }

        if settingsManager.skipAllDayEvents && event.isAllDay {
            logger.info("Alert suppressed for '\(event.title)' — all-day event skipped.")
            return
        }

        logger.info("Showing overlay alert for '\(event.title)'.")
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

}
