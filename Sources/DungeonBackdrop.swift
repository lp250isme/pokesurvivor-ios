import SwiftUI

struct DungeonBackdrop: View {
    var body: some View {
        ZStack {
            Theme.abyss
            RadialGradient(
                colors: [Theme.dungeon.opacity(0.95), Theme.abyss.opacity(0)],
                center: .center,
                startRadius: 12,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
    }
}
