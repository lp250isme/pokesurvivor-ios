# PokéSurvivor iOS

[English](#english) | [繁體中文](#繁體中文)

Unofficial, non-commercial iOS client for the fan game [PokéSurvivor](https://pokesurvivor.com/). The game stays on the author's site. A setting injects [Kai5106's Traditional Chinese patch](https://greasyfork.org/zh-TW/scripts/599869).

## English

### What this is

A landscape iOS app that opens `https://pokesurvivor.com/` in a full-screen web view: no browser bar, screen stays awake, login and cloud saves stay on the original site, and the Traditional Chinese patch can be turned off in Settings.

The gear in the corner opens Settings. It fades after a few seconds and stays tappable.

### Install

The GitHub Release IPA is unsigned. Sign it with your own Apple ID:

- AltStore, SideStore, or Feather: import the IPA
- Sideloadly: open the IPA and install

A free Apple ID signature expires in about 7 days. Refresh it with the same tool. iOS 17 or later. iPhone and iPad. The game plays in landscape.

Google sign-in may be blocked inside the app. Email and guest play work. Settings has "在 Safari 開啟原站" when a Google account is required.

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
| zh-Hant patch | [Kai5106](https://greasyfork.org/zh-TW/scripts/599869) | License unspecified. Downloaded on device, not stored in git |
| Patch guide | [usegametool](https://usegametool.blogspot.com/2026/10/pokesurvivor.html) | The blog that points at the script |
| App icon | pokesurvivor.com | Original home-screen icon. Not MIT code |
| Pokémon | Nintendo, Creatures, GAME FREAK, The Pokémon Company | Their trademarks. Not affiliated |

## 繁體中文

### 這是什麼

把 [PokéSurvivor](https://pokesurvivor.com/) 包成橫向全螢幕 App。沒有網址列，螢幕不會自己暗掉，帳號和雲端存檔仍在原站。設定裡可以開關 [Kai5106 的繁體中文補丁](https://greasyfork.org/zh-TW/scripts/599869)。

右上角齒輪是設定，幾秒後變淡，還是點得到。

### 安裝

GitHub Release 的 IPA 沒有簽章，要用你自己的 Apple ID 簽：

- AltStore、SideStore、Feather：匯入 IPA
- Sideloadly：打開 IPA 安裝

免費 Apple ID 的簽章大約 7 天，用同一個工具重新整理。需要 iOS 17 以上，iPhone 與 iPad 都可以。遊戲是橫向。

App 裡的「使用 Google 登入」可能被 Google 拒絕。帳號密碼和訪客可以玩。一定要用 Google 時，設定裡有「在 Safari 開啟原站」。

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
| 繁中補丁 | [Kai5106](https://greasyfork.org/zh-TW/scripts/599869) | 授權未標。只下載到裝置，不進 git |
| 補丁說明 | [usegametool](https://usegametool.blogspot.com/2026/10/pokesurvivor.html) | 指向該腳本的文章 |
| App icon | pokesurvivor.com | 原站的主畫面圖示，不在 MIT 程式授權裡 |
| Pokémon | Nintendo、Creatures、GAME FREAK、The Pokémon Company | 他們的商標。沒有任何官方關係 |
