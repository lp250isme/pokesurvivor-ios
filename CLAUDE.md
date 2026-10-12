# pokesurvivor-ios

非官方、非商業的 PokéSurvivor iOS 客戶端。遊戲本體不在這個 repo。

## 不能做的事

- 不要把 `JPTER78/pokesurvivor` 的程式、精靈圖、字型打包進來。精靈圖是 CC BY-NC 4.0；Firebase 也只授權 `pokesurvivor.com`。客戶端只開原站。
- 不要把 Kai5106 的繁中補丁原始碼 commit 進來。Greasy Fork 授權是未標。只從官方 `@downloadURL` 抓到裝置上，並經過 `PatchScriptValidator`。
- 不要加廣告、內購、捐款按鈕。CC BY-NC 與原作者都要求非商業。
- App icon 是原站公開的 home-screen icon，不是我們畫的。出處寫在 `Resources/ICON-SOURCE.txt`。

## Google 登入

遊戲呼叫 `signInWithPopup`。Google 會拒絕預設 WKWebView（`disallowed_useragent`），因為 UA 沒有 `Safari/`。

不要改回把登入網址 `location.assign` 到遊戲那一頁：那會拆掉 `window.opener`，Firebase 收不到登入結果。也不要改走 `ASWebAuthenticationSession` 的 https callback：回跳網域是 `pokesurvivor-jpter.firebaseapp.com`，https callback 要該網域的 associated domain（`webcredentials`），這個客戶端沒有那個網域。

做法：`createWebViewWith` 對 `/__/auth/handler` 與 `accounts.google.com` 另開一個 WKWebView，用 delegate 傳來的 configuration（才有 `window.opener`）。只在那個視窗把 `customUserAgent` 設成 Mobile Safari。Cookie 留在 App 的 `WKWebsiteDataStore`。不要把這個 UA 套到遊戲主頁。

## 建置

- `xcodegen generate`
- 未簽名 IPA：`./build-ipa.sh`（會把版號末位 +1）
- 側載給別人用 AltStore / SideStore / Feather / Sideloadly。本機沒有簽章憑證。

## 來源

見 `THIRD-PARTY-NOTICES.md`。
