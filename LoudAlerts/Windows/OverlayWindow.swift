import AppKit

class OverlayWindow: NSWindow {
    convenience init(screen: NSScreen) {
        self.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true

        // Keep window on its screen
        self.isMovable = false
        self.isMovableByWindowBackground = false
    }

    // Allow the window to become key to receive keyboard events
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
