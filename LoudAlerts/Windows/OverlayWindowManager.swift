import AppKit
import SwiftUI

class OverlayWindowManager: ObservableObject {
    private var windows: [OverlayWindow] = []
    private var keyMonitor: Any?
    private var snoozeWork: DispatchWorkItem?
    @Published var isShowingAlert = false

    // Stored so snooze can re-show the same alert
    private var currentEvent: CalendarEvent?
    private var currentOnDismiss: (() -> Void)?
    private var currentOnJoinCall: ((MeetingLink) -> Void)?
    private var currentPlaySound: Bool = false

    func showAlert(
        for event: CalendarEvent,
        playSound: Bool = false,
        onDismiss: @escaping () -> Void,
        onJoinCall: @escaping (MeetingLink) -> Void
    ) {
        // Cancel any pending snooze
        snoozeWork?.cancel()
        snoozeWork = nil

        // Dismiss any existing alerts first
        dismissWindows()

        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        // Store for snooze re-show
        currentEvent = event
        currentOnDismiss = onDismiss
        currentOnJoinCall = onJoinCall
        currentPlaySound = playSound

        if playSound {
            SoundPlayer.playAlertSound()
        }

        isShowingAlert = true

        // Activate the app so an LSUIElement app can show windows in front
        NSApp.activate(ignoringOtherApps: true)

        for (index, screen) in screens.enumerated() {
            let isPrimary = index == 0
            let window = OverlayWindow(screen: screen)

            let view = AlertOverlayView(
                event: event,
                isPrimary: isPrimary,
                onDismiss: { [weak self] in
                    self?.dismissAll()
                    onDismiss()
                },
                onSnooze: { [weak self] delay in
                    self?.snooze(delay: delay)
                },
                onJoinCall: { [weak self] link in
                    NSWorkspace.shared.open(link.url)
                    self?.dismissAll()
                    onJoinCall(link)
                }
            )

            let hostingView = NSHostingView(rootView: view)
            window.contentView = hostingView
            window.setFrame(screen.frame, display: true)

            window.orderFrontRegardless()

            if isPrimary {
                window.makeKey()
            }

            windows.append(window)
        }

        // Set up keyboard monitoring for Escape/Enter
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] keyEvent in
            guard self?.isShowingAlert == true else { return keyEvent }
            switch keyEvent.keyCode {
            case 53, 36: // Escape or Enter/Return
                let dismiss = self?.currentOnDismiss
                self?.dismissAll()
                dismiss?()
                return nil
            default:
                return keyEvent
            }
        }
    }

    func snooze(delay: EventFormatting.SnoozeDelay) {
        guard let event = currentEvent else { return }
        dismissWindows()

        let fireDate = delay.fireDate(eventStart: event.startDate)
        let interval = max(0, fireDate.timeIntervalSinceNow)

        let work = DispatchWorkItem { [weak self] in
            guard let self,
                  let event = self.currentEvent,
                  let onDismiss = self.currentOnDismiss,
                  let onJoinCall = self.currentOnJoinCall else { return }

            self.showAlert(
                for: event,
                playSound: self.currentPlaySound,
                onDismiss: onDismiss,
                onJoinCall: onJoinCall
            )
        }
        snoozeWork = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + interval,
            execute: work
        )
    }

    func dismissAll() {
        snoozeWork?.cancel()
        snoozeWork = nil
        dismissWindows()
        currentEvent = nil
        currentOnDismiss = nil
        currentOnJoinCall = nil
    }

    private func dismissWindows() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
        isShowingAlert = false
    }
}
