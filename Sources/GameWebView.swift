import SwiftUI
import WebKit

struct GameWebView: UIViewRepresentable {
    var session: GameSession

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let controller = configuration.userContentController
        controller.addUserScript(WKUserScript(source: ShellScripts.windowOpen, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        controller.addUserScript(WKUserScript(source: ShellScripts.viewport, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        if let patch = session.patchSource {
            controller.addUserScript(WKUserScript(source: patch, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
            controller.addUserScript(WKUserScript(source: ShellScripts.statusNote, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = Theme.uiAbyss
        webView.underPageBackgroundColor = Theme.uiAbyss
        webView.scrollView.backgroundColor = Theme.uiAbyss
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        if #available(iOS 16.4, *) {
            webView.isInspectable = false
        }
        context.coordinator.own(webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let session: GameSession
        private var progressObservation: NSKeyValueObservation?

        init(session: GameSession) {
            self.session = session
        }

        func own(_ webView: WKWebView) {
            MainActor.assumeIsolated {
                session.webView = webView
                session.phase = .loading
                session.progress = 0
            }
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { _, change in
                let value = change.newValue ?? 0
                Task { @MainActor in
                    if self.session.phase == .loading {
                        self.session.progress = value
                    }
                }
            }
            webView.load(URLRequest(url: NavigationPolicy.home))
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            MainActor.assumeIsolated { session.noteStart() }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            MainActor.assumeIsolated { session.noteFinish() }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            MainActor.assumeIsolated { session.noteFailure(Self.message(error)) }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code == NSURLErrorCancelled { return }
            MainActor.assumeIsolated { session.noteFailure(Self.message(error)) }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
        ) {
            MainActor.assumeIsolated {
                guard let url = navigationAction.request.url else {
                    decisionHandler(.allow)
                    return
                }
                if NavigationPolicy.allows(url) {
                    decisionHandler(.allow)
                    return
                }
                if navigationAction.navigationType == .linkActivated || navigationAction.targetFrame == nil {
                    session.openExternal(url)
                }
                decisionHandler(.cancel)
            }
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            MainActor.assumeIsolated {
                guard let url = navigationAction.request.url else { return nil }
                if NavigationPolicy.allows(url) {
                    webView.load(URLRequest(url: url))
                } else {
                    session.openExternal(url)
                }
                return nil
            }
        }

        private static func message(_ error: Error) -> String {
            let code = (error as NSError).code
            if code == NSURLErrorNotConnectedToInternet || code == NSURLErrorNetworkConnectionLost {
                return "沒有網路。PokéSurvivor 由原站提供，連線後才能玩。"
            }
            if code == NSURLErrorTimedOut {
                return "連到 pokesurvivor.com 逾時。"
            }
            return "打不開 pokesurvivor.com。"
        }
    }
}
