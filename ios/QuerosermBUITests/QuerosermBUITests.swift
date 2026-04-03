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

    /// Prefer over `otherElements[id]` — SwiftUI expõe o mesmo identificador em vários tipos de elemento.
    private func element(matchingIdentifier identifier: String) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@", identifier)
        return app.descendants(matching: .any).matching(predicate).element
    }

    private func dismissKeyboardIfPresent() {
        let search = app.keyboards.buttons["Search"]
        if search.exists {
            search.tap()
            return
        }
        let returnKey = app.keyboards.buttons["Return"]
        if returnKey.exists {
            returnKey.tap()
        }
    }

    func test_launch_showsExchangesNavigation() {
        let nav = app.navigationBars["Exchanges"]
        XCTAssertTrue(nav.waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["exchangeList.button.search"].waitForExistence(timeout: 10))
    }

    func test_openSearch_andCancel() {
        XCTAssertTrue(app.navigationBars["Exchanges"].waitForExistence(timeout: 20))

        let searchBtn = app.buttons["exchangeList.button.search"]
        XCTAssertTrue(searchBtn.waitForExistence(timeout: 5))
        searchBtn.tap()

        let field = app.textFields["exchangeSearch.field.query"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))

        let cancel = app.buttons["exchangeSearch.button.cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 3))
        cancel.tap()

        XCTAssertTrue(app.navigationBars["Exchanges"].waitForExistence(timeout: 10))
    }

    func test_search_filtersList() {
        XCTAssertTrue(app.navigationBars["Exchanges"].waitForExistence(timeout: 20))
        app.buttons["exchangeList.button.search"].tap()

        let field = app.textFields["exchangeSearch.field.query"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Beta")
        dismissKeyboardIfPresent()

        let betaCell = element(matchingIdentifier: "exchangeList.cell.2")
        XCTAssertTrue(betaCell.waitForExistence(timeout: 10))
    }

    func test_search_noResults_showsEmptyCopy() {
        XCTAssertTrue(app.navigationBars["Exchanges"].waitForExistence(timeout: 20))
        app.buttons["exchangeList.button.search"].tap()

        let field = app.textFields["exchangeSearch.field.query"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("zzznotfound")
        dismissKeyboardIfPresent()

        let emptyTitle = app.staticTexts["exchangeSearch.empty.title"]
        XCTAssertTrue(emptyTitle.waitForExistence(timeout: 10))
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
