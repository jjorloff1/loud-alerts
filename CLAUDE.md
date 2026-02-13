# Loud Alerts — Development Notes

## Build

```bash
xcodebuild -project LoudAlerts.xcodeproj -scheme LoudAlerts -configuration Debug build
```

Or open `LoudAlerts.xcodeproj` in Xcode and press Cmd+R.

## Project Conventions

- **Swift 5** with SwiftUI for views and AppKit for window management
- **No external dependencies** — system frameworks only (EventKit, AppKit, SwiftUI, AVFoundation, ServiceManagement)
- **Deployment target:** macOS 14.0
- **Architecture:** CalendarService -> AlertScheduler -> OverlayWindowManager -> AlertOverlayView
- **Menu bar only:** `LSUIElement = YES` in Info.plist (no Dock icon)
- **Entitlements:** App sandbox disabled, calendar access enabled

## Key Design Decisions

- EventKit over Microsoft Graph API: simpler, no auth, ~150 lines vs ~500+
- `NSWindow.Level.screenSaver + 1` for overlay windows to appear above everything
- `convenience init` on OverlayWindow to work around NSWindow designated initializer requirements
- Primary screen gets full interactive view, secondary screens get simplified overlay
- Keyboard monitor (`NSEvent.addLocalMonitorForEvents`) for Escape/Enter dismiss
- Timer-based polling every 5 minutes + `EKEventStoreChanged` notification for real-time updates

## Testing

- **Always add tests** for new features and bug fixes — no code change ships without corresponding test coverage
- Tests live in `LoudAlertsTests/` and compile source files directly (no `@testable import`)
- Run tests: `xcodebuild test -project LoudAlerts.xcodeproj -scheme LoudAlerts -destination 'platform=macOS'`

## File Layout

All source under `LoudAlerts/` in App/, Models/, Services/, Views/, Windows/, Utilities/ subdirectories. Xcode project at `LoudAlerts.xcodeproj/`.
