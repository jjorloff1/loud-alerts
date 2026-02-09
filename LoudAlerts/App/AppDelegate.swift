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

            if settingsManager.playSoundOnAlert {
                SoundPlayer.playAlertSound()
            }

            self.overlayManager.showAlert(
                for: event,
                onDismiss: { [weak self] in
                    self?.overlayManager.dismissAll()
                },
                onSnooze: { [weak self] minutes in
                    self?.overlayManager.dismissAll()
                    self?.alertScheduler.snooze(event: event, minutes: minutes)
                },
                onJoinCall: { [weak self] link in
                    NSWorkspace.shared.open(link.url)
                    self?.overlayManager.dismissAll()
                }
            )
        }
    }

    func testAlert() {
        let testEvent = CalendarEvent.testEvent()
        showAlert(for: testEvent)
    }
}
