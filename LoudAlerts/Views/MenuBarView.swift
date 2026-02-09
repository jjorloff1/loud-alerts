import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var calendarService: CalendarService
    @EnvironmentObject var alertScheduler: AlertScheduler
    @EnvironmentObject var overlayManager: OverlayWindowManager
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Loud Alerts")
                    .font(.headline)
                Spacer()
                if !calendarService.hasAccess {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .help("Calendar access not granted")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if !calendarService.hasAccess {
                noAccessView
            } else if calendarService.events.isEmpty {
                emptyView
            } else {
                eventsList
            }

            Divider()

            // Actions
            VStack(spacing: 0) {
                Button(action: testAlert) {
                    HStack {
                        Image(systemName: "bell.badge")
                        Text("Test Alert")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                Button(action: refreshEvents) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Events")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                Divider()
                    .padding(.vertical, 4)

                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings...")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit Loud Alerts")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .padding(.vertical, 4)
        }
        .frame(width: 300)
    }

    // MARK: - Subviews

    private var noAccessView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("Calendar Access Required")
                .font(.headline)
            Text("Grant access in System Settings > Privacy & Security > Calendars")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No upcoming events")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }

    private var eventsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(upcomingEvents.prefix(10)) { event in
                    EventRow(event: event)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 300)
    }

    private var upcomingEvents: [CalendarEvent] {
        calendarService.events.filter { !$0.isAllDay || !settingsManager.skipAllDayEvents }
    }

    // MARK: - Actions

    private func testAlert() {
        let testEvent = CalendarEvent.testEvent()

        if settingsManager.playSoundOnAlert {
            SoundPlayer.playAlertSound()
        }

        overlayManager.showAlert(
            for: testEvent,
            onDismiss: {
                overlayManager.dismissAll()
            },
            onSnooze: { minutes in
                overlayManager.dismissAll()
                alertScheduler.snooze(event: testEvent, minutes: minutes)
            },
            onJoinCall: { link in
                NSWorkspace.shared.open(link.url)
                overlayManager.dismissAll()
            }
        )
    }

    private func refreshEvents() {
        calendarService.fetchEvents()
    }
}

struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 8) {
            // Calendar color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(calendarColor)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    if event.meetingLink != nil {
                        Image(systemName: "video.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if event.isHappeningNow {
                Text("NOW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(4)
            } else {
                Text(relativeTime)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private var calendarColor: Color {
        if let cgColor = event.calendarColor {
            return Color(cgColor: cgColor)
        }
        return .blue
    }

    private var timeString: String {
        if event.isAllDay { return "All day" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }

    private var relativeTime: String {
        let interval = event.startDate.timeIntervalSinceNow
        if interval < 0 { return "" }
        let minutes = Int(interval / 60)
        if minutes < 1 { return "now" }
        if minutes < 60 { return "in \(minutes)m" }
        let hours = minutes / 60
        let remainingMin = minutes % 60
        if remainingMin == 0 { return "in \(hours)h" }
        return "in \(hours)h \(remainingMin)m"
    }
}
