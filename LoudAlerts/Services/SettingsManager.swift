import Foundation
import ServiceManagement

class SettingsManager: ObservableObject {
    private let defaults: UserDefaults

    @Published var alertsEnabled: Bool {
        didSet { defaults.set(alertsEnabled, forKey: "alertsEnabled") }
    }

    @Published var defaultReminderMinutes: Int {
        didSet {
            defaults.set(defaultReminderMinutes, forKey: "defaultReminderMinutes")
            onCalendarsChanged?()
        }
    }

    @Published var skipAllDayEvents: Bool {
        didSet { defaults.set(skipAllDayEvents, forKey: "skipAllDayEvents") }
    }

    @Published var playSoundOnAlert: Bool {
        didSet { defaults.set(playSoundOnAlert, forKey: "playSoundOnAlert") }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    var onCalendarsChanged: (() -> Void)?

    @Published var disabledCalendarIDs: Set<String> {
        didSet {
            defaults.set(Array(disabledCalendarIDs), forKey: "disabledCalendarIDs")
            onCalendarsChanged?()
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Register defaults
        defaults.register(defaults: [
            "alertsEnabled": true,
            "defaultReminderMinutes": -1,
            "skipAllDayEvents": true,
            "playSoundOnAlert": true,
            "launchAtLogin": false,
            "disabledCalendarIDs": [String](),
        ])

        self.alertsEnabled = defaults.bool(forKey: "alertsEnabled")
        self.defaultReminderMinutes = defaults.integer(forKey: "defaultReminderMinutes")
        self.skipAllDayEvents = defaults.bool(forKey: "skipAllDayEvents")
        self.playSoundOnAlert = defaults.bool(forKey: "playSoundOnAlert")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.disabledCalendarIDs = Set(defaults.stringArray(forKey: "disabledCalendarIDs") ?? [])
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
