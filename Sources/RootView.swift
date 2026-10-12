import SwiftUI
import UIKit

struct RootView: View {
    @AppStorage("patch.enabled") private var patchEnabled = true
    @AppStorage("keepAwake") private var keepAwake = true
    @AppStorage("haptics.enabled") private var hapticsEnabled = true
    @State private var client = PatchClient()
    @State private var session = GameSession()
    @State private var sessionID: UUID?
    @State private var showSettings = false
    @State private var settingsDetent: PresentationDetent = .large
    @State private var chromeDimmed = false
    @State private var safari: SafariLink?
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.scenePhase) private var scenePhase

    private var runningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.abyss.ignoresSafeArea()
            if sessionID != nil {
                GameWebView(session: session)
                    .id(sessionID)
                    .ignoresSafeArea()
            }
            BootOverlay(
                session: session,
                patchEnabled: patchEnabled,
                patchMissing: client.source == nil,
                patchStatus: client.status,
                onRetry: reloadGame
            )
            ChromeControls(session: session, dimmed: chromeDimmed && !voiceOver) {
                Haptics.tap()
                showSettings = true
            }
            .padding(.top, 8)
            .padding(.trailing, 8)
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
        .tint(Theme.spark)
        .task(id: patchEnabled) {
            await boot()
        }
        .task(id: sessionID) {
            await fadeChrome()
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
                patchEnabled: $patchEnabled,
                keepAwake: $keepAwake,
                hapticsEnabled: $hapticsEnabled,
                client: client,
                onReloadGame: {
                    showSettings = false
                    reloadGame()
                },
                onRefreshPatch: refreshPatch
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

    private func boot() async {
        guard !runningTests else { return }
        if patchEnabled, client.source == nil {
            session.phase = .booting
            await client.prepare()
        }
        session.patchSource = patchEnabled ? client.source : nil
        sessionID = UUID()
    }

    private func reloadGame() {
        Haptics.tap()
        session.phase = .loading
        session.patchSource = patchEnabled ? client.source : nil
        sessionID = UUID()
    }

    private func refreshPatch() async {
        let ok = await client.refresh()
        guard ok else {
            Haptics.warn()
            return
        }
        Haptics.tap()
        session.patchSource = patchEnabled ? client.source : nil
        sessionID = UUID()
    }

    private func fadeChrome() async {
        chromeDimmed = false
        if voiceOver { return }
        try? await Task.sleep(for: .seconds(3))
        guard !Task.isCancelled else { return }
        chromeDimmed = true
    }
}
