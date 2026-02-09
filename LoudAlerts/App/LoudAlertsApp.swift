import SwiftUI

@main
struct LoudAlertsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appDelegate.calendarService)
                .environmentObject(appDelegate.alertScheduler)
                .environmentObject(appDelegate.overlayManager)
                .environmentObject(appDelegate.settingsManager)
        } label: {
            Image(systemName: "bell.badge.fill")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appDelegate.calendarService)
                .environmentObject(appDelegate.settingsManager)
        }
    }
}
