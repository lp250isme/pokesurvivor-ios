import SwiftUI

struct SettingsView: View {
    @Binding var language: DisplayLanguage
    @Binding var keepAwake: Bool
    @Binding var hapticsEnabled: Bool
    var onReloadGame: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var safari: SafariLink?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("語言", selection: $language) {
                        ForEach(DisplayLanguage.allCases) { item in
                            Text(item.label).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("語言")
                } footer: {
                    Text("繁體中文直接做在這個 App 裡，套在原站畫面上。寶可夢名稱依 PokeAPI 繁中，介面譯文來自 Kai5106。切換後會重新載入。選原文就顯示原站自己的文字。帳號和存檔仍在原站。")
                }

                Section("遊玩") {
                    Toggle("螢幕保持恆亮", isOn: $keepAwake)
                    Toggle("觸覺回饋", isOn: $hapticsEnabled)
                    Button("重新載入遊戲", action: onReloadGame)
                }

                Section {
                    link("遊戲原站", "https://pokesurvivor.com/")
                    link("原作者 GitHub", "https://github.com/JPTER78/pokesurvivor")
                    link("繁中譯文", "https://greasyfork.org/zh-TW/scripts/599869")
                    link("譯文說明", "https://usegametool.blogspot.com/2026/10/pokesurvivor.html")
                    Button("在 Safari 開啟原站") {
                        safari = SafariLink(url: NavigationPolicy.home)
                    }
                } header: {
                    Text("來源")
                } footer: {
                    Text("使用 Google 登入會在這個 App 裡打開登入視窗。Google 完成後，登入狀態會回到遊戲。這份登入存在 App 裡，跟用 Safari 開原站是分開的。")
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
        .onChange(of: language) { _, _ in Haptics.select() }
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
