import XCTest
@testable import PokeSurvivor

final class AuthBridgeTests: XCTestCase {
    func testBridgeHandsGoogleTokensBackWithoutLoggingThem() {
        let source = ShellScripts.authBridge
        XCTAssertTrue(source.contains("verifyAssertion"))
        XCTAssertTrue(source.contains("signInWithCredential"))
        XCTAssertTrue(source.contains("psAuth"))
        XCTAssertTrue(source.contains("auth/popup-closed-by-user"))
        XCTAssertFalse(source.contains("AIza"))
        XCTAssertFalse(source.contains("oauthIdToken:"))
    }
}
