# PokéSurvivor iOS

[English](#english) | [繁體中文](#繁體中文)

Unofficial, non-commercial iOS client for the fan game [PokéSurvivor](https://pokesurvivor.com/). The game stays on the author's site. Settings switches the on-screen language to Traditional Chinese.

## English

### What this is

A landscape iOS app that opens `https://pokesurvivor.com/` in a full-screen web view: no browser bar, screen stays awake, login and cloud saves stay on the original site. Settings → 語言 chooses 繁體中文 or the site's own text. The Chinese catalog ships in the app.

In the game, open settings or pause and tap App 設定. That opens this app's language and options. No button sits on top of the game.

### Install

The GitHub Release IPA is unsigned. Sign it with your own Apple ID:

- AltStore, SideStore, or Feather: import the IPA
- Sideloadly: open the IPA and install

A free Apple ID signature expires in about 7 days. Refresh it with the same tool. iOS 17 or later. iPhone and iPad. The game plays in landscape.

Google sign-in opens in a window inside the app. After Google finishes, the app signs that account into the game. The first time, choose the Google account there. Email, password, and guest play also work. Signing in through Safari does not sign the app in.

### Build

```bash
xcodegen generate
./build-ipa.sh
```

`build-ipa.sh` bumps the version, builds an unsigned IPA, and copies it to iCloud Drive `ipa/PokeSurvivor/`.

### Rights

This client does not redistribute the game. Read [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) before you mirror or sell anything. Do not add ads or payments: the sprites are CC BY-NC 4.0, and the game author publishes it as a free fan work.

| Piece | Who | Terms |
| --- | --- | --- |
| iOS client | kv | MIT, this repo only |
| Game code | [JPTER78](https://github.com/JPTER78/pokesurvivor) | MIT. Not copied here. Loaded from pokesurvivor.com |
| Sprites | [SpriteCollab](https://github.com/PMDCollab/SpriteCollab) | CC BY-NC 4.0. Not copied here |
| zh-Hant text | [Kai5106](https://greasyfork.org/zh-TW/scripts/599869) | License unspecified. Display strings from the supplied 1.0.0 text, bundled as `Resources/zh-Hant.json`. Names: PokeAPI language 4 |
| Translation guide | [usegametool](https://usegametool.blogspot.com/2026/10/pokesurvivor.html) | The blog that points at that text |
| App icon | pokesurvivor.com | Poké Ball from the published icon. Gold frame removed so the iOS mask does not crop it. Not MIT code |
| Pokémon | Nintendo, Creatures, GAME FREAK, The Pokémon Company | Their trademarks. Not affiliated |

## 繁體中文

### 這是什麼

把 [PokéSurvivor](https://pokesurvivor.com/) 包成橫向全螢幕 App。沒有網址列，螢幕不會自己暗掉，帳號和雲端存檔仍在原站。設定 → 語言可以切換繁體中文或原站自己的文字。繁中詞庫在 App 裡。

遊戲裡打開設定或暫停，按「App 設定」，就是這個 App 的語言和選項。沒有按鈕蓋在遊戲上面。

### 安裝

GitHub Release 的 IPA 沒有簽章，要用你自己的 Apple ID 簽：

- AltStore、SideStore、Feather：匯入 IPA
- Sideloadly：打開 IPA 安裝

免費 Apple ID 的簽章大約 7 天，用同一個工具重新整理。需要 iOS 17 以上，iPhone 與 iPad 都可以。遊戲是橫向。

「使用 Google 登入」會在 App 裡打開登入視窗。Google 完成後，App 會把這個帳號登進遊戲。第一次要在那裡選 Google 帳號。帳號密碼和訪客也可以玩。用 Safari 開原站不會讓 App 跟著登入。

### 建置

```bash
xcodegen generate
./build-ipa.sh
```

`build-ipa.sh` 會把版號末位加一，產出未簽名 IPA，並複製到 iCloud Drive 的 `ipa/PokeSurvivor/`。

### 權利

這個客戶端沒有轉載遊戲本體。轉載或拿去收費之前先讀 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。不要加廣告或付費：精靈圖是 CC BY-NC 4.0，原作者也是免費的同人作品。

| 內容 | 誰的 | 條件 |
| --- | --- | --- |
| iOS 客戶端 | kv | 只有這個 repo 是 MIT |
| 遊戲程式 | [JPTER78](https://github.com/JPTER78/pokesurvivor) | MIT。這裡沒有複製，直接開 pokesurvivor.com |
| 精靈圖 | [SpriteCollab](https://github.com/PMDCollab/SpriteCollab) | CC BY-NC 4.0。這裡沒有複製 |
| 繁中譯文 | [Kai5106](https://greasyfork.org/zh-TW/scripts/599869) | 授權未標。使用者提供的 1.0.0 顯示譯文，收在 `Resources/zh-Hant.json`。名稱依 PokeAPI 繁中 |
| 譯文說明 | [usegametool](https://usegametool.blogspot.com/2026/10/pokesurvivor.html) | 指向該譯文的文章 |
| App icon | pokesurvivor.com | 原站的主畫面圖示，不在 MIT 程式授權裡 |
| Pokémon | Nintendo、Creatures、GAME FREAK、The Pokémon Company | 他們的商標。沒有任何官方關係 |
