import XCTest
@testable import PokeSurvivor

final class PatchScriptValidatorTests: XCTestCase {
    func testAcceptsReviewedShape() throws {
        let script = try PatchScriptValidator.validate(Data(Self.header.utf8))
        XCTAssertEqual(script.version, "1.0.0")
        XCTAssertFalse(script.sha256.isEmpty)
        XCTAssertTrue(script.source.contains("繁體中文補丁"))
    }

    func testRejectsExtraGrant() {
        let source = Self.header.replacingOccurrences(of: "// @grant        none", with: "// @grant        GM_xmlhttpRequest")
        XCTAssertThrowsError(try PatchScriptValidator.validate(Data(source.utf8))) { error in
            XCTAssertEqual(error as? PatchScriptValidator.Failure, .extraGrant)
        }
    }

    func testRejectsRequire() {
        let source = Self.header.replacingOccurrences(
            of: "==/UserScript==",
            with: "// @require      https://example.com/x.js\n==/UserScript=="
        )
        XCTAssertThrowsError(try PatchScriptValidator.validate(Data(source.utf8))) { error in
            XCTAssertEqual(error as? PatchScriptValidator.Failure, .requiresRemote)
        }
    }

    func testRejectsNetworkAPI() {
        let source = Self.header + "\nfetch('https://example.com');"
        XCTAssertThrowsError(try PatchScriptValidator.validate(Data(source.utf8))) { error in
            XCTAssertEqual(error as? PatchScriptValidator.Failure, .blockedAPI("fetch("))
        }
    }

    func testRejectsCleartextURL() {
        let source = Self.header + "\nconst x = 'http://example.com';"
        XCTAssertThrowsError(try PatchScriptValidator.validate(Data(source.utf8))) { error in
            XCTAssertEqual(error as? PatchScriptValidator.Failure, .blockedAPI("http://"))
        }
    }

    func testRejectsEmpty() {
        XCTAssertThrowsError(try PatchScriptValidator.validate(Data())) { error in
            XCTAssertEqual(error as? PatchScriptValidator.Failure, .empty)
        }
    }

    private static let header = """
    // ==UserScript==
    // @name         PokéSurvivor 繁體中文補丁
    // @version      1.0.0
    // @grant        none
    // @match        https://pokesurvivor.com/*
    // ==/UserScript==
    (() => { const dict = { hola: "你好" }; })();
    """
}
