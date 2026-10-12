import WebKit

@MainActor
@Observable
final class GameSession {
    weak var webView: WKWebView?
    var phase: Phase = .booting
    var progress: Double = 0
    var onExternal: (URL) -> Void = { _ in }
    var onAppSettings: () -> Void = {}
    var displayScript: String?

    enum Phase: Equatable {
        case booting
        case loading
        case playing
        case failed(String)
    }

    func noteStart() {
        if phase != .playing {
            phase = .loading
        }
    }

    func noteFinish() {
        phase = .playing
        progress = 1
        Task { await reinjectTranslationIfNeeded() }
    }

    func noteFailure(_ message: String) {
        phase = .failed(message)
        Haptics.warn()
    }

    func openExternal(_ url: URL) {
        if let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" {
            onExternal(url)
        }
    }

    private func reinjectTranslationIfNeeded() async {
        guard let webView, let displayScript else { return }
        let current = try? await webView.evaluateJavaScript(DisplayTranslator.markerExpression)
        if (current as? Bool) == true { return }
        _ = try? await webView.evaluateJavaScript(displayScript)
    }
}
