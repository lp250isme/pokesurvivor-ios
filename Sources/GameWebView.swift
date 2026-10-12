import SwiftUI
import WebKit

/// Publishes the device safe area into the page. CSS `env()` is the fallback until this runs.
/// On iPhone Duo an active fold replaces those insets with the larger side of the hinge.
/// The canvas stays full-bleed either way.
final class GameWKWebView: WKWebView {
    private var published: String?
    private var foldTimer: Timer?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        publishSafeArea()
        if window == nil {
            foldTimer?.invalidate()
            foldTimer = nil
        } else {
            watchFoldIfNeeded()
        }
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        publishSafeArea()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        publishSafeArea()
    }

    func publishSafeArea(force: Bool = false) {
        let insets = FoldLayout.insets(bounds: bounds, safe: measuredInsets(), division: FoldLayout.division(in: self))
        let payload = [insets.top, insets.right, insets.bottom, insets.left]
            .map(Self.px)
            .joined(separator: ",")
        if !force, payload == published { return }
        published = payload
        evaluateJavaScript("window.__psSetSafe&&window.__psSetSafe(\(payload))", completionHandler: nil)
    }

    /// Folding Duo does not change the window size, and this SDK has no hinge callback.
    /// The lookup is absent on iOS 17–26, so the timer never starts there.
    private func watchFoldIfNeeded() {
        guard foldTimer == nil, FoldLayout.systemCanReportDivision else { return }
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.publishSafeArea()
        }
        RunLoop.main.add(timer, forMode: .common)
        foldTimer = timer
    }

    private func measuredInsets() -> UIEdgeInsets {
        let own = safeAreaInsets
        if own.top + own.right + own.bottom + own.left > 0.5 { return own }
        guard let window else { return own }
        let frame = convert(bounds, to: window)
        let coversWindow = abs(frame.minX) < 1 && abs(frame.minY) < 1
            && abs(frame.width - window.bounds.width) < 1
            && abs(frame.height - window.bounds.height) < 1
        return coversWindow ? window.safeAreaInsets : own
    }

    private static func px(_ value: CGFloat) -> String {
        String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), Double(value))
    }
}

/// Picks the larger region that does not cross an active fold.
/// `division` is in `bounds` coordinates and already includes the system's margins.
/// A missing, empty, or offscreen band leaves the edge insets unchanged.
enum FoldLayout {
    /// UIKit names from the iOS 27.1 SDK. Looked up so an iOS 26 toolchain still builds.
    static let kindClassName = "UIViewReservedRegionKind"
    static let divisionKindSelector = "divisionRegionKind"
    static let regionsSelector = "reservedRegionsOfKind:options:"

    static var systemCanReportDivision: Bool {
        guard let kindClass = NSClassFromString(kindClassName) as? NSObject.Type else { return false }
        return kindClass.responds(to: NSSelectorFromString(divisionKindSelector))
    }

    static func insets(bounds: CGRect, safe: UIEdgeInsets, division: CGRect?) -> UIEdgeInsets {
        guard let division else { return safe }
        guard bounds.width > 1, bounds.height > 1 else { return safe }
        let safeRect = bounds.inset(by: safe)
        guard safeRect.width > 1, safeRect.height > 1, !safeRect.isNull, !safeRect.isInfinite else { return safe }
        let band = division.intersection(safeRect)
        guard !band.isNull, !band.isInfinite else { return safe }

        if band.height > band.width {
            guard band.width >= 1, band.height >= safeRect.height * 0.8 else { return safe }
            let leftWidth = band.minX - safeRect.minX
            let rightWidth = safeRect.maxX - band.maxX
            guard max(leftWidth, rightWidth) >= 64 else { return safe }
            let useLeft = leftWidth >= rightWidth
            let minX = useLeft ? safeRect.minX : band.maxX
            let maxX = useLeft ? band.minX : safeRect.maxX
            return UIEdgeInsets(
                top: safeRect.minY - bounds.minY,
                left: minX - bounds.minX,
                bottom: bounds.maxY - safeRect.maxY,
                right: bounds.maxX - maxX
            )
        }

        guard band.height >= 1, band.width >= safeRect.width * 0.8 else { return safe }
        let topHeight = band.minY - safeRect.minY
        let bottomHeight = safeRect.maxY - band.maxY
        guard max(topHeight, bottomHeight) >= 64 else { return safe }
        let useTop = topHeight >= bottomHeight
        let minY = useTop ? safeRect.minY : band.maxY
        let maxY = useTop ? band.minY : safeRect.maxY
        return UIEdgeInsets(
            top: minY - bounds.minY,
            left: safeRect.minX - bounds.minX,
            bottom: bounds.maxY - maxY,
            right: bounds.maxX - safeRect.maxX
        )
    }

