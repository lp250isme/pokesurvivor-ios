import SwiftUI

struct BootOverlay: View {
    var session: GameSession
    var patchEnabled: Bool
    var patchMissing: Bool
    var patchStatus: PatchClient.Status
    var onRetry: () -> Void

    var body: some View {
        switch session.phase {
        case .playing:
            patchBanner
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
                Text(splashTitle)
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

    private var splashTitle: String {
        if case .booting = session.phase, patchEnabled {
            return "正在取得繁體中文補丁"
        }
        return "正在打開原站"
    }

    @ViewBuilder
    private var patchBanner: some View {
        if patchEnabled, patchMissing, case .failed(let message) = patchStatus {
            VStack {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.ember.opacity(0.92), in: Capsule())
                    .padding(.top, 10)
                Spacer()
            }
            .padding(.horizontal, 24)
            .allowsHitTesting(false)
        }
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
            }
            .padding(28)
        }
    }

    private var gameMark: some View {
        Image("GameIcon")
            .resizable()
            .interpolation(.none)
            .frame(width: 88, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
            .accessibilityHidden(true)
    }
}
