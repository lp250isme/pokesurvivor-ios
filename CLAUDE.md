# pokesurvivor-ios

非官方、非商業的 PokéSurvivor iOS 客戶端。遊戲本體不在這個 repo。

## 不能做的事

- 不要把 `JPTER78/pokesurvivor` 的程式、精靈圖、字型打包進來。精靈圖是 CC BY-NC 4.0；Firebase 也只授權 `pokesurvivor.com`。客戶端只開原站。
- 不要把 Kai5106 的繁中補丁原始碼 commit 進來。Greasy Fork 授權是未標。只從官方 `@downloadURL` 抓到裝置上，並經過 `PatchScriptValidator`。
- 不要加廣告、內購、捐款按鈕。CC BY-NC 與原作者都要求非商業。
- App icon 是原站公開的 home-screen icon，不是我們畫的。出處寫在 `Resources/ICON-SOURCE.txt`。

## 建置

- `xcodegen generate`
- 未簽名 IPA：`./build-ipa.sh`（會把版號末位 +1）
- 側載給別人用 AltStore / SideStore / Feather / Sideloadly。本機沒有簽章憑證。

## 來源

見 `THIRD-PARTY-NOTICES.md`。
