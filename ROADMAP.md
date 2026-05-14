# Krema Development Roadmap

> A lightweight, modular dock for KDE Plasma 6. 
> **Source of Truth:** [ARCHITECTURE Mandate.md](ARCHITECTURE%20Mandate.md)
>
> The spiritual successor to Latte Dock, defined by performance, continuous curvature, and "Everything is a Module" architecture. Krema honors the legacy of Latte while establishing a unique identity focused on modularity and premium visual standards.

---

## Phase 1: Completed Foundation (v0.7.0)
- **Foundation:** C++23, LayerShellQt, DockModel (LibTaskManager).
- **Core UI:** Parabolic zoom, Indicator dots, Tooltips.
- **Persistence:** KConfig-based settings, Context menu, Keyboard shortcuts.
- **Interaction:** Drag & Drop, Window Previews (PipeWire), Pixel-Perfect 2D Hit-testing.
- **Visuals:** Basic background styles (Acrylic, Mica, Adaptive), Attention animations.
- **Multi-Monitor Core:** Follow Active mode, Virtual Desktop filtering.

---

## Phase 2: Refinement & The "Everything is a Module" Pivot (Current)

### Milestone 9: Visual Engine & Foundation Polish (Current Priority) ⬅️
- [ ] **Advanced Surface Shaders:** Implementation of hardware-accelerated Acrylic and Mica background materials.
- [x] **Volumetric Shadow Engine:** Precise outer shadow rendering clamped strictly to the visual panel bounds.
- [ ] **Preview Geometry Sync:** Absolute coordinate synchronization for window preview thumbnails and vertical offsets.
- [ ] **Kinetic Zoom Physics (UX):** Implementation of smoothed Bezier curves and easing functions for entry/exit zoom orbits (the "Kremy" feel).
- [ ] **Architectural Pivot:** Partial migration to QML Singletons (Mixed with setContextProperty).

### Stabilization Phase (Foundation Integrity)
- [x] **Fix "Heisenbug" (Rule 12):** Identified and resolved debug-induced hit-test latency (fixed via Absolute Sync).
- [x] **Center Deadzone Isolation:** Resolved via Distance-Based Visual Center hit-testing.
- [x] **Sticky Preview Fix (Bug #8):** Resolved via Icon-Gated Visibility.
- [ ] **Placement Stabilization (Bug #9):** Fix Behavior conflict during edge transitions.
- [ ] **Vertical Indicator Flow (Bug #10):** Fix dot wrapping in vertical mode.


### Architectural Shift: Mathematical Foundation
- [x] **Mathematical Constitution:** Established the `ARCHITECTURE Mandate.md` as the absolute source of truth.
- [x] **Geometric Gravity (Rule 1):** Isolated Screen-to-Panel and Panel-to-Icon geometry.
- [x] **Universal Symmetry (Rule 2):** Perfected the "Empty Gap Rule" for flawless visual balance.
- [x] **Proactive Rule 6 Enforcement:** Real-time settings clamping to eliminate all UI "dead zones."
- [x] **Dual Reserve Space Modes (Rule 1):** Choice between "Panel Background" or "Icon Extents".
- [ ] **Dynamic Indicator Proportions (Rule 2):** 10% golden ratio sizing.
- [x] **The Feature Vault:** Versioned history logs in `docs/features/`.
- [ ] **Island Protocol & Recursive Containers (Rule 13):** Support nested modules (Widgets inside Areas).
- [ ] **Fixed Width Mode (Rule 8):** Start/Center/End icon alignment within extended panels.
- [ ] **Coupling Lock Protocol (Rule 14):** Explicit 'Lock' state for geometric integrity.
- [ ] **Dynamic Repulsion & Proportional Gaps (Rules 15 & 16):** Perfecting the Parabolic Wave physics.

---

## Phase 3: Modular Architecture & System Integration

### Milestone 10: The Modular System
- [ ] **Island Protocol (Rule 13):** Implement recursive container logic for Widgets and Areas.
- [ ] **System Tray Integration:** Full StatusNotifierItem (SNI) protocol support.
- [ ] **Widget Module Ecosystem:** Initial support for System Stats, Media, and Toggles.
- [ ] **Unified DockShell:** Consolidate DockView and MultiDockManager into a robust modular shell.

### Milestone 11: Workspace Awareness & Profile Management
- [ ] **Virtual Desktop & Activity Awareness:** Implement "Filter vs. Global" modes for apps.
- [ ] **Profile-Based Visibility:** Toggle buttons to separate apps by Activity or Virtual Desktop.
- [ ] **Custom Layout Profiles:** Ability to save, export, and load custom dock configurations.
- [ ] **Activity-Specific Docks:** Automatic profile switching based on the current KDE Activity.
- [ ] **Global Default Config:** A "Reset to Factory" and "Default Template" system for new panels.

### Milestone 12: Multi-Panel Architecture
- [ ] **Parallel Panel support:** Allow multiple independent dock panels on the same display/screen.
- [ ] **Multi-Panel Logic:** Independent z-index, visibility, and filtering rules for each panel instance.
- [ ] **Panel Synchronization:** Shared drag-and-drop between multiple panels on the same display.

---

## Future & Wildcard Backlog
- [ ] **Modular Theme Engine:** JSON-based Blueprint system for sharing styles.
- [ ] **KDE "Get New Stuff" (KNS):** Integration for a Krema Theme Store.
- [ ] **Dynamic Soundscapes:** Audio feedback for interaction based on active theme.
- [ ] **Particle Layer:** `QtQuick.Particles` for reactive mouse trails.

---

## Tech Stack
| Component | Technology |
|---|---|
| Language | C++23 |
| Desktop | KDE Plasma 6 (Wayland only) |
| Framework | Qt 6.8+ / Qt Quick / QRhi |
| KDE Tooling | Frameworks 6.0+, LibTaskManager, LayerShellQt, KPipeWire, Kirigami |
| Build System | CMake + ECM + Ninja |
| License | GPL-3.0-or-later |
