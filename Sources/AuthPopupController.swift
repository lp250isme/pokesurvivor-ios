import UIKit
import WebKit

/// Google account chooser. Presented over the game for `signInWithPopup`.
final class AuthPopupController: UIViewController {
    let webView: WKWebView
    private let onCancel: @MainActor () -> Void

    init(webView: WKWebView, onCancel: @escaping @MainActor () -> Void) {
        self.webView = webView
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let bar = UINavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        let item = UINavigationItem(title: "Google 登入")
        let cancel = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelTapped))
        cancel.accessibilityIdentifier = "google-sign-in-cancel"
        item.leftBarButtonItem = cancel
        bar.items = [item]

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.accessibilityIdentifier = "google-sign-in"
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(bar)
        view.addSubview(webView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: guide.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: bar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
        ])
    }

    @objc private func cancelTapped() {
        onCancel()
    }
}
