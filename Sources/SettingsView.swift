import SwiftUI

struct SettingsView: View {
    @Binding var patchEnabled: Bool
    @Binding var keepAwake: Bool
    @Binding var hapticsEnabled: Bool
    var client: PatchClient
    var onReloadGame: () -> Void
    var onRefreshPatch: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var safari: SafariLink?
    @State private var refreshing = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("繁體中文補丁", isOn: $patchEnabled)
                    LabeledContent("版本") {
                        Text(client.version ?? "尚未取得")
                    }
                    if let fetchedAt = client.fetchedAt {
                        LabeledContent("取得時間") {
                            Text(fetchedAt.formatted(
                                Date.FormatStyle(date: .abbreviated, time: .shortened)
                                    .locale(Locale(identifier: "zh-TW"))
                            ))
                        }
                    }
                    if let sha = client.sha256 {
                        LabeledContent("SHA-256") {
                            Text(String(sha.prefix(12)))
                                .font(.caption.monospaced())
                        }
                        .accessibilityLabel("SHA-256 \(sha)")
                    }
                    Button(refreshing ? "取得中…" : "重新取得補丁") {
                        refreshing = true
                        Task {
                            await onRefreshPatch()
                            refreshing = false
                        }
                    }
                    .disabled(refreshing || !patchEnabled)
                } header: {
                    Text("翻譯")
                } footer: {
                    Text("補丁作者 Kai5106，授權未標。App 只向 Greasy Fork 官方網址抓取，檢查過格式後注入，不把腳本放進原始碼。關閉後重新載入即恢復原文。")
                }

                Section("遊玩") {
                    Toggle("螢幕保持恆亮", isOn: $keepAwake)
                    Toggle("觸覺回饋", isOn: $hapticsEnabled)
                    Button("重新載入遊戲", action: onReloadGame)
                }

                Section {
                    link("遊戲原站", "https://pokesurvivor.com/")
                    link("原作者 GitHub", "https://github.com/JPTER78/pokesurvivor")
                    link("繁中補丁", "https://greasyfork.org/zh-TW/scripts/599869")
                    link("補丁說明", "https://usegametool.blogspot.com/2026/10/pokesurvivor.html")
                    Button("在 Safari 開啟原站") {
                        safari = SafariLink(url: NavigationPolicy.home)
                    }
                } header: {
                    Text("來源")
                } footer: {
                    Text("Google 登入在 App 內可能被 Google 拒絕。帳號密碼與訪客可以玩。需要 Google 帳號時，用 Safari 開啟原站。")
                }

                Section("關於") {
                    Text("這是非官方 iOS 客戶端，不是 JPTER78 或任天堂的產品。遊戲畫面由 pokesurvivor.com 提供，存檔與帳號留在原站。沒有廣告，也沒有內購。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    LabeledContent("客戶端") {
                        Text(appVersion)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DungeonBackdrop())
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .tint(Theme.spark)
        }
        .sheet(item: $safari) { link in
            SafariSheet(url: link.url)
                .ignoresSafeArea()
        }
        .onChange(of: patchEnabled) { _, _ in Haptics.select() }
        .onChange(of: keepAwake) { _, _ in Haptics.select() }
        .onChange(of: hapticsEnabled) { _, _ in Haptics.select() }
    }

    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    private func link(_ title: String, _ raw: String) -> some View {
        Button(title) {
            if let url = URL(string: raw) {
                safari = SafariLink(url: url)
            }
        }
    }
}
