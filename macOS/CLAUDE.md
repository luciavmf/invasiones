# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

macOS port of a Windows C# RTS (real-time strategy) game, translated to Swift using SpriteKit for rendering. The original C# source lives at `../../Juego/Invasiones/fuente/` and is the authoritative reference for game logic and documentation.

## Build & Run

- Open `Invasiones/Invasiones.xcodeproj` in Xcode
- Build: `xcodebuild -scheme Invasiones -project Invasiones/Invasiones.xcodeproj`
- Run: Cmd+R in Xcode
- Tests: `xcodebuild test -scheme Invasiones -project Invasiones/Invasiones.xcodeproj`

Debug builds show FPS/node count and run in windowed mode. Release builds run fullscreen.

## Architecture

### Frame Loop

```
GameScene.update(_:)       [SpriteKit callback, 20 FPS]
  → GameFrame.update()     [dispatches to state machine]
  → StateMachine.update()  [handles pending transitions, calls current state]
  → State.update()         [current state logic]
  → State.draw(Video)      [current state rendering]
  → Video.clear()          [removes all SKNodes for next frame]
```

### State Machine

`StateMachine` (`StateMachiche/`) manages top-level game states:
- `LogoState` → `MainMenuState` → `GameState` → `ExitState`
- States implement `start()`, `update()`, `draw()`, `exit()`
- `setNextState()` queues a transition; it executes at the start of the next `update()` call
- `setState()` switches immediately without calling `exit()`/`start()` — used only for the initial state
- `LogoState.start()` is **never called** — the first state is set via `setState()`, bypassing `start()`. Init code must go in `GameFrame.startGame()`

### Active Battle: `GameState` → `Episode`

`Episode` (`Level/`) owns the complete battle session:

```
Episode
├── Level           [objective tracker, loads nivel_N.xml]
├── Map             [isometric TMX tile map, multi-layer]
├── ArgentineTeam   [player forces]
│   └── Groups → Units
├── EnemyTeam       [AI forces]
│   └── Groups → Units
└── IA              [enemy decision-making]
```

Battle lifecycle: `LOADING → SHOW_INTRO → PLAYING → WON/LOST`

### Unit System

`Unit` has stats (health, attack, resistance, visibility, aim, range, speed) and states: `IDLE`, `MOVING`, `DYING`, `ATTACKING`, `CHASING`, `DEAD`, `PATROLLING`, `HEALING`.

`Group` wraps a squad of units. `Command` is a single order. `Objective` is a stack of commands.

**Combat notes:**
- Damage is always `attackPoints` — no accuracy roll. `aim` is loaded from CSV but was never used in the original C# attack logic.
- Enemy units without a group (`IA`) are set to `PATROLLING` on load and wander randomly between `RANDOM_PATRULLA_MIN=8` and `RANDOM_PATRULLA_MAX=16` tiles from their spawn position.
- Counter-attack (`contraAtacar`): when a unit enters `ATTACKING`, it notifies the target to counter-attack if idle. **Not yet ported to Swift.**

### Rendering (`Video`)

`Video` wraps SpriteKit with an SDL-style API. It owns a `SKNode` canvas that is fully rebuilt each frame (all nodes removed in `clear()`, re-added in `draw()`). Coordinate origin is bottom-left `(0,0)` at `Video.width × Video.height` (1024×768).

Screen dimensions live on `Video` as `Video.width` / `Video.height` — do not add a separate constants file for these.

Input from `NSEvent` flows through `GameScene` into `Mouse` and `Keyboard` singletons.

### Pathfinding

`PathFinder` (singleton) runs A* on the physical tile grid (2× map resolution). 4.5-second timeout for long calculations. Costs: 10 orthogonal, 14 diagonal.

### Resources

`ResourceManager` (singleton, `static let shared`) loads and caches all assets from `data/res.xml`:
- Images → `Surface` (wraps `SKTexture`)
- Fonts → `GameFont`
- Sprites → `Sprite` (collection of `Animation` objects)
- Animation metadata → `Animation` (sprite sheet controller)
- Unit type templates → `Unit`

