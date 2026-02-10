import SwiftUI

struct AlertOverlayView: View {
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    let event: CalendarEvent
    let isPrimary: Bool
    let onDismiss: () -> Void
    let onSnooze: (Int) -> Void
    let onJoinCall: (MeetingLink) -> Void

    @State private var timeUntilStart: TimeInterval = 0
    @State private var showSnoozeOptions = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Dark overlay background
            Color.black.opacity(0.85)

            if isPrimary {
                primaryContent
            } else {
                secondaryContent
            }
        }
        .ignoresSafeArea()
        .onAppear {
            timeUntilStart = event.startDate.timeIntervalSinceNow
        }
        .onReceive(timer) { _ in
            timeUntilStart = event.startDate.timeIntervalSinceNow
        }
    }

    // MARK: - Primary Screen (full interactive)

    private var primaryContent: some View {
        VStack(spacing: 0) {
            Spacer()

            // Main card
            VStack(spacing: 24) {
                // Calendar indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(calendarSwiftUIColor)
                        .frame(width: 10, height: 10)
                    Text(event.calendarName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Event title
                Text(event.title)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                // Time and countdown
                VStack(spacing: 8) {
                    Text(timeRangeString)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    countdownView
                }

                // Location
                if let location = event.location, !location.isEmpty,
                   event.meetingLink == nil || !location.contains("http") {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                        Text(location)
                            .font(.system(size: 16))
                            .lineLimit(2)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }

                // Meeting link indicator
                if let link = event.meetingLink {
                    HStack(spacing: 6) {
                        Image(systemName: link.service.iconName)
                            .font(.system(size: 14))
                        Text(link.service.rawValue)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }

                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 40)

                // Action buttons
                actionButtons
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
            .frame(maxWidth: 600)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )

            Spacer()

            // Bottom hint
            Text("Press Escape or Enter to dismiss")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.3))
                .padding(.bottom, 40)
        }
    }

    // MARK: - Secondary Screen (simplified)

    private var secondaryContent: some View {
        VStack(spacing: 20) {
            // Calendar indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(calendarSwiftUIColor)
                    .frame(width: 10, height: 10)
                Text(event.calendarName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Text(event.title)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(timeRangeString)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            countdownView
        }
        .padding(40)
    }

    // MARK: - Subviews

    private var countdownView: some View {
        Group {
            if timeUntilStart > 0 {
                Text("Starts in \(countdownString)")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
            } else if timeUntilStart > -60 {
                Text("STARTING NOW")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.red)
            } else {
                Text("Started \(agoString)")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Join Call button (if meeting link detected)
            if let link = event.meetingLink {
                Button(action: { onJoinCall(link) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "video.fill")
                        Text(link.displayName)
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                // Snooze button
                if showSnoozeOptions {
                    HStack(spacing: 8) {
                        ForEach([1, 5], id: \.self) { minutes in
                            Button(action: { onSnooze(minutes) }) {
                                Text("\(minutes)m")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 44)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }

                        if minutesUntilStart > 1 {
                            Button(action: { onSnooze(minutesUntilStart) }) {
                                Text("Start")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 44)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    Button(action: { withAnimation { showSnoozeOptions = true } }) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Snooze")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }

                // Dismiss button
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private var minutesUntilStart: Int {
        max(0, Int(ceil(event.startDate.timeIntervalSinceNow / 60)))
    }

    private var calendarSwiftUIColor: Color {
        if let cgColor = event.calendarColor {
            return Color(cgColor: cgColor)
        }
        return .blue
    }

    private var timeRangeString: String {
        "\(Self.timeFormatter.string(from: event.startDate)) – \(Self.timeFormatter.string(from: event.endDate))"
    }

    private var countdownString: String {
        let total = Int(max(0, timeUntilStart))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var agoString: String {
        let total = Int(abs(timeUntilStart))
        let minutes = total / 60
        if minutes < 1 { return "just now" }
        if minutes == 1 { return "1 minute ago" }
        return "\(minutes) minutes ago"
    }
}
