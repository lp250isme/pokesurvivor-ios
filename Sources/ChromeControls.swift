import SwiftUI

struct ChromeControls: View {
    var session: GameSession
    var dimmed: Bool
    var onSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if session.canGoBack {
                chromeButton("chevron.backward", "返回", session.goBack)
            }
            chromeButton("gearshape.fill", "設定", onSettings)
        }
        .opacity(dimmed ? 0.38 : 1)
        .animation(.easeOut(duration: 0.35), value: dimmed)
    }

    private func chromeButton(_ symbol: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .modifier(ChromeGlass())
        .accessibilityLabel(label)
    }
}

private struct ChromeGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular.interactive(), in: .circle)
        } else {
            content.background(.ultraThinMaterial, in: Circle())
        }
    }
}
