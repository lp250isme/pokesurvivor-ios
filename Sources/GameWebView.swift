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
        private var signInController: AuthPopupController?
        private var signInWebView: WKWebView?

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
            MainActor.assumeIsolated {
                if webView === signInWebView { return }
                session.noteStart()
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            MainActor.assumeIsolated {
                if webView === signInWebView { return }
                session.noteFinish()
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            MainActor.assumeIsolated {
                if webView === signInWebView { return }
                session.noteFailure(Self.message(error))
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code == NSURLErrorCancelled { return }
            MainActor.assumeIsolated {
                if webView === signInWebView { return }
                session.noteFailure(Self.message(error))
            }
        }

        func webViewDidClose(_ webView: WKWebView) {
            MainActor.assumeIsolated {
                guard webView === signInWebView else { return }
                finishSignIn()
            }
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
                if webView === signInWebView {
                    let subframe = navigationAction.targetFrame?.isMainFrame == false
                    if subframe || NavigationPolicy.allowsSignInNavigation(url) {
                        decisionHandler(.allow)
                    } else {
                        decisionHandler(.cancel)
                    }
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
                if webView === signInWebView {
                    if NavigationPolicy.allowsSignInNavigation(url) {
                        webView.load(URLRequest(url: url))
                    }
                    return nil
                }
                if NavigationPolicy.isSignIn(url) {
                    return beginSignIn(configuration: configuration)
                }
                if NavigationPolicy.allows(url) {
                    webView.load(URLRequest(url: url))
                } else {
                    session.openExternal(url)
                }
                return nil
            }
        }

        @MainActor
        private func beginSignIn(configuration: WKWebViewConfiguration) -> WKWebView {
            let popup = WKWebView(frame: session.webView?.bounds ?? CGRect(x: 0, y: 0, width: 844, height: 390), configuration: configuration)
            popup.customUserAgent = BrowserIdentity.mobileSafari
            popup.navigationDelegate = self
            popup.uiDelegate = self
            popup.isOpaque = true
            popup.backgroundColor = .systemBackground
            popup.allowsBackForwardNavigationGestures = true
            popup.allowsLinkPreview = false
            if #available(iOS 16.4, *) {
                popup.isInspectable = false
            }
            let controller = AuthPopupController(webView: popup) { [weak self] in
                self?.cancelSignIn()
            }
            signInWebView = popup
            signInController = controller
            controller.loadViewIfNeeded()
            Task { @MainActor [weak self] in
                self?.presentSignIn(controller)
            }
            return popup
        }

        @MainActor
        private func presentSignIn(_ controller: AuthPopupController) {
            guard signInController === controller, controller.presentingViewController == nil else { return }
            guard let host = topPresenter() else { return }
            host.present(controller, animated: true)
        }

        @MainActor
        private func topPresenter() -> UIViewController? {
            guard let root = session.webView?.nearestViewController()
                ?? UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .flatMap(\.windows)
                    .first(where: \.isKeyWindow)?
                    .rootViewController
            else { return nil }
            var top = root
            while let presented = top.presentedViewController, !presented.isBeingDismissed {
                top = presented
            }
            return top
        }

        @MainActor
        private func cancelSignIn() {
            Haptics.tap()
            signInWebView?.evaluateJavaScript("window.close()")
            finishSignIn()
        }

        @MainActor
        private func finishSignIn() {
            guard let controller = signInController else { return }
            let web = signInWebView
            signInController = nil
            controller.dismiss(animated: true) { [weak self] in
                if self?.signInWebView === web {
                    self?.signInWebView = nil
                }
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

private extension UIView {
    func nearestViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let controller = current as? UIViewController { return controller }
            responder = current.next
        }
        return nil
    }
}
