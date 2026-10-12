# pokesurvivor-ios

非官方、非商業的 PokéSurvivor iOS 客戶端。遊戲本體不在這個 repo。

## 不能做的事

- 不要把 `JPTER78/pokesurvivor` 的程式、精靈圖、字型打包進來。精靈圖是 CC BY-NC 4.0；Firebase 也只授權 `pokesurvivor.com`。客戶端只開原站。
- 繁中語系是 App 內建資料：`Resources/zh-Hant.json`。設定裡切換，不要再向 Greasy Fork 下載 userscript。套到原站時只替換畫面上的字。翻譯程式不准讀憑證、寫 storage、改網路請求，也不要跑進 `/__/auth/handler`。名稱標 PokeAPI 繁中（language 4），介面譯文標 Kai5106。Greasy Fork 授權未標，這份詞庫是使用者提供來做成語系的。
- 不要加廣告、內購、捐款按鈕。CC BY-NC 與原作者都要求非商業。
- App icon 取自原站公開圖示的寶貝球。金色外框已拿掉，避免主畫面圓角切到。出處寫在 `Resources/ICON-SOURCE.txt`。

## Google 登入

遊戲呼叫 `signInWithPopup`。Google 會拒絕預設 WKWebView（`disallowed_useragent`），因為 UA 沒有 `Safari/`。

不要改回把登入網址 `location.assign` 到遊戲那一頁：那會拆掉 `window.opener`，Firebase 收不到登入結果。也不要改走 `ASWebAuthenticationSession` 的 https callback：回跳網域是 `pokesurvivor-jpter.firebaseapp.com`，https callback 要該網域的 associated domain（`webcredentials`），這個客戶端沒有那個網域。

做法：`createWebViewWith` 對 `/__/auth/handler` 與 `accounts.google.com` 另開一個 WKWebView，用 delegate 傳來的 configuration。只在那個視窗把 `customUserAgent` 設成 Mobile Safari。Cookie 留在 App 的 `WKWebsiteDataStore`。不要把這個 UA 套到遊戲主頁。

Google 的 COOP 會切斷 `window.opener`。Firebase 於是把 popup 當成已關閉（`auth/popup-closed-by-user`），handler 再把 popup 導去 `pokesurvivor.com`，看起來像跳回主畫面，遊戲頁也拿不到登入狀態。登入視窗因此不准載入遊戲網域。`ShellScripts.authBridge` 在 handler 頁讀 `verifyAssertion` 的 `oauthIdToken` / `oauthAccessToken`，經 `psAuth` 交回遊戲頁，呼叫 `signInWithCredential`。遊戲頁先按住 `popup-closed-by-user`，等 credential 回來再 resolve，`loginWithGoogle` 的新帳號額度檢查才走得完。

## 建置

- `xcodegen generate`
- 未簽名 IPA：`./build-ipa.sh`（會把版號末位 +1）
- 側載給別人用 AltStore / SideStore / Feather / Sideloadly。本機沒有簽章憑證。

## 來源

見 `THIRD-PARTY-NOTICES.md`。
