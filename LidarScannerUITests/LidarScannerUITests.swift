import XCTest

final class LidarScannerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts["LiDAR Scanner"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
    }

    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        let previewTab = app.buttons["Önizleme"]
        XCTAssertTrue(previewTab.exists)
        previewTab.tap()

        let emptyText = app.staticTexts["Henüz tarama yapılmadı"]
        XCTAssertTrue(emptyText.exists)
    }

    func testScanButtonExists() throws {
        let app = XCUIApplication()
        app.launch()

        let scanButton = app.buttons["Taramayı Başlat"]
        XCTAssertTrue(scanButton.exists)
    }
}
