import XCTest

final class SettingsManagerTests: XCTestCase {

    private var suiteName: String!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "com.loudalerts.tests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        // removePersistentDomain must be called on a different instance than the suite itself
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Defaults

    func testFreshInitHasCorrectDefaults() {
        let manager = SettingsManager(defaults: testDefaults)
        XCTAssertTrue(manager.alertsEnabled)
        XCTAssertEqual(manager.defaultReminderMinutes, -1)
        XCTAssertTrue(manager.skipAllDayEvents)
        XCTAssertTrue(manager.playSoundOnAlert)
        XCTAssertFalse(manager.launchAtLogin)
        XCTAssertTrue(manager.disabledCalendarIDs.isEmpty)
    }

    // MARK: - Persistence

    func testAlertsEnabledPersists() {
        let manager = SettingsManager(defaults: testDefaults)
        manager.alertsEnabled = false
        XCTAssertFalse(testDefaults.bool(forKey: "alertsEnabled"))
    }

    func testDefaultReminderMinutesPersists() {
        let manager = SettingsManager(defaults: testDefaults)
        manager.defaultReminderMinutes = 10
        XCTAssertEqual(testDefaults.integer(forKey: "defaultReminderMinutes"), 10)
    }

    func testSkipAllDayEventsPersists() {
        let manager = SettingsManager(defaults: testDefaults)
        manager.skipAllDayEvents = false
        XCTAssertFalse(testDefaults.bool(forKey: "skipAllDayEvents"))
    }

    func testPlaySoundOnAlertPersists() {
        let manager = SettingsManager(defaults: testDefaults)
        manager.playSoundOnAlert = false
        XCTAssertFalse(testDefaults.bool(forKey: "playSoundOnAlert"))
    }

    // Note: launchAtLogin persistence is not tested because its didSet calls
    // SMAppService.mainApp.register/unregister, which has side effects in a
    // test environment. The UserDefaults write itself follows the same pattern
    // as the other properties tested above.

    // MARK: - DisabledCalendarIDs

    func testDisabledCalendarIDsRoundTrips() {
        let manager = SettingsManager(defaults: testDefaults)
        manager.disabledCalendarIDs = Set(["cal-1", "cal-2"])

        let stored = Set(testDefaults.stringArray(forKey: "disabledCalendarIDs") ?? [])
        XCTAssertEqual(stored, Set(["cal-1", "cal-2"]))

        // Re-init and verify
        let manager2 = SettingsManager(defaults: testDefaults)
        XCTAssertEqual(manager2.disabledCalendarIDs, Set(["cal-1", "cal-2"]))
    }

    // MARK: - Callbacks

    func testOnCalendarsChangedFiresOnReminderChange() {
        let manager = SettingsManager(defaults: testDefaults)
        var callbackFired = false
        manager.onCalendarsChanged = { callbackFired = true }
        manager.defaultReminderMinutes = 5
        XCTAssertTrue(callbackFired)
    }

    func testOnCalendarsChangedFiresOnCalendarDisable() {
        let manager = SettingsManager(defaults: testDefaults)
        var callbackFired = false
        manager.onCalendarsChanged = { callbackFired = true }
        manager.disabledCalendarIDs = Set(["cal-1"])
        XCTAssertTrue(callbackFired)
    }

    func testValuesReadFromExistingDefaults() {
        testDefaults.set(false, forKey: "alertsEnabled")
        testDefaults.set(15, forKey: "defaultReminderMinutes")
        testDefaults.set(["cal-x"], forKey: "disabledCalendarIDs")

        let manager = SettingsManager(defaults: testDefaults)
        XCTAssertFalse(manager.alertsEnabled)
        XCTAssertEqual(manager.defaultReminderMinutes, 15)
        XCTAssertEqual(manager.disabledCalendarIDs, Set(["cal-x"]))
    }
}
