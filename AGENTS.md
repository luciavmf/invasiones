# Invasiones Agent Guide

## Active Project

The active product is the macOS Swift/SpriteKit port in `macOS/`.
Start with [`macOS/CLAUDE.md`](macOS/CLAUDE.md) for the game architecture, coding conventions, resource-loading rules, and porting notes. Those instructions apply regardless of which coding agent is used.

The original C# game is in `Juego/Invasiones/fuente/`. Treat it as the authoritative behavioral reference when porting or checking gameplay logic, but do not modify it unless the task explicitly targets the legacy Windows version.

## Build and Test

Run these commands from the repository root:

```sh
xcodebuild -scheme Invasiones -project macOS/Invasiones/Invasiones.xcodeproj build
xcodebuild -scheme Invasiones -project macOS/Invasiones/Invasiones.xcodeproj test
```

Use the smallest relevant test target while developing; run the appropriate build or test command before handoff. Do not trust SourceKit "Cannot find type … in scope" messages by themselves: confirm them with `xcodebuild` first.

## Working Conventions

- Write Swift code, comments, and identifiers in English, following the existing style.
- Preserve the Spanish names used by the XML data format. In particular, changing names such as `<unidad>` or `<animacion>` breaks resource loading without a compiler error.
- Keep gameplay changes aligned with the C# reference unless the task deliberately changes behavior.
- Prefer focused edits. Do not reformat unrelated Swift files or modify generated Xcode user data.
- Avoid editing binary assets, legacy installer projects, or bundled tools unless they are explicitly in scope.
- When adding source files, ensure they are included in the Xcode project or target as required by the current project structure.

## Repository Layout

- `macOS/Invasiones/`: Swift application and test targets.
- `macOS/data/`: port resources, maps, strings, and asset metadata.
- `Juego/Invasiones/fuente/`: original C# game source (reference implementation).
- `Juego/Invasiones/data/`: original Windows game data.
- `Instalador/`, `Herramientas/`, and `Productos Software/`: historical installer, third-party tools, and project documentation; leave untouched unless explicitly requested.

## Handoff

Before reporting a task complete, inspect the diff, state which validation command ran and its result, and call out anything that could not be verified locally.
