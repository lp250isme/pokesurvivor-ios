import SwiftUI
import UIKit

struct RootView: View {
    @AppStorage("displayLanguage") private var languageRaw = DisplayLanguage.traditionalChinese.rawValue
    @AppStorage("keepAwake") private var keepAwake = true
    @AppStorage("haptics.enabled") private var hapticsEnabled = true
    @State private var session = GameSession()
    @State private var sessionID: UUID?
    @State private var showSettings = false
    @State private var settingsDetent: PresentationDetent = .large
    @State private var safari: SafariLink?
    @Environment(\.scenePhase) private var scenePhase

    private var runningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var body: some View {
        ZStack {
            Theme.abyss.ignoresSafeArea()
            if sessionID != nil {
                GameWebView(session: session)
                    .id(sessionID)
                    .ignoresSafeArea()
            }
            BootOverlay(session: session, onRetry: reloadGame, onSettings: openSettings)
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
        .tint(Theme.spark)
        .task(id: languageRaw) {
            boot()
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = keepAwake }
        .onChange(of: keepAwake) { _, on in
            UIApplication.shared.isIdleTimerDisabled = on
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                UIApplication.shared.isIdleTimerDisabled = keepAwake
                lockLandscape()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                language: languageBinding,
                keepAwake: $keepAwake,
                hapticsEnabled: $hapticsEnabled,
                onReloadGame: {
                    showSettings = false
                    reloadGame()
                }
            )
            .presentationDetents([.medium, .large], selection: $settingsDetent)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(item: $safari) { link in
            SafariSheet(url: link.url)
                .ignoresSafeArea()
        }
        .onAppear {
            session.onExternal = { safari = SafariLink(url: $0) }
            session.onAppSettings = {
                Haptics.tap()
                showSettings = true
            }
            lockLandscape()
            if ProcessInfo.processInfo.arguments.contains("-showSettings") {
                showSettings = true
            }
        }
    }

    private func lockLandscape() {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
        try? scene.requestGeometryUpdate(preferences)
    }

    private var language: DisplayLanguage {
        DisplayLanguage(rawValue: languageRaw) ?? .traditionalChinese
    }

    private var languageBinding: Binding<DisplayLanguage> {
        Binding(
            get: { language },
            set: { languageRaw = $0.rawValue }
        )
    }

    private func boot() {
        guard !runningTests else { return }
        session.displayScript = language.pageScript
        sessionID = UUID()
    }

    private func reloadGame() {
        Haptics.tap()
        session.phase = .loading
        session.displayScript = language.pageScript
        sessionID = UUID()
    }

    private func openSettings() {
        Haptics.tap()
        showSettings = true
    }
}
