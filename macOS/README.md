# Invasiones port

[![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey?logo=apple)](https://developer.apple.com/macos/)
[![Status](https://img.shields.io/badge/status-work%20in%20progress-yellow)]()

This is a port of the original Windows game (`Juego/`) to macOS, built with Swift and SpriteKit.

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
