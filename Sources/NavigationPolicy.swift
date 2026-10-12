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
}
