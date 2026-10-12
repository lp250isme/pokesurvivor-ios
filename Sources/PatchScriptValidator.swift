import CryptoKit
import Foundation

/// Checks the Greasy Fork userscript before it is injected into the game page.
/// The patch author did not set a license, so the script is never stored in this repo.
enum PatchScriptValidator {
    struct Script: Equatable {
        var source: String
        var version: String
        var sha256: String
    }

    enum Failure: Error, Equatable {
        case empty
        case tooLarge
        case notUTF8
        case missingHeader
        case extraGrant
        case requiresRemote
        case blockedAPI(String)
    }

    static let maxBytes = 1_500_000

    private static let required = [
        "// @name         PokéSurvivor 繁體中文補丁",
        "// @grant        none",
        "// @match        https://pokesurvivor.com/*",
    ]

    /// The reviewed 1.0.0 script is a dictionary plus DOM/canvas text replacement.
    /// These tokens are absent from that file. A later upload that adds them is refused.
    private static let blocked = [
        "fetch(",
        "XMLHttpRequest",
        "localStorage",
        "sessionStorage",
        "indexedDB",
        "document.cookie",
        "eval(",
        "new Function",
        "WebSocket",
        "sendBeacon",
        "import(",
        "GM_",
        "chrome.runtime",
        "http://",
    ]

    static func validate(_ data: Data) throws -> Script {
        guard !data.isEmpty else { throw Failure.empty }
        guard data.count <= maxBytes else { throw Failure.tooLarge }
        guard let text = String(data: data, encoding: .utf8) else { throw Failure.notUTF8 }
        guard let headerEnd = text.range(of: "==/UserScript==") else { throw Failure.missingHeader }
        let header = String(text[..<headerEnd.upperBound])
        let grants = header.split(separator: "\n", omittingEmptySubsequences: false).filter { $0.contains("@grant") }
        guard grants.count == 1, grants[0].contains("@grant        none") else { throw Failure.extraGrant }
        guard required.allSatisfy(header.contains) else { throw Failure.missingHeader }
        if header.contains("@require") { throw Failure.requiresRemote }
        guard let version = version(in: header) else { throw Failure.missingHeader }
        for token in blocked where text.contains(token) {
            throw Failure.blockedAPI(token)
        }
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return Script(source: text, version: version, sha256: digest)
    }

    private static func version(in header: String) -> String? {
        guard let line = header.split(separator: "\n").first(where: { $0.contains("@version") }) else { return nil }
        let parts = line.split(whereSeparator: \.isWhitespace)
        guard let marker = parts.firstIndex(where: { $0 == "@version" }), parts.index(after: marker) < parts.endIndex else {
            return nil
        }
        return String(parts[parts.index(after: marker)])
    }
}
