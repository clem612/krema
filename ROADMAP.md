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

### Architectural Shift: Modular Root
- [ ] **The Module Base:** Implement a shared base component that handles interaction, spacing, and geometry for ALL dock elements.
- [ ] **Recursive Container Logic:** Support nested modules (Apps inside Groups, Widgets inside Areas) using Single-Directional Flow math to prevent binding loops.
- [x] **Variable Sanitization (KConfig Audit):**
    - [x] Rename `iconScaling` → `indicatorOffset`.
    - [ ] Identify and rename ambiguous variables in `DockSettings`.
- [ ] **Fixed Width Mode:** Add support for constant panel width with center/left/right alignment options.

### Design Language: "Milk & Deep Roast"
- [ ] **Squircle-First Geometry:** Replace standard `Rectangle` rounding with Continuous Curvature (SDF Shaders) for the panel and cards.
- [ ] **Palette Implementation:** Primary `#1C1A1C` (Soft Obsidian), Accent `#FFFDD0` (Clotted Cream).
- [ ] **Surface Logic:** Implement internal shadows/inner glows for a "pressed" material look.
- [ ] **Viscous Easing:** Implement `CubicBezier` curves for weighted, "liquid" motion in zooms and transitions.

### The "Blueprint Ghost" Evolution
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
