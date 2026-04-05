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

    /// Busca por identifier ignorando o tipo de elemento (UIKit expõe search como searchField, não textField).
    private func element(matchingIdentifier identifier: String) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@", identifier)
        return app.descendants(matching: .any).matching(predicate).element
    }

    /// Ativa o UISearchController: toca na search bar embutida na navigation bar.
    private func activateSearch() {
        let searchField = element(matchingIdentifier: "exchangeSearch.field.query")
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
    }

    /// Cancela o UISearchController via botão nativo ("Cancelar").
    private func cancelSearch() {
        // UISearchController exibe "Cancelar" no locale pt-BR
        let cancelBtn = app.buttons["Cancelar"]
        if cancelBtn.waitForExistence(timeout: 3) {
            cancelBtn.tap()
        }
    }

    // MARK: - Tests

    func test_launch_showsExchangesNavigation() {
        let nav = app.navigationBars["Exchanges"]
        XCTAssertTrue(nav.waitForExistence(timeout: 20))

        // Search bar embutida no UISearchController deve estar visível
        let searchField = element(matchingIdentifier: "exchangeSearch.field.query")
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
    }

    func test_openSearch_andCancel() {
        XCTAssertTrue(app.navigationBars["Exchanges"].waitForExistence(timeout: 20))

        activateSearch()

        // Campo ativo — teclado deve aparecer
        let searchField = element(matchingIdentifier: "exchangeSearch.field.query")
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        cancelSearch()

        // Após cancelar, nav bar ainda existe (não faz pop — search é inline)
        XCTAssertTrue(app.navigationBars["Exchanges"].waitForExistence(timeout: 5))
    }

    func test_search_filtersList() {
        XCTAssertTrue(app.navigationBars["Exchanges"].waitForExistence(timeout: 20))

        activateSearch()

        let searchField = element(matchingIdentifier: "exchangeSearch.field.query")
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.typeText("Beta")

        // Aguarda debounce (150ms) + diff async
        let betaCell = element(matchingIdentifier: "exchangeList.cell.2")
        XCTAssertTrue(betaCell.waitForExistence(timeout: 5))

        // Alpha não deve estar visível
        let alphaCell = element(matchingIdentifier: "exchangeList.cell.1")
        XCTAssertFalse(alphaCell.exists)
    }

    func test_search_noResults_showsEmptyCopy() {
        XCTAssertTrue(app.navigationBars["Exchanges"].waitForExistence(timeout: 20))

        activateSearch()

        let searchField = element(matchingIdentifier: "exchangeSearch.field.query")
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.typeText("zzznotfound")

        let emptyTitle = app.staticTexts["exchangeSearch.empty.title"]
        XCTAssertTrue(emptyTitle.waitForExistence(timeout: 5))
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
