import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var calendarService: CalendarService
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            calendarSettings
                .tabItem {
                    Label("Calendars", systemImage: "calendar")
                }
        }
        .frame(width: 450, height: 350)
    }

    private var generalSettings: some View {
        Form {
            Section("Alerts") {
                Toggle("Enable alerts", isOn: $settingsManager.alertsEnabled)

                Picker("Default reminder", selection: $settingsManager.defaultReminderMinutes) {
                    Text("At start time").tag(0)
                    Text("1 minute before").tag(1)
                    Text("2 minutes before").tag(2)
                    Text("5 minutes before").tag(5)
                    Text("10 minutes before").tag(10)
                    Text("15 minutes before").tag(15)
                }
                .pickerStyle(.menu)

                Toggle("Skip all-day events", isOn: $settingsManager.skipAllDayEvents)
                Toggle("Play sound with alert", isOn: $settingsManager.playSoundOnAlert)
            }

            Section("System") {
                Toggle("Launch at login", isOn: $settingsManager.launchAtLogin)
            }

            Section("About") {
                HStack {
                    Text("Loud Alerts")
                        .font(.headline)
                    Spacer()
                    Text("v1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var calendarSettings: some View {
        Form {
            if calendarService.calendars.isEmpty {
                Text("No calendars found. Make sure calendar access is granted.")
                    .foregroundColor(.secondary)
            } else {
                Section("Select calendars to monitor") {
                    ForEach(calendarService.calendars, id: \.calendarIdentifier) { calendar in
                        Toggle(isOn: Binding(
                            get: { !settingsManager.disabledCalendarIDs.contains(calendar.calendarIdentifier) },
                            set: { enabled in
                                if enabled {
                                    settingsManager.disabledCalendarIDs.remove(calendar.calendarIdentifier)
                                } else {
                                    settingsManager.disabledCalendarIDs.insert(calendar.calendarIdentifier)
                                }
                            }
                        )) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(cgColor: calendar.cgColor ?? CGColor(red: 0, green: 0, blue: 1, alpha: 1)))
                                    .frame(width: 10, height: 10)
                                Text(calendar.title)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
