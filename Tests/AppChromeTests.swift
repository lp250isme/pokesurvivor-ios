import UIKit
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

    func testSafeAreaInsetsEveryFixedPage() {
        let source = ShellScripts.safeArea
        for token in [
            "safe-area-inset-top", "safe-area-inset-right", "safe-area-inset-bottom", "safe-area-inset-left",
            ".scr", "#pull-fx", ".tapstart", ".boot", ".topbar", ".credits-line",
            ".sound-panel", ".toast", ".ach-pop", ".invite-pop", "__psSetSafe", "G.HUD", "pokesurvivor.com",
            "height:30px!important", "#btn-support",
        ] {
            XCTAssertTrue(source.contains(token), token)
        }
        XCTAssertFalse(source.contains("#game"))
        XCTAssertFalse(source.contains("#rotate"))
        XCTAssertFalse(source.contains("localStorage"))
        XCTAssertFalse(source.contains("sessionStorage"))
        XCTAssertFalse(source.contains("fetch("))
        XCTAssertFalse(source.contains("XMLHttpRequest"))
    }

    func testDuoDivisionLookupNames() {
        XCTAssertEqual(FoldLayout.kindClassName, "UIViewReservedRegionKind")
        XCTAssertEqual(FoldLayout.divisionKindSelector, "divisionRegionKind")
        XCTAssertEqual(FoldLayout.regionsSelector, "reservedRegionsOfKind:options:")
    }

    func testDivisionLookupIsAbsentOnThisSDK() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
        XCTAssertFalse(FoldLayout.systemCanReportDivision)
        XCTAssertNil(FoldLayout.division(in: view))
    }

    func testMissingOrThinDivisionKeepsEdgeInsets() {
        let bounds = CGRect(x: 0, y: 0, width: 874, height: 402)
        let safe = UIEdgeInsets(top: 0, left: 59, bottom: 21, right: 0)
        XCTAssertEqual(FoldLayout.insets(bounds: bounds, safe: safe, division: nil), safe)
        let line = CGRect(x: 400, y: 0, width: 0, height: 402)
        XCTAssertEqual(FoldLayout.insets(bounds: bounds, safe: safe, division: line), safe)
        let patch = CGRect(x: 400, y: 20, width: 40, height: 40)
        XCTAssertEqual(FoldLayout.insets(bounds: bounds, safe: .zero, division: patch), .zero)
        let sliver = CGRect(x: 10, y: 0, width: 180, height: 400)
        XCTAssertEqual(
            FoldLayout.insets(bounds: CGRect(x: 0, y: 0, width: 200, height: 400), safe: .zero, division: sliver),
            .zero
        )
    }

    func testActiveVerticalFoldUsesTheWiderSide() {
        let bounds = CGRect(x: 0, y: 0, width: 951, height: 669)
        let rail = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 84)
        let fold = CGRect(x: 455, y: 0, width: 40, height: 669)
        let left = FoldLayout.insets(bounds: bounds, safe: rail, division: fold)
        XCTAssertEqual(left.top, 0, accuracy: 0.01)
        XCTAssertEqual(left.left, 0, accuracy: 0.01)
        XCTAssertEqual(left.bottom, 0, accuracy: 0.01)
        XCTAssertEqual(left.right, 496, accuracy: 0.01)

        let right = FoldLayout.insets(bounds: bounds, safe: .zero, division: CGRect(x: 100, y: 0, width: 40, height: 669))
        XCTAssertEqual(right.left, 140, accuracy: 0.01)
        XCTAssertEqual(right.right, 0, accuracy: 0.01)
        XCTAssertEqual(right.top, 0, accuracy: 0.01)
        XCTAssertEqual(right.bottom, 0, accuracy: 0.01)

        let tie = FoldLayout.insets(bounds: CGRect(x: 0, y: 0, width: 800, height: 600), safe: .zero, division: CGRect(x: 380, y: 0, width: 40, height: 600))
        XCTAssertEqual(tie.left, 0, accuracy: 0.01)
        XCTAssertEqual(tie.right, 420, accuracy: 0.01)
    }

    func testActiveHorizontalFoldUsesTheTallerSide() {
        let bounds = CGRect(x: 0, y: 0, width: 669, height: 951)
        let fold = CGRect(x: 0, y: 455, width: 669, height: 40)
        let bottom = FoldLayout.insets(bounds: bounds, safe: .zero, division: fold)
        XCTAssertEqual(bottom.top, 495, accuracy: 0.01)
        XCTAssertEqual(bottom.bottom, 0, accuracy: 0.01)
        XCTAssertEqual(bottom.left, 0, accuracy: 0.01)
        XCTAssertEqual(bottom.right, 0, accuracy: 0.01)

        let top = FoldLayout.insets(bounds: bounds, safe: UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0), division: CGRect(x: 0, y: 700, width: 669, height: 40))
        XCTAssertEqual(top.top, 20, accuracy: 0.01)
        XCTAssertEqual(top.bottom, 251, accuracy: 0.01)
    }

    func testFoldOutsideTheViewKeepsEdgeInsets() {
        let bounds = CGRect(x: 0, y: 0, width: 800, height: 400)
        let safe = UIEdgeInsets(top: 10, left: 4, bottom: 8, right: 6)
        let fold = CGRect(x: 900, y: 0, width: 40, height: 400)
        XCTAssertEqual(FoldLayout.insets(bounds: bounds, safe: safe, division: fold), safe)
    }
}
