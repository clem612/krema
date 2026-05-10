# Krema Development Roadmap

> A lightweight, modular dock for KDE Plasma 6. 
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

### Architectural Shift: Mathematical Foundation
- [x] **Mathematical Constitution:** Established the `ARCHITECTURE Mandate.md` as the absolute source of truth.
- [x] **Geometric Gravity & Two Worlds:** Isolated Screen-to-Panel (Outside World) and Panel-to-Icon (Inside World) geometry.
- [x] **Universal Symmetry:** Perfected the "Empty Gap Rule" (12px standard) for flawless visual balance.
- [x] **Proactive Rule 6 Enforcement:** Real-time settings clamping to eliminate all UI "dead zones."
- [x] **Dual Reserve Space Modes:** Added choice between "Panel Background" or "Icon Extents" for Wayland window avoidance.
- [x] **Dynamic Indicator Proportions:** Implemented 10% golden ratio sizing and linear gap scaling.
- [x] **Geometry Debugging Mandate:** Formalized Rule 12 with a unified terminal-based diagnostic framework.
- [x] **The Feature Vault:** Established versioned history logs in `docs/features/` to prevent regressions.
- [ ] **Recursive Container Logic:** Support nested modules (Apps inside Groups, Widgets inside Areas) using Single-Directional Flow math to prevent binding loops.
- [ ] **Panel Fixed Width Mode:** Enable constant, minimum, or full-screen dock lengths (Rule 8) with support for Start/Center/End icon alignment within the extended panel.
- [ ] **Icon Display Mode:** Support for "Icons Only" and "Icons + Names" modes to provide flexible task manager visual configurations.

### Design Language: "Milk & Deep Roast"
- [ ] **Squircle-First Geometry:** Replace standard `Rectangle` rounding with Continuous Curvature (SDF Shaders) for the panel and cards.
- [ ] **Palette Implementation:** Primary `#1C1A1C` (Soft Obsidian), Accent `#FFFDD0` (Clotted Cream).
- [ ] **Surface Logic:** Implement internal shadows/inner glows for a "pressed" material look.
- [ ] **Viscous Easing:** Implement `CubicBezier` curves for weighted, "liquid" motion in zooms and transitions.

### Variable Sanitization & Diagnostics
- [x] **Variable Sanitization (KConfig Audit):**
    - [x] Rename `iconScaling` → `indicatorOffset`.
    - [x] Unified sizing limits (PanelHeight max 300).
- [ ] **Real-time Geometry Awareness:** Refactor the blueprint layer to visualize dock boundaries and max-width constraints dynamically.
- [ ] **Shader Integration:** Update the blueprint shader to support resizing animations smoothly.

---

## Phase 3: Extension & Custom Shell
- [ ] **Module System Expansion:** 
    - [ ] App Module: Pinned/Non-pinned/Custom Categories.
    - [ ] Widget Module: System Stats, Media, Toggles.
- [ ] **Breaking QML Limits:**
    - [ ] Custom Shell: Bypass Kirigami window limits for the Settings UI to allow "Liquid Expansion" effects.
    - [ ] Consolidated Rendering: Single `MultiEffect` pass for blur/shadow/tint optimization.
- [ ] **System Tray Integration:** StatusNotifierItem protocol support.

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
