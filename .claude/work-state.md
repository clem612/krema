# Work State (The Master Mind)

> **Role:** This file is the central hub for project coordination. It bridges sessions by tracking priorities, summarizing technical memory, and linking to deep-dive documentation.

## Knowledge Index
- **Architectural Truth:** [ARCHITECTURE Mandate.md](../ARCHITECTURE Mandate.md) (The mathematical constitution)
- **Technical Memory:** [docs/bugs_report.md](../docs/bugs_report.md) (Failed trials, root causes, and ironclad fixes)
- **Research Logs:** [docs/research/](../docs/research/) (Deep dives into math, protocols, and KWin issues)
## Current Milestone

**Phase 1: Foundational Architecture (v0.8.0)** ⬅️
*Focus: Completing the 3-Tier Mathematical Engine, workspace awareness, and layout modes.*

## Completed Items

- [x] M1-M8: Foundation stabilization, shaders, shadow clamping, and kinetic physics.
- [x] **Flatpak Identity Resolver:** Enhanced `IdentityManager` to automatically bridge short Wayland `app_id`s to reverse-DNS Flatpak identifiers, natively fixing icons and launcher URLs.
- [x] **Instance-Aware Active Indicators (Dynamic Dash):** Implemented shifting dash to represent focused window instance accurately across Hyprland and KDE via `KdeTasksProxyModel`.
- [x] **Flatpak Vector Icon Fix:** Removed strict `availableSizes().isEmpty()` checks from the icon rendering bridge, allowing scalable vector graphics (SVGs) to render successfully.
- [x] **Fuzzy Identity Resolver:** Updated suffix matching in Flatpak extractor to aggressively strip spaces and dashes, resolving "Aim Train" Wayland class vs Flatpak ID desyncs.
- [x] **Lua IPC Interception Fallback:** Resolved Hyprland context menu "Close" failure by rewriting raw socket dispatches to `hl.dsp.window.close()` when the user runs the `hyprland-lua-plugins` extension.
- [x] **Interaction Flooring Constitution:** Established 5-unit mathematical vertical stack `[LEGACY — migrating to 3-Tier]`.
- [x] **V1+V2 Document Merge:** Unified ARCHITECTURE Mandate (20 rules), ROADMAP (v0.8.0), and plans directory under V2's 3-Tier structure.
- [x] **Bug Sweep (#12, #18-#28):** Fixed autohide failure, Hyprland crashes, signal leaks, edge placement desyncs, missing flatpak SVGs, and lua IPC dispatches.
- [x] **Identity Bridge:** Resolved Wayland AppID mismatch via dynamic KService lookup (Rule 11).
- [x] **Hyprland Launch Fix:** Resolved application launch failure on Hyprland via direct KService execution.
- [x] **Absolute Sync:** Locked interaction boundaries 1:1 to visual icon pixels.
- [x] **Startup Gap Resolution:** Fixed recursive race condition via **State-Aware Layout**.
- [x] **Sticky Preview Fix:** Resolved interaction deadlocks via Trial 4 (Icon-Gated Visibility).
- [x] **UI Polish:** Resolved text overlaps (Rule 20) and restored Settings UI consistency.
- [x] **Edge Placement Fix:** Fixed settings geometry desync where Wayland window was stuck due to screen overrides.
- [x] **Configuration Desync Tracker:** Added `--debug-config` flag and override interception to track config mismatch bugs.
- [x] **Kinetic Zoom:** Implemented smoothed easing orbits (Rule 19).
- [x] **Preview Geometry Sync:** Resolved "Altitude Confusion" via Absolute Sync (Rule 17).

## Known Issues

- (None — Bugs #18-#25 all fixed on 2026-05-19)

## On Hold Items

- [ ] **Icon Sizing Regression Fix:** Bug is elusive. Shelved by user pending further reproducibility.
- [ ] **Placement Stabilization (Bug #9)**: Conflict during edge transitions.

## Active Tasks

- [ ] **M3: 3-Tier Migration:** Migrate current 5-Unit Stack to Panel → Island → Item hierarchy.
- [ ] **M10 Kickoff:** Design recursive container logic for Widgets (Rule 15).

## Session History

- **2026-05-23 (Session B):** Applied the Surgical Bug-Fix Protocol to resolve **Bug #28**. Discovered that the user's `hyprland-lua-plugins` extension intercepts standard `/dispatch closewindow address:` IPC socket commands. Added a fallback branch in `HyprlandIpc` that intercepts the Lua error and dynamically rewrites the socket string to `hl.dsp.window.close()`, successfully restoring the "Close" context menu action.
- **2026-05-23 (Session A):** Discovered that vector-based Flatpak icons (SVGs) were failing to render because they report an empty `availableSizes()` before rendering. Removed the strict check in the image bridge to pass SVGs successfully to QML.
- **2026-05-23 (Session A):** Updated the **Flatpak Identity Resolver** with extreme fuzzy suffix matching. Stripped spaces and dashes completely to match edge cases like `"aim train"` vs `io.gitlab.aimtrain.aimtrain.svg`.
- **2026-05-23 (Session A):** Implemented **Flatpak Direct Icon Extractor** in `TaskIconProvider`. Directly scans `~/.local/share/flatpak/` and `/var/lib/flatpak/` for icon assets on standalone window managers like Hyprland where `XDG_DATA_DIRS` might not be correctly populated, bridging the gap between flatpak apps and native rendering.
- **2026-05-23 (Session A):** Resolved **Flatpak Identity Mismatch**. Created a reverse-DNS caching resolver inside `IdentityManager` that scans `KService` via `StartupWMClass` and suffix matching. This bridges short Wayland classes (e.g. `stremio`) to Flatpak `.desktop` bundles (e.g. `com.stremio.Stremio`), inherently fixing missing Flatpak icons and middle-click launcher instances.
- **2026-05-23 (Session A):** Completed **Instance-Aware Active Indicators (Dynamic Dash)**. Injected `ActiveChildIndex` into `HyprlandTasksModel` and built `KdeTasksProxyModel` to safely adapt KDE's tree model into QML, accurately shifting the active dash to the focused window.
- **2026-05-20 (Session A):** Discovered and fixed the "Stuck at Bottom" Edge Placement bug. The UI was moving to global settings while the Wayland Window was blocked by a local screen override. Implemented the Configuration Desync Tracker (`--debug-config`) to instantly expose these state desyncs in the future.
- **2026-05-19 (Session C):** Raw code audit — found 8 bugs (#18-#25). Merged V1+V2 project documents: unified ARCHITECTURE Mandate (20 rules, 3-Tier structure), ROADMAP (v0.8.0 → v1.0.0), and plans directory. Promoted V2 plans, cleaned up duplicates, deleted v2 source files.
- **2026-05-19 (Session B):** Fixed Hyprland window grouping and identity crisis. Integrated `IdentityManager` into `HyprlandTasksModel` to properly extract `.desktop` identifiers from `launcherUrl` and Wayland `class` metadata. Restructured the `Task` model to support a `QList<WindowInfo>`, allowing the QML layer to accurately render indicator dots (`ChildCount`) and map multiple window instances to a single pinned application.
- **2026-05-19 (Session A):** Initiated Hyprland support. Created `HyprlandDockPlatform` to handle positioning on non-KDE compositors. Updated `DockPlatformFactory` to detect Hyprland sessions via `XDG_CURRENT_DESKTOP`.
- **2026-05-19 (Session A):** Fixed Hyprland application launching bug. Replaced `QDesktopServices::openUrl` with direct `KService` exec line parsing and `QProcess` execution. Verified `nwg-dock-hyprland` reference and implemented robust field code stripping.

- **2026-05-16 (Session A):** Cleaned up `ROADMAP.md`. Migrated granular bugs (#9, #10) to `docs/bugs_report.md`. Added **Instance-Aware Active Indicators (Dynamic Dash)** to Phase 2. Marked **Preview Geometry Sync** as completed. Updated `justfile` for development environment autostart. Added **Hyprland Support** to the roadmap backlog.

- **2026-05-14 (Session A):** Resolved **Dolphin/Settings Identity Crisis**. Unified AppID normalization via dynamic KService lookup, removing hardcoded bridges.

- **2026-05-14 (Session A):** Applied **Absolute Sync** to tooltips. Icon labels now track visual growth and center in real-time using `Calculated Reality` math.
- **2026-05-14 (Session A):** Resolved **RED 2 (Ghost Sheet Blur)**. Decoupled the blur region from the input region by introducing `setBlurRegion` to the platform interface. Blur is now strictly mapped to the visual panel size.
- **2026-05-14 (Session A):** Resolved **Ghost Popups** and **Settings Slider** synchronization. Implemented `IsWindow` gateway filters and the **Activation Guard** to prevent premature triggers from zoom animations. Consolidated preview math into the **Calculated Reality** system.
- **2026-05-12 (Session B):** Completed **Phase 2 Milestone 9**. Resolved **Sticky Previews** and interaction deadzones. Polished settings UI and codified **Rule 20 (Safe Spacing)**. Finalized **Strong Foundation** phase with memory-first synchronization.
- **2026-05-12 (Session A):** Definitive fix for **Startup Gaps** (State-Aware Layout). Identified **Signal Desync** and **Orbit Suffocation** as causes for zoom sluggishness.
- **2026-05-11 (Session B):** Definitive resolution of "Ghost Mouse" via **Absolute Sync**.

