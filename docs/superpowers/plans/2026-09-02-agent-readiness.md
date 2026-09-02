# Agent Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a repository-root guide that lets coding agents work safely on the active macOS port.

**Architecture:** `AGENTS.md` is the short, tool-agnostic entry point. It delegates detailed architecture and game-specific conventions to the existing `macOS/CLAUDE.md`, avoiding duplicated knowledge.

**Tech Stack:** Markdown, Swift 6, SpriteKit, Xcode/xcodebuild.

**Spec:** `docs/superpowers/specs/2026-09-02-agent-readiness-design.md`

## Global Constraints

- The active product is `macOS/`; `Juego/Invasiones/fuente/` is a reference unless explicitly in scope.
- Do not translate Spanish XML element or attribute names in data files.
- Verify a change with an appropriate `xcodebuild` command before handoff.

---

### Task 1: Create the repository agent guide

**Files:**
- Create: `AGENTS.md`
- Reference: `macOS/CLAUDE.md`

**Interfaces:**
- Consumes: repository layout and development commands documented in `macOS/CLAUDE.md`.
- Produces: a root-level, tool-agnostic operating guide for coding agents.

- [ ] **Step 1: Add the root guide**

Include the active-project boundary, reference-source policy, root-relative build/test commands, data constraints, safe edit boundaries, and handoff verification rule.

- [ ] **Step 2: Verify paths and commands**

Run: `test -f AGENTS.md && test -f macOS/CLAUDE.md && test -f macOS/Invasiones/Invasiones.xcodeproj/project.pbxproj`

Expected: exit status 0.

- [ ] **Step 3: Run the macOS tests**

Run: `xcodebuild test -scheme Invasiones -project macOS/Invasiones/Invasiones.xcodeproj`

Expected: the selected Xcode destination builds and tests the Swift port.

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md docs/superpowers
git commit -m "docs: add agent repository guidance"
```
