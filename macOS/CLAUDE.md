# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

macOS port of a Windows C# RTS (real-time strategy) game, translated to Swift using SpriteKit for rendering. Actively in progress.

## Build & Run

- Open `Invasiones/Invasiones.xcodeproj` in Xcode
- Build: `xcodebuild -scheme Invasiones -project Invasiones/Invasiones.xcodeproj`
- Run: Cmd+R in Xcode
- Tests: `xcodebuild test -scheme Invasiones -project Invasiones/Invasiones.xcodeproj`

Debug builds show FPS/node count and run in windowed mode. Release builds run fullscreen.

## Architecture

### Frame Loop

```
GameScene.update(_:)          [SpriteKit callback, 20 FPS]
  → GameFrame.actualizar()    [loads resources on first frame]
  → MaquinaDeEstados          [state machine dispatcher]
  → Estado.actualizar()       [current state logic]
  → Estado.dibujar(Video)     [current state rendering]
  → Video.limpiar()           [clears SKNode canvas for next frame]
```

### State Machine

`MaquinaDeEstados` (`SM/`) manages all top-level game states:
- `EstadoLogo` → `EstadoMenuPpal` → `EstadoJuego` → `EstadoSalir`
- States implement `iniciar()`, `actualizar()`, `dibujar()`, `salir()`
- State transitions are queued and executed at start of next frame

### Active Battle: `EstadoJuego` → `Episodio`

`Episodio` (`Nivel/`) owns the complete battle session:

```
Episodio
├── Nivel          [objective tracker, loads nivel_N.xml]
├── Mapa           [isometric TMX tile map, multi-layer]
├── BandoArgentino [player forces]
│   └── Grupos → Unidades
├── BandoEnemigo   [AI forces]
│   └── Grupos → Unidades
└── IA             [enemy decision-making]
```

Battle lifecycle: `CARGANDO → MOSTRAR_INTRODUCCION → JUGANDO → GANO/PERDIO`

### Unit System

`Unidad` has stats (health, attack, resistance, visibility, aim, range, speed) and states: `OCIO`, `MOVIENDO`, `MURIENDO`, `ATACANDO`, `PERSIGUIENDO_UNIDAD`, `MUERTO`, `PATRULLANDO`, `SANANDO`.

`Grupo` wraps a squad of units. `Orden` is a single command. `Objetivo` is a stack of orders.

**Combat notes:**
- Damage is always `m_puntosDeAtaque` — no accuracy roll. `m_punteria` is loaded from CSV but was never used in the original C# attack logic.
- Enemy units without a group (`IA`) are set to `PATRULLANDO` state on load and wander randomly between `RANDOM_PATRULLA_MIN=8` and `RANDOM_PATRULLA_MAX=16` tiles from their base position.
- `ContraAtacar` (counter-attack): when a unit enters `ATACANDO`, it notifies the target to counter-attack if idle. Not yet ported to Swift.
- `EstadoLogo.iniciar()` is never called — the first state is set directly via `setearEstado()`, bypassing `iniciar()`. Sound and init code must go in `GameFrame.iniciarJuego()`.

### Rendering (`Video`)

`Video` wraps SpriteKit, presenting an SDL-compatible API to the rest of the game. It owns a `SKNode` canvas that is fully redrawn each frame. Coordinate origin is bottom-left `(0,0)` at 1024×768.

Input from `NSEvent` flows through `GameScene` into `Mouse` and `Teclado` singletons.

### Pathfinding

`PathFinder` (singleton) runs A* on the physical tile grid (2× map resolution). 4.5-second timeout for long calculations. Costs: 10 orthogonal, 14 diagonal.

### Resources

`AdministradorDeRecursos` (singleton) loads and caches all assets from `data/res.xml`:
- Images, fonts, sprites, animation CSVs, unit type templates
- `Res` contains generated integer constants for resource indices
- `Texto` loads localised strings from `data/strings.xml`

## Conventions

**Language:** All code, comments, and identifiers are in Spanish.

**Key vocabulary:**
| Spanish | English |
|---|---|
| `Unidad` | Unit (soldier) |
| `Grupo` | Group / Squad |
| `Mapa` | Map |
| `Orden` | Order / Command |
| `Objetivo` | Objective |
| `Bando` | Side / Faction |
| `Nivel` | Level |
| `Episodio` | Battle session |
| `Estado` | State |
| `Instancia` | Singleton accessor |

**Member naming:** private members prefixed `m_` (carried over from C# original).

**Singletons:** accessed via `Foo.Instancia` (e.g., `PathFinder.Instancia`, `Log.Instancia`).

## Data Files (`data/`)

| Path | Purpose |
|---|---|
| `res.xml` | Resource manifest (all asset paths) |
| `strings.xml` | Localised text |
| `nivel/nivel_N.xml` | Level definitions (objectives, units, orders) |
| `unidades/*.csv` | Unit animation frame data |
| `imagenes/` | PNG sprites and UI assets |
| `fuentes/` | TTF font files |
