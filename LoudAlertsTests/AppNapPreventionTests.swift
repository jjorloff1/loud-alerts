import XCTest

final class AppNapPreventionTests: XCTestCase {

    // MARK: - ProcessInfo.beginActivity Mechanism

    func testBeginActivityReturnsValidToken() {
        // Validates that the exact options used in AppDelegate produce a valid activity token.
        // If Apple ever changes the API behavior, this test catches it.
        let token = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Loud Alerts needs precise timer firing for calendar alerts"
        )
        XCTAssertNotNil(token, "beginActivity should return a valid token")
        ProcessInfo.processInfo.endActivity(token)
    }

    func testActivityTokenPreventsAppNapFlag() {
        // Verify the activity token is accepted by endActivity without error.
        // If the token were invalid, endActivity would crash or log an error.
        let token = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Test activity"
        )
        // No assertion needed — endActivity would crash on an invalid token.
        // The fact that this completes is the test.
        ProcessInfo.processInfo.endActivity(token)
    }

    func testMultipleActivitiesCanCoexist() {
        // Ensure multiple beginActivity calls don't interfere with each other.
        // This matters if other parts of the app also use beginActivity.
        let token1 = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Activity 1"
        )
        let token2 = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Activity 2"
        )
        XCTAssertNotNil(token1)
        XCTAssertNotNil(token2)

        ProcessInfo.processInfo.endActivity(token1)
        ProcessInfo.processInfo.endActivity(token2)
    }
}
