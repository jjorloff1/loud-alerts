# Loud Alerts

Full-screen calendar alert app for macOS. Shows unmissable blocking overlays on **all monitors** when a meeting is about to start. A free, open-source alternative to [InYourFace](https://inyourface.app).

## Why?

Small macOS notification banners get lost across multiple monitors. Loud Alerts covers every screen with a dark overlay showing the event details, a live countdown, and a one-click "Join Call" button.

## Features

- **Full-screen overlay on all monitors** — borderless windows at `screenSaver + 1` level, visible on all Spaces and over full-screen apps
- **EventKit integration** — reads from the macOS system calendar database (supports any account added in System Settings > Internet Accounts: Outlook/Exchange, Google, iCloud, etc.)
- **Meeting link detection** — auto-detects Teams, Zoom, Google Meet, Webex, and Slack links from event URL, location, and notes fields
- **Join Call button** — opens the meeting link directly and dismisses the alert
- **Snooze** — 1 minute, 5 minutes, or until event start time
- **Keyboard shortcuts** — Escape or Enter to dismiss
- **Menu bar app** — no Dock icon (`LSUIElement`), lives in the menu bar
- **Upcoming events list** — see your next 24 hours of events from the menu bar
- **Settings** — default reminder offset, calendar selection, skip all-day events, sound toggle, launch at login
- **Alert sounds** — plays system sounds when an alert fires

## Architecture

```
EKEventStore (macOS Calendar)
        |
        v
CalendarService          -- fetches events, monitors changes, polls every 5 min
        |
        v
AlertScheduler           -- calculates alert times from event alarms, manages timers
        |
        v (timer fires)
OverlayWindowManager     -- creates full-screen NSWindow on each monitor
        |
        v
AlertOverlayView (SwiftUI) -- event details, countdown, join/snooze/dismiss buttons
```

### Tech Stack

- **Swift 5 + SwiftUI** (views) + **AppKit** (window management)
- **EventKit** for calendar data
- **No external dependencies** — all system frameworks
- Minimum deployment target: macOS 14.0

## Prerequisites

1. **Xcode** (16.0+)
2. **Calendar sync** — Add your Outlook/Exchange/Google account in **System Settings > Internet Accounts** with Calendars toggled ON

## Build & Install

### Quick install

```bash
# Build release
xcodebuild -project LoudAlerts.xcodeproj -scheme LoudAlerts -configuration Release build

# Copy to Applications
cp -R ~/Library/Developer/Xcode/DerivedData/LoudAlerts-*/Build/Products/Release/LoudAlerts.app /Applications/
```

Since the app isn't signed with a Developer ID, macOS may block it on first launch. Right-click the app in Finder, choose **Open**, and confirm in the dialog.

### Launch at login

Open the app, click the menu bar bell icon, go to **Settings**, and toggle **Launch at login**. This uses `SMAppService` to register with macOS.

Alternatively: **System Settings > General > Login Items** and add LoudAlerts.

### Development

```bash
# Open in Xcode
open LoudAlerts.xcodeproj

# Or build debug from command line
xcodebuild -project LoudAlerts.xcodeproj -scheme LoudAlerts -configuration Debug build
```

Press **Cmd+R** in Xcode to build and run.

## Testing

### Unit Tests

The project includes unit tests covering core logic. Tests run in a standalone `xctest` process (not hosted inside the app), so they do not trigger calendar access prompts.

```bash
# Run all unit tests
xcodebuild test -project LoudAlerts.xcodeproj -scheme LoudAlerts -destination 'platform=macOS'
```

Test files are in `LoudAlertsTests/` and cover:

| File | What it tests |
|------|---------------|
| `MeetingLinkDetectorTests` | Teams, Zoom, Google Meet, Webex, Slack URL detection; priority ordering; HTML stripping; edge cases |
| `AlertSchedulerTests` | Timer scheduling, immediate fire, past event skipping, cancel/prune, default reminder logic |
| `CalendarEventTests` | `isHappeningNow` logic, equality, test event factory |
| `SettingsManagerTests` | Default values, UserDefaults persistence, callback triggers |
| `EventFormattingTests` | Alarm string formatting, relative time display |
| `MeetingLinkModelTests` | Service icon names, display names, enum completeness |

### Manual Testing

1. **Menu bar icon** — Verify the bell icon appears in the menu bar, no Dock icon
2. **Menu bar dropdown** — Click the icon, verify upcoming calendar events are listed
3. **Test Alert** — Click "Test Alert" in the dropdown to verify the full-screen overlay covers all monitors
4. **Real event** — Create a calendar event with a 1-minute reminder, verify the alert fires automatically
5. **Meeting link** — Add a Teams/Zoom URL to an event's location, verify "Join Call" button appears
6. **Snooze** — Click Snooze, select a duration, verify the alert reappears
7. **Dismiss** — Click Dismiss or press Escape/Enter

## How It Works

### Calendar Access
On first launch, the app requests full calendar access via EventKit. Grant access in the system prompt. If you need to change this later: **System Settings > Privacy & Security > Calendars**.

### Connecting to Outlook / Exchange

Loud Alerts reads from the macOS system calendar database via EventKit. It doesn't connect to Outlook or Exchange directly — instead, you add your account to macOS and it syncs automatically.

1. Open **System Settings > Internet Accounts**
2. Click **Add Account** and choose **Microsoft Exchange** (or **Google**, **iCloud**, etc.)
3. Sign in with your work email and credentials
4. On the "what to sync" screen, make sure **Calendars** is toggled **ON** (you can disable Mail, Contacts, etc. if you only want calendar sync)
5. Open the macOS **Calendar** app and verify your events appear

Once your calendars are syncing to macOS, Loud Alerts will see them automatically — no API keys or OAuth setup required. You can select which calendars to monitor in **Settings > Calendars**.

### Alert Timing
The app uses each event's alarm/reminder settings. If an event has no alarms (alert set to "None" in the calendar app), no alert is shown.

### Multi-Monitor Overlay
One borderless `NSWindow` per screen at `NSWindow.Level.screenSaver + 1`. The primary screen gets the full interactive alert (event details, buttons). Secondary screens get a simplified overlay with just the event title and time.

### Meeting Link Detection
Regex patterns (based on [MeetingBar](https://github.com/leits/MeetingBar)) search the event's URL, location, and notes fields for:
- Microsoft Teams (`teams.microsoft.com`, `teams.live.com`)
- Zoom (`*.zoom.us`)
- Google Meet (`meet.google.com`)
- Webex (`*.webex.com`)
- Slack Huddles (`app.slack.com/huddle`)

## Project Structure

```
LoudAlerts/
  App/
    LoudAlertsApp.swift              -- @main, MenuBarExtra scene
    AppDelegate.swift                -- AppKit lifecycle, alert coordination
  Models/
    CalendarEvent.swift              -- Domain model wrapping EKEvent
    MeetingLink.swift                -- Parsed video conference link
  Services/
    CalendarService.swift            -- EventKit integration, polling
    MeetingLinkDetector.swift        -- Video URL regex parser
    AlertScheduler.swift             -- Timer management
    SoundPlayer.swift                -- Alert sound playback
    SettingsManager.swift            -- UserDefaults persistence
  Views/
    AlertOverlayView.swift           -- Full-screen alert SwiftUI view
    MenuBarView.swift                -- Menu bar dropdown
    SettingsView.swift               -- Preferences window
  Windows/
    OverlayWindowManager.swift       -- Multi-monitor window orchestration, snooze
    OverlayWindow.swift              -- NSWindow subclass
  Utilities/
    EventFormatting.swift            -- Alarm and relative time formatting
  Resources/
    Assets.xcassets
  Info.plist
  LoudAlerts.entitlements
LoudAlertsTests/
  MeetingLinkDetectorTests.swift
  AlertSchedulerTests.swift
  CalendarEventTests.swift
  SettingsManagerTests.swift
  EventFormattingTests.swift
  MeetingLinkModelTests.swift
```

## Code Signing & Calendar Permissions

macOS ties calendar permission grants to the app's **code signing identity**. Without consistent signing, each rebuild looks like a new app and macOS re-prompts for calendar access.

### Setting up signing (do this once)

1. Open **Xcode > Settings > Accounts**
2. Add your Apple ID (a free account works)
3. Xcode creates a "Personal Team" signing certificate automatically
4. Open `LoudAlerts.xcodeproj`, select the **LoudAlerts** target
5. Go to **Signing & Capabilities** and select your Personal Team from the **Team** dropdown
6. Build and run — macOS will ask for calendar access one final time, then remember it across rebuilds

If you're building from the command line, you can also add `DEVELOPMENT_TEAM=YOUR_TEAM_ID` to the `xcodebuild` command:

```bash
xcodebuild -project LoudAlerts.xcodeproj -scheme LoudAlerts -configuration Debug \
  DEVELOPMENT_TEAM=XXXXXXXXXX build
```

Find your Team ID with: `security find-identity -v -p codesigning` or in Xcode under the Signing & Capabilities tab.

### Why this happens

Without a `DEVELOPMENT_TEAM`, the project uses ad-hoc signing (`CODE_SIGN_STYLE = Automatic` with no team). Each build gets a different signing identity, so macOS treats it as an unrelated app and the TCC (Transparency, Consent, and Control) database has no matching record — prompting again.

## Troubleshooting

### Log File

Loud Alerts writes a persistent log file to:

```
~/Library/Logs/LoudAlerts/LoudAlerts.log
```

Open it in Terminal:

```bash
open ~/Library/Logs/LoudAlerts/LoudAlerts.log
```

Or tail it live:

```bash
tail -f ~/Library/Logs/LoudAlerts/LoudAlerts.log
```

The log records event fetches, alert scheduling decisions, timer fires, missed alerts, and suppressed alerts. The file rotates at 5 MB (old log kept as `LoudAlerts.log.old`).

Logs are also sent to the unified system log (viewable in Console.app, subsystem `com.loudalerts`).

## Future Enhancements

- Overlapping alert handling (queue/stack)
- Screen configuration change handling
- Microsoft Graph API as alternative data source
- Custom alert sounds
- Per-calendar reminder offset overrides
- Watchdog timer for imminent events — 15-second fast-tick timer when alerts are within 6 minutes, for faster stale-timer recovery
- Wall-clock-aligned polling — anchor polls to :02:30/:07:30 offsets to avoid contention with typical meeting start times
