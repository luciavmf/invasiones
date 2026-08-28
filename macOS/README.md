# Invasiones macOS port

[![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey?logo=apple)](https://developer.apple.com/macos/)
[![Status](https://img.shields.io/badge/status-work%20in%20progress-yellow)]()
[![macOS Build](https://github.com/luciavmf/invasiones/actions/workflows/macos-build.yml/badge.svg)](https://github.com/luciavmf/invasiones/actions/workflows/macos-build.yml)

This is a port of the original Windows game (`Juego/`) to macOS, built with Swift and SpriteKit.

## ⬇️ Download

Every push to `main` builds, signs, and notarizes the app, then publishes it as a DMG on the [latest release](https://github.com/luciavmf/invasiones/releases/tag/latest-macos-build).

The original game was written in C# for Windows, with all code in Spanish (`Unidad`, `Grupo`, `Mapa`, `Orden`, etc.). This port translates everything to English and adapts the SDL-based rendering and input systems to native macOS APIs via SpriteKit.

The port is being developed with the assistance of [Claude Code](https://claude.ai/code), Anthropic's AI coding tool, which is helping with the translation from C# to Swift, debugging, and Swiftification of the codebase.

## 📐 Coding conventions

Swift code follows the official [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/). The codebase is being progressively updated toward full compliance as part of the Swiftification effort.

## ✅ Swiftification progress

The codebase is being progressively updated toward full Swift API Design Guidelines compliance. Completed so far:

- ✅ `m_` prefix removal from all private properties
- ✅ Singleton pattern: `static let shared = Foo()`
- ✅ Setter methods replaced with `didSet` observers
- ✅ `NSObject` removed where conformance was unused
- ✅ Argument labels added to game-logic functions
- ✅ C# XML doc comments restored as Swift `///` comments in English
- ✅ `Int16` → `Int` throughout
- ✅ Value types converted to `struct` (`Tile`, `Command`, `Objective`)
- ✅ SCREAMING_CASE enum names/cases → Swift convention (PascalCase types, lowerCamelCase cases)
- ✅ `FontIndex` and `Direction` enums moved to top level
- ✅ SCREAMING_CASE `static let` / `let` constants → `lowerCamelCase` across all files
- ✅ `throws` instead of `Bool` return values for error propagation

## 🎮 Cheat codes

Cheats are only active during gameplay (not in menus). Each code is entered one key at a time — pressing any other key resets all sequences.

| Sequence | Effect |
|----------|--------|
| <kbd>G</kbd> <kbd>A</kbd> <kbd>N</kbd> <kbd>X</kbd> <kbd>W</kbd> | 🏆 Instant win — jumps to the victory screen |
| <kbd>P</kbd> <kbd>E</kbd> <kbd>R</kbd> <kbd>X</kbd> <kbd>W</kbd> | 💀 Instant lose — jumps to the game over screen |
| <kbd>O</kbd> <kbd>B</kbd> <kbd>J</kbd> <kbd>X</kbd> <kbd>W</kbd> | ⏭️ Skip objective — advances to the next objective immediately |

Additionally, pressing <kbd>U</kbd> at any time during gameplay cycles the camera to the next Argentine unit.

## 📁 Data files

Game data lives in `Invasiones/data/`:

| File | Format | Purpose |
|------|--------|---------|
| `res.json` | JSON | Resource manifest — all asset paths, sprite and animation definitions |
| `strings.json` | JSON | Localised text strings, keyed by English snake_case identifiers |
| `nivel/nivel_N.xml` | XML | Level definitions (objectives, units, starting orders) |
| `nivel/orden_nv*.xml` | XML | Scripted AI movement orders |
| `unidades/*.csv` | CSV | Unit animation frame data |

`res.json` and `strings.json` replaced the original `res.xml` and `strings.xml` from the C# version. Map and level files remain XML because they use the [Tiled](https://www.mapeditor.org/) format (`.tmx`/`.tsx`).

## 🌐 Other ports

- 🕸️ **TypeScript (web)** — another port in progress using PixiJS for rendering.

## 🤖 Continuous integration

`.github/workflows/macos-build.yml` (repo root) builds, signs, and notarizes the app on every push to `main` that touches `macOS/**`, then publishes the DMG to the rolling [`latest-macos-build`](https://github.com/luciavmf/invasiones/releases/tag/latest-macos-build) release. It uses `Invasiones.xcodeproj`'s shared `Invasiones` scheme (`xcshareddata/xcschemes/`) and `macOS/ci/exportOptions.plist` (Developer ID, manual signing, team `44DMMFA3SQ`).

To enable it, add these secrets under **Settings → Secrets and variables → Actions** in the GitHub repo:

| Secret | How to get it |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | In Keychain Access, export your **Developer ID Application** certificate (with private key) as a `.p12`, then run `base64 -i cert.p12 \| pbcopy` and paste the result. |
| `P12_PASSWORD` | The password you set when exporting the `.p12`. |
| `KEYCHAIN_PASSWORD` | Any random string — used only to protect the temporary CI keychain for the run. |
| `APPLE_ID` | Your Apple ID email (must be a member of the `44DMMFA3SQ` team). |
| `APPLE_APP_SPECIFIC_PASSWORD` | Generate one at [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords. Used for `notarytool`, not your real Apple ID password. |

Once the secrets are set, push to `main` (or run the workflow manually from the Actions tab) to trigger a build.
