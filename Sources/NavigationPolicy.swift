import Foundation

enum NavigationPolicy {
    static let home = URL(string: "https://pokesurvivor.com/")!

    private static let hosts = [
        "pokesurvivor.com",
        "googleapis.com",
        "gstatic.com",
        "google.com",
        "googleusercontent.com",
        "firebaseio.com",
        "firebaseapp.com",
        "recaptcha.net",
    ]

    static func allows(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        if scheme == "about" || scheme == "blob" || scheme == "data" { return true }
        guard scheme == "https", let host = url.host?.lowercased() else { return false }
        return hosts.contains { host == $0 || host.hasSuffix(".\($0)") }
    }

    /// Firebase `signInWithPopup` opens `https://<authDomain>/__/auth/handler`.
    static func isSignIn(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else { return false }
        if host == "accounts.google.com" { return true }
        return isAuthHandler(url)
    }

    /// The page that exchanges the Google code. Credential messages are accepted only from here.
    static func isAuthHandler(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else { return false }
        guard url.path == "/__/auth/handler" || url.path.hasPrefix("/__/auth/handler/") else { return false }
        return host == "firebaseapp.com" || host.hasSuffix(".firebaseapp.com")
            || host == "pokesurvivor.com" || host.hasSuffix(".pokesurvivor.com")
    }

    /// Main-frame loads inside the sign-in window. The game origin is refused:
    /// when `window.opener` is gone, the handler navigates here and the sheet shows the start screen.
    static func allowsSignInNavigation(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else { return false }
        if host == "pokesurvivor.com" || host.hasSuffix(".pokesurvivor.com") {
            return isAuthHandler(url)
        }
        if allows(url) { return true }
        return host == "youtube.com" || host.hasSuffix(".youtube.com")
    }
}
