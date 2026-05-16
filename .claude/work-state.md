# Work State (The Master Mind)

> **Role:** This file is the central hub for project coordination. It bridges sessions by tracking priorities, summarizing technical memory, and linking to deep-dive documentation.

## Knowledge Index
- **Architectural Truth:** [ARCHITECTURE Mandate.md](../ARCHITECTURE Mandate.md) (The mathematical constitution)
- **Technical Memory:** [docs/bugs_report.md](../docs/bugs_report.md) (Failed trials, root causes, and ironclad fixes)
- **Research Logs:** [docs/research/](../docs/research/) (Deep dives into math, protocols, and KWin issues)
## Current Milestone

**Milestone 9: Visual Engine & Foundation Polish** ⬅️
*Focus: Volumetric shadows, coordinate sync, and Dynamic Dash system.*

## Completed Items

- [x] M1-M8: Foundation stabilization, shaders, shadow clamping, and kinetic physics.
- [x] **Interaction Flooring Constitution:** Established 5-unit mathematical vertical stack (Rule 17).
- [x] **Identity Bridge:** Resolved Wayland AppID mismatch via dynamic KService lookup (Rule 11).
- [x] **Absolute Sync:** Locked interaction boundaries 1:1 to visual icon pixels.
- [x] **Startup Gap Resolution:** Fixed recursive race condition via **State-Aware Layout**.
- [x] **Sticky Preview Fix:** Resolved interaction deadlocks via Trial 4 (Icon-Gated Visibility).
- [x] **UI Polish:** Resolved text overlaps (Rule 20) and restored Settings UI consistency.
- [x] **Kinetic Zoom:** Implemented smoothed easing orbits (Rule 19).
- [x] **Preview Geometry Sync:** Resolved "Altitude Confusion" via Absolute Sync (Rule 17).

## Known Issues

- (None)

## On Hold Items

- [ ] **Window Preview Layering**: Icon thumbnails cover the context menu.
- [ ] **Icon Sizing Regression Fix:** Bug is elusive. Shelved by user pending further reproducibility.
- [ ] **Placement Stabilization (Bug #9)**: Conflict during edge transitions.
- [ ] **Vertical Indicator Flow (Bug #10)**: Dot wrapping in vertical mode.

## Active Tasks

- [ ] **Instance-Aware Active Indicators (Dynamic Dash):** Implement shifting dash to represent focused window instance.
- [ ] **Autohide & Auto-Dodge Fix:** Investigate `DockVisibilityController` interaction locks and Wayland signal desync.
- [ ] **M10 Kickoff:** Design recursive container logic for Widgets (Rule 13).

## Session History

- **2026-05-16 (Session A):** Cleaned up `ROADMAP.md`. Migrated granular bugs (#9, #10) to `docs/bugs_report.md`. Added **Instance-Aware Active Indicators (Dynamic Dash)** to Phase 2. Marked **Preview Geometry Sync** as completed. Updated `justfile` for development environment autostart. Added **Hyprland Support** to the roadmap backlog.
- **2026-05-14 (Session A):** Resolved **Dolphin/Settings Identity Crisis**. Unified AppID normalization via dynamic KService lookup, removing hardcoded bridges.

- **2026-05-14 (Session A):** Applied **Absolute Sync** to tooltips. Icon labels now track visual growth and center in real-time using `Calculated Reality` math.
- **2026-05-14 (Session A):** Resolved **RED 2 (Ghost Sheet Blur)**. Decoupled the blur region from the input region by introducing `setBlurRegion` to the platform interface. Blur is now strictly mapped to the visual panel size.
- **2026-05-14 (Session A):** Resolved **Ghost Popups** and **Settings Slider** synchronization. Implemented `IsWindow` gateway filters and the **Activation Guard** to prevent premature triggers from zoom animations. Consolidated preview math into the **Calculated Reality** system.
- **2026-05-12 (Session B):** Completed **Phase 2 Milestone 9**. Resolved **Sticky Previews** and interaction deadzones. Polished settings UI and codified **Rule 20 (Safe Spacing)**. Finalized **Strong Foundation** phase with memory-first synchronization.
- **2026-05-12 (Session A):** Definitive fix for **Startup Gaps** (State-Aware Layout). Identified **Signal Desync** and **Orbit Suffocation** as causes for zoom sluggishness.
- **2026-05-11 (Session B):** Definitive resolution of "Ghost Mouse" via **Absolute Sync**.

