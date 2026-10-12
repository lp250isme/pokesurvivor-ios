import Foundation

@MainActor
@Observable
final class PatchClient {
    /// Official Greasy Fork install URL. The script is cached on device, not committed.
    static let downloadURL = URL(string: "https://update.greasyfork.org/scripts/599869/Pok%C3%A9Survivor%20%E7%B9%81%E9%AB%94%E4%B8%AD%E6%96%87%E8%A3%9C%E4%B8%81.user.js")!

    private(set) var source: String?
    private(set) var version: String?
    private(set) var sha256: String?
    private(set) var fetchedAt: Date?
    private(set) var status: Status = .idle

    enum Status: Equatable {
        case idle
        case loading
        case cached
        case ready
        case failed(String)
    }

    func prepare() async {
        if let cached = readCache() {
            apply(cached)
            status = .cached
            return
        }
        _ = await refresh()
    }

    @discardableResult
    func refresh() async -> Bool {
        status = .loading
        var request = URLRequest(url: Self.downloadURL, timeoutInterval: 20)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw Failure.badResponse
            }
            let script = try PatchScriptValidator.validate(data)
            try write(data)
            apply(script)
            status = .ready
            return true
        } catch {
            status = .failed(Self.message(for: error))
            return false
        }
    }

    private func apply(_ script: PatchScriptValidator.Script) {
        source = script.source
        version = script.version
        sha256 = script.sha256
        fetchedAt = readMeta()?.fetchedAt
    }

    private func readCache() -> PatchScriptValidator.Script? {
        guard let data = try? Data(contentsOf: Self.scriptFile) else { return nil }
        guard let script = try? PatchScriptValidator.validate(data) else {
            try? FileManager.default.removeItem(at: Self.scriptFile)
            return nil
        }
        return script
    }

    private func write(_ data: Data) throws {
        try FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        try data.write(to: Self.scriptFile, options: .atomic)
        let meta = Meta(fetchedAt: Date())
        let encoded = try JSONEncoder().encode(meta)
        try encoded.write(to: Self.metaFile, options: .atomic)
        fetchedAt = meta.fetchedAt
    }

    private func readMeta() -> Meta? {
        guard let data = try? Data(contentsOf: Self.metaFile) else { return nil }
        return try? JSONDecoder().decode(Meta.self, from: data)
    }

    private static func message(for error: Error) -> String {
        if let failure = error as? PatchScriptValidator.Failure {
            switch failure {
            case .empty, .notUTF8, .missingHeader, .extraGrant, .requiresRemote:
                return "補丁內容與原作者發布的格式不符，已拒絕注入。"
            case .tooLarge:
                return "補丁檔案過大，已拒絕注入。"
            case .blockedAPI(let token):
                return "補丁含未審查的行為（\(token)），已拒絕注入。"
            }
        }
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return "沒有網路，抓不到繁中補丁。"
        }
        return "抓不到繁中補丁。可以先玩原文，稍後再試。"
    }

    private struct Meta: Codable {
        var fetchedAt: Date
    }

    private enum Failure: Error {
        case badResponse
    }

    private static var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PokéSurvivorPatch", isDirectory: true)
    }

    private static var scriptFile: URL { directory.appendingPathComponent("zh-hant.user.js") }
    private static var metaFile: URL { directory.appendingPathComponent("meta.json") }
}