`Res` contains integer constants for all resource indices (images, sounds, strings, animations, tiles).

`GameText` loads localised strings from `data/strings.xml`.

### res.xml Parsing — Critical Gotcha

`res.xml` uses **Spanish element names** that must match exactly in the XML parsers:
- `<unidad>` (not `<unit>`) — unit file references
- `<animacion>` (not `<animation>`) — animation definitions in `<anims>`

Translating these element name strings will silently break loading (no compile error).

## Swiftify Progress

The codebase has been progressively Swiftified from the C# port style. Completed:
1. `m_` prefix removal from all private properties
2. Singleton pattern: `static let shared = Foo()` (was lazy `private static var instance`)
3. Setter methods → `didSet` observers (Tileset, Menu)
4. `NSObject` removed from `ResourceManager` (conformance was unused)
5. Column-alignment padding spaces removed throughout
6. Argument labels added to game-logic functions (removing `_` suppression)
7. C# XML doc comments restored as Swift `///` comments in English
8. `Int16` → `Int` throughout (`Tile`, `Tileset`, `Map`, `PathFinder`, `Obstacle`, `Player`, `ArgentineTeam`, `EnemyTeam`)

In progress / not yet done:
- `throws` instead of `Bool` returns
- `struct` for value types (`Tile`, etc.)
- Raw `Int` constants → typed Swift enums

## Conventions

**Language:** All code, comments, and identifiers are in English. `res.xml` and data files remain in Spanish — do not translate XML element/attribute names.

**Key vocabulary (C# → Swift):**
| C# (Spanish) | Swift (English) |
|---|---|
| `Unidad` | `Unit` |
| `Grupo` | `Group` |
| `Mapa` | `Map` |
| `Orden` | `Command` |
| `Objetivo` | `Objective` |
| `Bando` | Team (Argentine/Enemy) |
| `Nivel` | `Level` |
| `Episodio` | `Episode` |
| `Estado` | `State` |
| `MaquinaDeEstados` | `StateMachine` |
| `Superficie` | `Surface` |
| `Fuente` | `GameFont` |
| `Texto` | `GameText` |

**Singletons:** accessed via `Foo.shared` (e.g., `ResourceManager.shared`, `Log.shared`, `PathFinder.shared`).

**SourceKit false positives:** Xcode's indexer frequently shows "Cannot find type X in scope" errors after edits. These are **always** false positives in this project — a clean `xcodebuild` produces zero errors. Do not act on SourceKit diagnostics without verifying with a real build.

## Web Port

A complete TypeScript/PixiJS port lives at https://github.com/luciavmf/invasiones-web. It mirrors this codebase 1-to-1 with these differences:

- Rendering: PixiJS v8 instead of SpriteKit. `Video` wraps a `PIXI.Container` canvas rebuilt each frame.
- Coordinate origin: top-left (Y down), matching C#/SDL — no Y-flip needed unlike SpriteKit.
- Resource manifest: `data/res.json` replaces `data/res.xml` (same structure, JSON format).
- String tables: `data/strings_es.json` / `strings_en.json` / `strings_de.json` replace `data/strings.xml`.
- All loading is async (`fetch` + `DOMParser` / `PIXI.Assets`).
- No `Log`, `GameError`, `Utils`, `AppDelegate`, `ViewController`, or `GameScene` — browser equivalents used directly.
- `erasableSyntaxOnly` TypeScript config: no `enum`, uses `const` objects + type aliases.
- Episode loading uses an `asyncBusy` guard because `update()` is fire-and-forget in the PixiJS ticker.
- `Animation.clone()` creates an independent `Surface` (same GPU texture source, independent clip state) so cloned units don't share animation clip state.

## Data Files (`data/`)

| Path | Purpose |
|---|---|
| `res.xml` | Resource manifest (all asset paths, sprite/animation definitions) |
| `strings.xml` | Localised text strings |
| `nivel/nivel_N.xml` | Level definitions (objectives, units, starting orders) |
| `unidades/*.csv` | Unit animation frame data |
| `imagenes/` | PNG sprites and UI assets |
| `fuentes/` | TTF font files |
