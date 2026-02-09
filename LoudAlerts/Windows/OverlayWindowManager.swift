import AppKit
import SwiftUI

class OverlayWindowManager: ObservableObject {
    private var windows: [OverlayWindow] = []
    private var keyMonitor: Any?
    @Published var isShowingAlert = false

    func showAlert(
        for event: CalendarEvent,
        onDismiss: @escaping () -> Void,
        onSnooze: @escaping (Int) -> Void,
        onJoinCall: @escaping (MeetingLink) -> Void
    ) {
        // Dismiss any existing alerts first
        dismissAll()

        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        isShowingAlert = true

        // Activate the app so an LSUIElement app can show windows in front
        NSApp.activate(ignoringOtherApps: true)

        for (index, screen) in screens.enumerated() {
            let isPrimary = index == 0
            let window = OverlayWindow(screen: screen)

            let view = AlertOverlayView(
                event: event,
                isPrimary: isPrimary,
                onDismiss: onDismiss,
                onSnooze: onSnooze,
                onJoinCall: onJoinCall
            )

            let hostingView = NSHostingView(rootView: view)
            hostingView.frame = screen.frame
            window.contentView = hostingView

            // Set window frame to cover the entire screen
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
            case 53: // Escape
                onDismiss()
                return nil
            case 36: // Enter/Return
                onDismiss()
                return nil
            default:
                return keyEvent
            }
        }
    }

    func dismissAll() {
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
