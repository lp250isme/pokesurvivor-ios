import SwiftUI
import UIKit

struct BootOverlay: View {
    var session: GameSession
    var onRetry: () -> Void
    var onSettings: () -> Void

    var body: some View {
        switch session.phase {
        case .playing:
            EmptyView()
        case .failed(let message):
            failure(message)
        case .booting, .loading:
            splash
        }
    }

    private var splash: some View {
        ZStack {
            DungeonBackdrop()
            VStack(spacing: 16) {
                gameMark
                Text("PokéSurvivor")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                Text("遊戲啟動中")
                    .font(.headline)
                    .foregroundStyle(Theme.spark)
                    .multilineTextAlignment(.center)
                if session.phase == .loading {
                    ProgressView(value: session.progress)
                        .tint(Theme.spark)
                        .frame(maxWidth: 180)
                } else {
                    ProgressView()
                        .tint(Theme.spark)
                }
            }
            .padding(28)
        }
        .accessibilityElement(children: .combine)
    }

    private func failure(_ message: String) -> some View {
        ZStack {
            DungeonBackdrop()
            VStack(spacing: 16) {
                gameMark
                Text(message)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Button("再試一次", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.spark)
                    .foregroundStyle(Theme.abyss)
                Button("App 設定", action: onSettings)
                    .buttonStyle(.bordered)
                    .tint(Theme.spark)
            }
            .padding(28)
        }
    }

    private var gameMark: some View {
        Group {
            if let image = UIImage(named: "GameIcon") {
                Image(uiImage: image)
                    .renderingMode(.original)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 88, height: 88)
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
        .accessibilityHidden(true)
    }
}
