# Work State (The Master Mind)

> **Role:** This file is the central hub for project coordination. It bridges sessions by tracking priorities, summarizing technical memory, and linking to deep-dive documentation.

## Knowledge Index
- **Architectural Truth:** [ARCHITECTURE Mandate.md](../ARCHITECTURE Mandate.md) (The mathematical constitution)
- **Technical Memory:** [docs/bugs_report.md](../docs/bugs_report.md) (Failed trials, root causes, and ironclad fixes)
- **Research Logs:** [docs/research/](../docs/research/) (Deep dives into math, protocols, and KWin issues)

## Current Milestone

M8 Completed → **M9: Modular System (Widgets & Tray)**
*Focus: Rule 13 (Island Protocol) and Rule 14 (Coupling Lock).*

## Completed Items

- [x] M1-M8: Core Foundation & Multi-Monitor Support.
- [x] **Interaction Flooring Constitution:** Established 5-unit mathematical vertical stack (Rule 17).
- [x] **Absolute Sync:** Locked interaction boundaries 1:1 to visual icon pixels.
- [x] **Startup Gap Resolution:** Fixed recursive race condition via **State-Aware Layout**.

## Known Issues

- **Dolphin/Settings Identity Crisis**: Wayland App ID mismatch.
- **Zoom Scale Reactivity**: Sluggish updates at low scales; 1.0x fails to persist while Settings is open.

## On Hold Items

- [ ] **Ghost Gaps**: Linked to App ID mismatch.
- [ ] **Zoom Orbit Suffocation**: 1.0x/1.1x scales are "click-through" while Settings window is open. Current hypothesis: **Wayland Surface Layer Conflict** in `liveEditMode`.
- [ ] **Window Preview Layering**: Icon thumbnails cover the context menu.

## Active Tasks

- [ ] **M9 Kickoff:** Design recursive container logic for Widgets (Rule 13).
- [ ] **Geometry Audit:** Investigate `WaylandDockPlatform` input region mapping during `liveEditMode`.

## Session History

- **2026-05-12 (Session B):** Codified **Rule 17 (The Unit Mandate)** to formalize the 5-unit vertical stack. Attempted fix for **Orbit Suffocation** via stability fallbacks, but reverted the code changes as they were deemed unnecessary/ineffective. Rule 17 remains as a documentation mandate for unit-based variables.
- **2026-05-12 (Session A):** Definitive fix for **Startup Gaps** (State-Aware Layout). Identified **Signal Desync** and **Orbit Suffocation** as causes for zoom sluggishness.
- **2026-05-11 (Session B):** Definitive resolution of "Ghost Mouse" via **Absolute Sync**.
- **2026-05-11 (Session A):** Reorganized documentation. established `work-state.md` as the Master Mind.
