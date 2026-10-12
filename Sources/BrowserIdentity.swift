import UIKit

enum BrowserIdentity {
    /// Google rejects the stock WKWebView user agent (`disallowed_useragent`)
    /// because it has no `Safari/` token. The sign-in window is still WebKit;
    /// only that window sends this string. The game view does not.
    static var mobileSafari: String {
        let system = UIDevice.current.systemVersion
        let os = system.replacingOccurrences(of: ".", with: "_")
        if UIDevice.current.userInterfaceIdiom == .pad {
            return "Mozilla/5.0 (iPad; CPU OS \(os) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(system) Mobile/15E148 Safari/604.1"
        }
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(os) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(system) Mobile/15E148 Safari/604.1"
    }
}
