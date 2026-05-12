import XCTest

final class {{APP_NAME}}UITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAppLaunches() throws {
        XCTAssertTrue(app.state == .runningForeground)
    }

    // Voeg UI tests toe naarmate features worden gebouwd
    // Tests draaien ALLEEN in CI — nooit lokaal
}