    /// Active division only. Passing no query options asks UIKit for active regions,
    /// so a flat Duo (inactive fold) contributes nothing and does not pad the layout.
    static func division(in view: UIView) -> CGRect? {
        guard let kindClass = NSClassFromString(kindClassName) as? NSObject.Type else { return nil }
        let kindSelector = NSSelectorFromString(divisionKindSelector)
        guard kindClass.responds(to: kindSelector) else { return nil }
        guard let kind = kindClass.perform(kindSelector)?.takeUnretainedValue() else { return nil }
        let selector = NSSelectorFromString(regionsSelector)
        guard view.responds(to: selector) else { return nil }
        guard let returned = view.perform(selector, with: kind, with: nil)?.takeUnretainedValue() else { return nil }
        let items = (returned as? [AnyObject]) ?? (returned as? NSArray)?.compactMap { $0 as? AnyObject } ?? []
        let frameSelector = NSSelectorFromString("frame")
        var best: CGRect?
        var bestArea: CGFloat = 0
        for item in items {
            guard item.responds(to: frameSelector), let value = item.value(forKey: "frame") as? NSValue else { continue }
            let frame = value.cgRectValue
            let area = frame.width * frame.height
            guard area > bestArea else { continue }
            bestArea = area
            best = frame
        }
        return best
    }
}

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
        controller.addUserScript(WKUserScript(source: ShellScripts.safeArea, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        controller.addUserScript(WKUserScript(source: ShellScripts.appSettings, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        if let script = session.displayScript {
            controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }

        let webView = GameWKWebView(frame: .zero, configuration: configuration)
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
        private var didOpenScreen = false
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
                (webView as? GameWKWebView)?.publishSafeArea(force: true)
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
                if !didOpenScreen, let name = Self.requestedScreen() {
                    didOpenScreen = true
                    webView.evaluateJavaScript(Self.openScreen(name))
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

        private static func requestedScreen() -> String? {
            let args = ProcessInfo.processInfo.arguments
            guard let index = args.firstIndex(of: "-psOpenScr"), index + 1 < args.count else { return nil }
            let name = args[index + 1]
            let allowed = [
                "scr-menu", "scr-dex", "scr-upgrades", "scr-gacha", "scr-friends", "scr-lobby",
                "scr-rank", "scr-goals", "scr-pause", "scr-levelup", "scr-nick", "scr-over",
                "scr-item", "scr-bond", "scr-starters", "scr-settings", "scr-news", "scr-support",
                "scr-profile", "scr-legal", "scr-login", "scr-test", "scr-result", "play",
            ]
            return allowed.contains(name) ? name : nil
        }

        private static func openScreen(_ name: String) -> String {
            """
            (() => {
              const name = "\(name)";
              let n = 0;
              let held = 0;
              let opened = false;
              const open = document.getElementById.bind(document);
              const visible = (id) => {
                const el = open(id);
                return !!(el && !el.classList.contains("hidden"));
              };
              const tick = () => {
                const start = open("tap-start");
                if (start && !start.classList.contains("hidden")) start.click();
                const ready = window.G && G.UI && (visible("scr-menu") || visible("scr-login") || visible("scr-nick"));
                if (!ready) {
                  if (++n < 50) setTimeout(tick, 250);
                  return;
                }
                if (!opened) {
                  const go = name === "play" ? "play" : name.replace(/^scr-/, "");
                  const btn = document.querySelector('[data-go="' + go + '"]');
                  if (btn) btn.click();
                  else if (name !== "scr-menu") G.UI.show(name);
                  opened = true;
                }
                const bar = ["scr-menu", "scr-dex", "scr-upgrades", "scr-gacha", "scr-friends", "scr-lobby", "scr-rank", "scr-goals", "scr-news", "scr-profile"];
                if (bar.indexOf(name) >= 0 && G.UI.chrome) G.UI.chrome(true);
                if (name === "play") return;
                if (!visible(name) && name !== "scr-menu") G.UI.show(name);
                if (visible(name) && ++held >= 2) return;
                if (++n < 50) setTimeout(tick, 200);
              };
              tick();
            })();
            """
        }

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
