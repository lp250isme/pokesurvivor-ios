import WebKit

@MainActor
@Observable
final class GameSession {
    weak var webView: WKWebView?
    var phase: Phase = .booting
    var progress: Double = 0
    var canGoBack = false
    var onExternal: (URL) -> Void = { _ in }
    var patchSource: String?

    enum Phase: Equatable {
        case booting
        case loading
        case playing
        case failed(String)
    }

    func goBack() {
        guard let webView, webView.canGoBack else { return }
        Haptics.tap()
        webView.goBack()
    }

    func noteStart() {
        if phase != .playing {
            phase = .loading
        }
        syncNavigation()
    }

    func noteFinish() {
        phase = .playing
        progress = 1
        syncNavigation()
        Task { await reinjectPatchIfNeeded() }
    }

    func noteFailure(_ message: String) {
        phase = .failed(message)
        Haptics.warn()
        syncNavigation()
    }

    func syncNavigation() {
        canGoBack = webView?.canGoBack ?? false
    }

    func openExternal(_ url: URL) {
        if let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" {
            onExternal(url)
        }
    }

    private func reinjectPatchIfNeeded() async {
        guard let webView, let patchSource else { return }
        let current = try? await webView.evaluateJavaScript(ShellScripts.patchMarker)
        if (current as? Bool) == true { return }
        _ = try? await webView.evaluateJavaScript(patchSource)
    }
}
