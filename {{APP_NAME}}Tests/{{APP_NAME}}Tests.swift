import XCTest
@testable import {{APP_NAME}}

final class {{APP_NAME}}Tests: XCTestCase {

    // MARK: — HomeViewModel

    func testHomeViewModelInitialState() async throws {
        let viewModel = HomeViewModel()
        XCTAssertFalse(viewModel.isLoading)
    }

    // Voeg tests toe naarmate features worden gebouwd
    // Tests draaien ALLEEN in CI — nooit lokaal
}
