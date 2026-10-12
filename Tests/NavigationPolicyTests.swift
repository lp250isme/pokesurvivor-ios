import XCTest
@testable import PokeSurvivor

final class NavigationPolicyTests: XCTestCase {
    func testAllowsGameAndFirebase() {
        XCTAssertTrue(NavigationPolicy.allows(URL(string: "https://pokesurvivor.com/")!))
        XCTAssertTrue(NavigationPolicy.allows(URL(string: "https://www.pokesurvivor.com/index.html")!))
        XCTAssertTrue(NavigationPolicy.allows(URL(string: "https://identitytoolkit.googleapis.com/v1/accounts")!))
        XCTAssertTrue(NavigationPolicy.allows(URL(string: "https://accounts.google.com/o/oauth2/auth")!))
        XCTAssertTrue(NavigationPolicy.allows(URL(string: "about:blank")!))
    }

    func testBlocksOtherSitesAndCleartext() {
        XCTAssertFalse(NavigationPolicy.allows(URL(string: "https://evil.com/")!))
        XCTAssertFalse(NavigationPolicy.allows(URL(string: "https://notpokesurvivor.com/")!))
        XCTAssertFalse(NavigationPolicy.allows(URL(string: "https://pokesurvivor.com.evil.com/")!))
        XCTAssertFalse(NavigationPolicy.allows(URL(string: "http://pokesurvivor.com/")!))
    }
}
