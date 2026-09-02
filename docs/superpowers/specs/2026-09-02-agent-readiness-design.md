# Agent Readiness Design

## Goal

Give coding agents one repository-level entry point that directs routine work to the active macOS port without obscuring the original game as a behavioral reference.

## Decisions

- Add a root `AGENTS.md` as the canonical cross-agent instruction file.
- Treat `macOS/` as the active Swift 6 and SpriteKit product.
- Treat `Juego/Invasiones/fuente/` as read-only behavioral reference unless a task explicitly targets the legacy Windows game.
- Keep `macOS/CLAUDE.md` intact as the detailed architecture and conventions document, and link to it instead of duplicating it.

## Required Guidance

The root guide must identify the project layout, give reproducible root-relative build and test commands, protect generated and binary artifacts, preserve the data-file conventions, and require an appropriate build or test before handoff.

## Validation

Validate the new guide as Markdown, inspect its documented paths and commands, and run the macOS test command when the local Xcode environment permits it.
