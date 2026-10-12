# Third-party notices

This repository is an unofficial, non-commercial iOS client. It does not contain the game.

## PokéSurvivor

- Author: [JPTER78](https://github.com/JPTER78)
- Game: [https://pokesurvivor.com/](https://pokesurvivor.com/)
- Source: [https://github.com/JPTER78/pokesurvivor](https://github.com/JPTER78/pokesurvivor)
- Code license: MIT, Copyright (c) 2026 JPTER78, for `js/`, `css/`, `index.html`, `tools/`, and the music in `js/data/music.js`
- This client does not copy that code. It loads the published site so cloud saves, accounts, and the author's updates stay on the domain Firebase already allows.

## Art and data used by the game (not bundled here)

- Pokémon sprites: [SpriteCollab](https://github.com/PMDCollab/SpriteCollab), CC BY-NC 4.0. Non-commercial, with attribution. Artist list: `CREDITS.md` in the game repo.
- Font: Pixelify Sans, SIL Open Font License 1.1, shipped by the game.
- Pokédex data: [PokeAPI](https://pokeapi.co/).
- These files are not in this repository. The app shows them only by loading pokesurvivor.com.

## App icon

The home-screen icon is the game's published icon (`https://pokesurvivor.com/assets/icons/icon-512.png`), scaled with nearest-neighbor. It is not included in the MIT code grant. See `Resources/ICON-SOURCE.txt`.

## Traditional Chinese patch

- Author: [Kai5106](https://greasyfork.org/zh-TW/users/1652257-kai5106)
- Script: [PokéSurvivor 繁體中文補丁](https://greasyfork.org/zh-TW/scripts/599869) version 1.0.0
- Install URL: `https://update.greasyfork.org/scripts/599869/Pok%C3%A9Survivor%20%E7%B9%81%E9%AB%94%E4%B8%AD%E6%96%87%E8%A3%9C%E4%B8%81.user.js`
- Guide: [usegametool](https://usegametool.blogspot.com/2026/10/pokesurvivor.html)
- Greasy Fork lists the license as unspecified. This repo therefore does not contain the script. The app downloads it onto the device when the setting is on, checks the userscript header, and refuses copies that add `@require`, a grant other than `none`, or network/storage calls that were not in the reviewed 1.0.0 script.
- Name data in the patch follows PokeAPI Traditional Chinese. UI lines are Kai5106's translation.

## Trademarks

Pokémon and all related names, characters, and the Poké Ball design are trademarks and property of Nintendo, Creatures Inc., GAME FREAK inc. and The Pokémon Company. PokéSurvivor is a free fan project. This client is not affiliated with, endorsed, or made by them, or by JPTER78. No ads. No purchases.
