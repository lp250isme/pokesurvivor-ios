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

    func testRecognizesFirebaseAndGoogleSignIn() {
        XCTAssertTrue(NavigationPolicy.isSignIn(URL(string: "https://pokesurvivor-jpter.firebaseapp.com/__/auth/handler?apiKey=1")!))
        XCTAssertTrue(NavigationPolicy.isSignIn(URL(string: "https://accounts.google.com/o/oauth2/v2/auth?client_id=1")!))
        XCTAssertTrue(NavigationPolicy.isSignIn(URL(string: "https://pokesurvivor.com/__/auth/handler")!))
        XCTAssertFalse(NavigationPolicy.isSignIn(URL(string: "https://pokesurvivor.com/")!))
        XCTAssertFalse(NavigationPolicy.isSignIn(URL(string: "https://pokesurvivor-jpter.firebaseapp.com/__/auth/iframe")!))
        XCTAssertFalse(NavigationPolicy.isSignIn(URL(string: "https://firebaseapp.com.evil.com/__/auth/handler")!))
        XCTAssertFalse(NavigationPolicy.isSignIn(URL(string: "http://accounts.google.com/o/oauth2/v2/auth")!))
    }

    func testSignInWindowAllowsAccountChooserHosts() {
        XCTAssertTrue(NavigationPolicy.allowsSignInNavigation(URL(string: "https://accounts.youtube.com/accounts/SetSID")!))
        XCTAssertTrue(NavigationPolicy.allowsSignInNavigation(URL(string: "https://pokesurvivor-jpter.firebaseapp.com/__/auth/handler")!))
        XCTAssertFalse(NavigationPolicy.allowsSignInNavigation(URL(string: "https://pokesurvivor.com/")!))
        XCTAssertFalse(NavigationPolicy.allowsSignInNavigation(URL(string: "https://www.pokesurvivor.com/play")!))
        XCTAssertFalse(NavigationPolicy.allowsSignInNavigation(URL(string: "https://evil.com/")!))
        XCTAssertFalse(NavigationPolicy.allowsSignInNavigation(URL(string: "https://youtube.com.evil.com/")!))
    }

    func testAuthHandlerIsOnlyTheFirebaseHelper() {
        XCTAssertTrue(NavigationPolicy.isAuthHandler(URL(string: "https://pokesurvivor-jpter.firebaseapp.com/__/auth/handler?apiKey=1")!))
        XCTAssertFalse(NavigationPolicy.isAuthHandler(URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!))
        XCTAssertFalse(NavigationPolicy.isAuthHandler(URL(string: "https://pokesurvivor.com/")!))
    }

    func testSignInUserAgentLooksLikeMobileSafari() {
        let agent = BrowserIdentity.mobileSafari
        XCTAssertTrue(agent.contains("Safari/"))
        XCTAssertTrue(agent.contains("Mobile/"))
        XCTAssertFalse(agent.contains("WKWebView"))
    }
}
