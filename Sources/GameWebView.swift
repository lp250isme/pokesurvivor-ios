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
        context.coordinator.installAuthBridge(on: controller)
        controller.add(context.coordinator, name: "psChrome")
        controller.addUserScript(WKUserScript(source: ShellScripts.viewport, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        controller.addUserScript(WKUserScript(source: ShellScripts.appSettings, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        if let script = session.displayScript {
            controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
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

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let session: GameSession
        private var progressObservation: NSKeyValueObservation?
        private var signInController: AuthPopupController?
        private var signInWebView: WKWebView?
        private var bridgedControllers: [ObjectIdentifier] = []
        private var didHandOff = false
        private var signInCancelled = false
        #if DEBUG
        private var didTapGoogle = false
        private var didOpenGameSettings = false
        private var didTapAppSettings = false
        #endif

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
                #if DEBUG
                if !didTapGoogle, ProcessInfo.processInfo.arguments.contains("-psTapGoogle") {
                    didTapGoogle = true
                    webView.evaluateJavaScript(Self.tapGoogle)
                }
                if !didOpenGameSettings, ProcessInfo.processInfo.arguments.contains("-psOpenGameSettings") {
                    didOpenGameSettings = true
                    webView.evaluateJavaScript(Self.openGameSettings)
                }
                if !didTapAppSettings, ProcessInfo.processInfo.arguments.contains("-psTapAppSettings") {
                    didTapAppSettings = true
                    webView.evaluateJavaScript(Self.tapAppSettings)
                }
                #endif
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
                if !didHandOff && !signInCancelled {
                    signInCancelled = true
                    session.webView?.evaluateJavaScript("window.__psCancelGoogle && window.__psCancelGoogle()")
                }
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
                        if !subframe {
                            NSLog("psAuth blocked sign-in window from opening %@", url.host ?? "")
                        }
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
                    if signInWebView != nil { return nil }
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

        func installAuthBridge(on controller: WKUserContentController) {
            let id = ObjectIdentifier(controller)
            guard !bridgedControllers.contains(id) else { return }
            bridgedControllers.append(id)
            controller.addUserScript(WKUserScript(
                source: ShellScripts.authBridge,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            ))
            controller.add(self, name: "psAuth")
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            MainActor.assumeIsolated {
                if message.name == "psChrome" {
                    if (message.body as? String) == "settings" {
                        session.onAppSettings()
                    }
                    return
                }
                guard message.name == "psAuth" else { return }
                guard let body = message.body as? [String: Any] else {
                    NSLog("psAuth unexpected message")
                    return
                }
                if body["ready"] as? Bool == true {
                    let hasCode = (body["hasCode"] as? Bool) == true
                    let storage = body["storage"] as? Int ?? (body["storage"] as? NSNumber)?.intValue ?? -1
                    NSLog(
                        "psAuth handler hook code=%d storage=%d",
                        hasCode ? 1 : 0,
                        storage
                    )
                    return
                }
                if let jserror = body["jserror"] as? String {
                    NSLog("psAuth js %@", jserror)
                    return
                }
                if body["missing"] as? Bool == true {
                    NSLog("psAuth token response had no Google credential")
                    return
                }
                if body["signedIn"] as? Bool == true {
                    NSLog("psAuth game signed in")
                    return
                }
                if body["close"] as? Bool == true {
                    if !didHandOff && !signInCancelled {
                        signInCancelled = true
                        session.webView?.evaluateJavaScript("window.__psCancelGoogle && window.__psCancelGoogle()")
                    }
                    finishSignIn()
                    return
                }
                guard !signInCancelled, !didHandOff else { return }
                guard message.webView === signInWebView, let page = message.frameInfo.request.url, NavigationPolicy.isAuthHandler(page) else { return }
                let idToken = body["id"] as? String ?? ""
                let accessToken = body["access"] as? String ?? ""
                guard !idToken.isEmpty || !accessToken.isEmpty else { return }
                didHandOff = true
                NSLog("psAuth handed Google credential to the game")
                completeGoogleSignIn(idToken: idToken, accessToken: accessToken)
            }
        }

        @MainActor
        private func beginSignIn(configuration: WKWebViewConfiguration) -> WKWebView {
            didHandOff = false
            signInCancelled = false
            installAuthBridge(on: configuration.userContentController)
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
        private func completeGoogleSignIn(idToken: String, accessToken: String) {
            let payload: [String: String] = ["id": idToken, "access": accessToken]
            guard let data = try? JSONSerialization.data(withJSONObject: payload),
                  let json = String(data: data, encoding: .utf8) else { return }
            session.webView?.evaluateJavaScript("window.__psCompleteGoogle && window.__psCompleteGoogle(\(json))")
            finishSignIn()
        }

        @MainActor
        private func cancelSignIn() {
            Haptics.tap()
            signInCancelled = true
            if !didHandOff {
                session.webView?.evaluateJavaScript("window.__psCancelGoogle && window.__psCancelGoogle()")
            }
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

        #if DEBUG
        private static let openGameSettings = """
        (() => {
          let n = 0;
          const tick = () => {
            document.querySelectorAll("canvas").forEach((c) => { c.style.visibility = "hidden"; });
            const start = document.getElementById("tap-start");
            if (start) start.classList.add("hidden");
            const scr = document.getElementById("scr-settings");
            if (scr) scr.classList.remove("hidden");
            if (document.getElementById("ps-app-settings") || ++n > 30) return;
            setTimeout(tick, 200);
          };
          tick();
        })();
        """

        private static let tapAppSettings = """
        (() => {
          let n = 0;
          const tick = () => {
            document.querySelectorAll("canvas").forEach((c) => { c.style.visibility = "hidden"; });
            const scr = document.getElementById("scr-settings");
            if (scr) scr.classList.remove("hidden");
            const btn = document.getElementById("ps-app-settings");
            if (btn) { btn.click(); return; }
            if (++n < 30) setTimeout(tick, 200);
          };
          tick();
        })();
        """

        private static let tapGoogle = """
        (() => {
          let n = 0;
          const tick = () => {
            const start = document.getElementById("tap-start");
            if (start && !start.classList.contains("hidden")) start.click();
            const btn = document.getElementById("btn-google");
            if (btn && btn.offsetParent) {
              btn.scrollIntoView({ block: "center" });
              btn.click();
              return;
            }
            if (++n < 40) setTimeout(tick, 250);
          };
          tick();
        })();
        """
        #endif

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
