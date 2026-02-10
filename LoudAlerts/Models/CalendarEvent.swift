import EventKit
import Foundation

struct CalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let notes: String?
    let url: URL?
    let calendarID: String
    let calendarName: String
    let calendarColor: CGColor?
    let hasAlarms: Bool // whether the event has any alarms configured
    let alarmOffsets: [TimeInterval] // seconds before start (negative values)
    let meetingLink: MeetingLink?

    var isHappeningNow: Bool {
        let now = Date()
        return startDate <= now && endDate > now
    }

    static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        lhs.id == rhs.id
    }

    static func from(ekEvent: EKEvent) -> CalendarEvent {
        let alarms = ekEvent.alarms
        let offsets = alarms?.map { $0.relativeOffset } ?? []
        let link = MeetingLinkDetector.detect(
            url: ekEvent.url,
            location: ekEvent.location,
            notes: ekEvent.notes
        )
        return CalendarEvent(
            id: ekEvent.eventIdentifier ?? UUID().uuidString,
            title: ekEvent.title ?? "Untitled Event",
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            isAllDay: ekEvent.isAllDay,
            location: ekEvent.location,
            notes: ekEvent.notes,
            url: ekEvent.url,
            calendarID: ekEvent.calendar?.calendarIdentifier ?? "",
            calendarName: ekEvent.calendar?.title ?? "Unknown",
            calendarColor: ekEvent.calendar?.cgColor,
            hasAlarms: alarms != nil && !alarms!.isEmpty,
            alarmOffsets: offsets,
            meetingLink: link
        )
    }

    static func testEvent() -> CalendarEvent {
        let location = "https://teams.microsoft.com/l/meetup-join/test123"
        let notes = "This is a test alert from Loud Alerts.\nZoom: https://zoom.us/j/1234567890"
        return CalendarEvent(
            id: "test-\(UUID().uuidString)",
            title: "Test Meeting — Loud Alerts Demo",
            startDate: Date().addingTimeInterval(60),
            endDate: Date().addingTimeInterval(3660),
            isAllDay: false,
            location: location,
            notes: notes,
            url: nil,
            calendarID: "test",
            calendarName: "Test Calendar",
            calendarColor: CGColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0),
            hasAlarms: true,
            alarmOffsets: [-300],
            meetingLink: MeetingLinkDetector.detect(url: nil, location: location, notes: notes)
        )
    }
}
