import SwiftUI
import UIKit

@main
struct PokeSurvivorApp: App {
    @UIApplicationDelegateAdaptor(OrientationDelegate.self) private var orientationDelegate

    init() {
        DisplayLanguage.migrateStoredValue()
        UserDefaults.standard.register(defaults: [
            "displayLanguage": DisplayLanguage.traditionalChinese.rawValue,
            "keepAwake": true,
            "haptics.enabled": true,
        ])
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

final class OrientationDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .landscape
    }
}
