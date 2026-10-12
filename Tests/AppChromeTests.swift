import XCTest
@testable import PokeSurvivor

final class AppChromeTests: XCTestCase {
    func testAppSettingsButtonStaysInsideTheGame() {
        let source = ShellScripts.appSettings
        XCTAssertTrue(source.contains("psChrome"))
        XCTAssertTrue(source.contains("set-close"))
        XCTAssertTrue(source.contains("btn-pause-settings"))
        XCTAssertTrue(source.contains("pszhControl"))
        XCTAssertTrue(source.contains("App 設定"))
        XCTAssertFalse(source.contains("localStorage"))
        XCTAssertFalse(source.contains("sessionStorage"))
        XCTAssertFalse(source.contains("fetch("))
        XCTAssertFalse(source.contains("XMLHttpRequest"))
        XCTAssertFalse(source.contains("/__/auth/handler"))
    }
}
