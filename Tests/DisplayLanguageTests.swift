import JavaScriptCore
import XCTest
@testable import PokeSurvivor

final class DisplayLanguageTests: XCTestCase {
    func testCatalogTranslatesNamesMovesAndPatterns() throws {
        let json = try XCTUnwrap(DisplayTranslator.bundledEntriesJSON)
        let context = JSContext()!
        var failure: String?
        context.exceptionHandler = { _, value in
            failure = value?.toString()
        }
        let probe = context.evaluateScript(DisplayTranslator.translationCore(entriesJSON: json) + """
        JSON.stringify({
          bulb: translate("Bulbasaur"),
          play: translate("Jugar"),
          level: translate("¡Nivel 12!"),
          spaced: translate("  Jugar  "),
          psychic: translate("Psíquico"),
          move: moveText("Psychic"),
          nuevo: translate("Nuevo · Pikachu"),
          digits: translate("123"),
          count: ENTRIES.length
        })
        """)
        XCTAssertNil(failure)
        let data = try XCTUnwrap(probe?.toString()?.data(using: .utf8))
        let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["bulb"] as? String, "妙蛙種子")
        XCTAssertEqual(object["play"] as? String, "開始遊戲")
        XCTAssertEqual(object["level"] as? String, "升到 12 級！")
        XCTAssertEqual(object["spaced"] as? String, "  開始遊戲  ")
        XCTAssertEqual(object["psychic"] as? String, "超能力")
        XCTAssertEqual(object["move"] as? String, "精神強念")
        XCTAssertEqual(object["nuevo"] as? String, "新招式 · 皮卡丘")
        XCTAssertEqual(object["digits"] as? String, "123")
        XCTAssertGreaterThanOrEqual(object["count"] as? Int ?? 0, 3000)
    }

    func testPageScriptStaysOnTheGamePageAndDoesNotTouchAuthOrStorage() throws {
        let script = try XCTUnwrap(DisplayTranslator.traditionalChinese)
        XCTAssertTrue(script.contains("pokesurvivor.com"))
        XCTAssertTrue(script.contains("fillText"))
        XCTAssertTrue(script.contains("measureText"))
        XCTAssertTrue(script.contains("妙蛙種子"))
        XCTAssertFalse(script.contains("localStorage"))
        XCTAssertFalse(script.contains("sessionStorage"))
        XCTAssertFalse(script.contains("fetch("))
        XCTAssertFalse(script.contains("XMLHttpRequest"))
        XCTAssertFalse(script.contains("Tampermonkey"))
        XCTAssertFalse(script.contains("/__/auth/handler"))
        XCTAssertNil(DisplayLanguage.original.pageScript)
        XCTAssertNotNil(DisplayLanguage.traditionalChinese.pageScript)
    }

    func testPageScriptInstallsOnTheGameDocument() throws {
        let script = try XCTUnwrap(DisplayTranslator.traditionalChinese)
        let context = JSContext()!
        var failure: String?
        context.exceptionHandler = { _, value in
            failure = value?.toString()
        }
        context.evaluateScript("""
        var window = globalThis;
        function node() {
          return { nodeType: 1, closest() { return null; }, getAttribute() { return null; }, parentElement: null, nodeValue: null };
        }
        var location = { hostname: 'pokesurvivor.com', pathname: '/' };
        var document = {
          body: node(),
          documentElement: { setAttribute() {}, lang: '' },
          head: { appendChild() {} },
          title: 'Jugar',
          createElement() { return { id: '', textContent: '' }; },
          createTreeWalker() { return { nextNode() { return null; } }; }
        };
        var Node = { TEXT_NODE: 3, ELEMENT_NODE: 1 };
        var NodeFilter = { SHOW_ELEMENT: 1, SHOW_TEXT: 4 };
        function MutationObserver() {}
        MutationObserver.prototype.observe = function () {};
        window.CanvasRenderingContext2D = { prototype: {
          fillText() {}, strokeText() {}, measureText() { return {}; }
        } };
        window.alert = function () {};
        window.confirm = function () {};
        """)
        context.evaluateScript(script)
        XCTAssertNil(failure)
        let installed = context.evaluateScript("!!window[Symbol.for('pokesurvivor.zhHant.displayPatch')]")
        XCTAssertEqual(installed?.toBool(), true)
        let title = context.evaluateScript("document.title")
        XCTAssertEqual(title?.toString(), "開始遊戲")
        context.evaluateScript("""
        location.hostname = 'pokesurvivor-jpter.firebaseapp.com';
        location.pathname = '/__/auth/handler';
        window[Symbol.for('pokesurvivor.zhHant.displayPatch')] = false;
        """)
        context.evaluateScript(script)
        let skipped = context.evaluateScript("!!window[Symbol.for('pokesurvivor.zhHant.displayPatch')]")
        XCTAssertEqual(skipped?.toBool(), false)
        XCTAssertNil(failure)
    }
}
