# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

RetzerCrosshair is a World of Warcraft addon for Midnight (Interface 120000). It renders a ring + full-screen crosshair lines centered on the mouse cursor, optionally only in combat.

## Deploy

```bash
./deploy.sh    # rsync src/ → WoW AddOns/RetzerCrosshair/
./watch.sh     # auto-deploy on file changes (requires inotify-tools)
```

No build step. Edit files in `src/`, deploy, `/reload` in-game. Open settings with `/rch`.

## Architecture

**Load order** (defined in `RetzerCrosshair.toc`):

1. `libs/LibStub.lua` — standard WoW lib registry
2. `libs/RetzerUI-1.0.lua` — shared settings UI library (also used by retzer-plates)
3. `RetzerCrosshair.lua` — core logic; writes `NS.SCHEMA`, `NS.db`, `NS.ApplyAll` to the addon namespace
4. `Options.lua` — settings window; reads from namespace, writes `NS.ToggleOptions`

All files share a single addon namespace table via `local _, NS = ...` (WoW passes the same table to every file in the addon).

**Frame structure:**

- **Outer frame** (`RetzerCrosshairFrame`) — covers UIParent, drives `OnUpdate`, shown/hidden by `UpdateVisibility()`
- **Visual frame** — child of outer frame, owns all `CreateLine` objects. A single `Hide()` suppresses everything during mouselook.
- **Ring** — 48 line segments with half-segment overlap on each end to prevent gaps from flat line caps
- **4 cardinal lines** — from ring edge to screen boundary

**Config flow:**

- `SCHEMA` in `RetzerCrosshair.lua` is the single source of truth for defaults and UI
- `InitDB()` seeds `RetzerCrosshairDB` from `SCHEMA` on `ADDON_LOADED`
- `NS.db` is set after `InitDB()` so `Options.lua` can reference it lazily (frame built on first `/rch`)
- `NS.ApplyAll` calls `ApplyColor()` + `ApplyThickness()` + `UpdateVisibility()` — call this after any `db.settings` change

**RetzerUI-1.0** (`libs/RetzerUI-1.0.lua`):

- LibStub library shared with retzer-plates. Copy changes to both repos.
- `RUI:BuildOptionsFrame(opts)` auto-generates a tabbed settings window from a schema. Widget type is inferred from `default`: boolean → checkbox, number+min → slider, `{r,g,b}` table → color picker, string+`choices` → dropdown.
- Schema entries: `{ key, default, label, [min, max, step], [choices], [reload], [hidden] }`

## Key invariants

- `db` is only valid after `ADDON_LOADED`. Never access `db` or `NS.db` at file-load time.
- Settings are nested: `db.settings.<key>` (not flat).
- Default values in the table are only applied to new installations; existing `RetzerCrosshairDB` keeps its values. Use Reset Section in the UI to revert.
