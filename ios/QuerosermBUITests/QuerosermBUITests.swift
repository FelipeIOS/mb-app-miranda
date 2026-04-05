import XCTest

/// UI tests usam `-UITesting` + UITestStubExchangeRepository (dados fixos, sem rede).
final class QuerosermBUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    // MARK: - Helpers

    private func element(matchingIdentifier identifier: String) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@", identifier)
        return app.descendants(matching: .any).matching(predicate).element
    }

    // MARK: - Tests

    func test_launch_showsExchangesNavigation() {
        XCTAssertTrue(app.navigationBars["Exchanges"].waitForExistence(timeout: 20))
    }

    func test_tapFirstCell_opensDetail() {
        XCTAssertTrue(app.navigationBars["Exchanges"].waitForExistence(timeout: 20))

        let alphaCell = element(matchingIdentifier: "exchangeList.cell.1")
        XCTAssertTrue(alphaCell.waitForExistence(timeout: 15))
        alphaCell.tap()

        let title = app.staticTexts["exchangeDetail.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        XCTAssertEqual(title.label, "Alpha Exchange")
    }
}
