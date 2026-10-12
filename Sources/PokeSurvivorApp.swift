import SwiftUI
import UIKit

@main
struct PokeSurvivorApp: App {
    @UIApplicationDelegateAdaptor(OrientationDelegate.self) private var orientationDelegate

    init() {
        UserDefaults.standard.register(defaults: [
            "patch.enabled": true,
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
