# Code Documentation Audit Log

## 1. Objective
Systematically catalog all undocumented code blocks, ambiguous identifiers, and "magic numbers" across the codebase to ensure long-term maintainability and transparency.

## 2. Audit Guidelines
Each entry in this log must include:
- **Location:** File path and line number(s).
- **The Issue:** Lack of explanation, magic number, or ambiguous naming.
- **The Mandate:** Which of our architectural rules this code serves.
- **Proposed Documentation:** A proposed comment to be added to the code.

---

## 3. Audit Records

### src/qml/AppIcon.qml
- [ ] **Lines 42-55:** Undocumented focus/state properties.
- [ ] **Lines 64-78:** Badge count calculation logic priorities.
- [ ] **Lines 83-98:** Attention conditions (needs reference to KDE Attention Protocol).
- [ ] **Lines 275-305:** Magic timing values for launch/startup (500ms, 2s, 30s).

### src/qml/main.qml
- [ ] **Lines 1090-1120:** Flow container layout assumptions.
- [ ] **Lines 1130-1200:** Mouse area and hit-testing loop logic.

### src/shell/dockvisibilitycontroller.cpp
- [ ] **Constructor Logic (Lines 20-56):** Document the initialization sequence of `m_overlapModel` and the timers.
- [ ] **evaluateVisibility() (Lines 185-210):** Add detailed documentation on the Wayland exclusive zone calculation and visibility state transitions.
- [ ] **applyInputRegion() (Lines 145-165):** Needs an architectural comment on how it interacts with the platform's input region protocol.

### src/app/application.cpp
- [ ] **Main Loop/Init (Lines 40-100):** Document the initialization of the `DockManager` and platform-specific services.

### src/platform/waylanddockplatform.cpp
- [ ] **Wayland Protocol Integration (Lines 50-150):** Document the mapping between `LayerShellQt` protocols and the dock's visible state.
- [ ] **setExclusiveZone():** Explain how this interacts with the Wayland compositor to reserve screen real estate.

### src/style/backgroundstyle.cpp
- [ ] **Render Logic:** Document the shader-based rendering math for Acrylic/Mica effects.

### src/utils/zoomcalculator.h
- [ ] **Parabolic Math:** Document the parabolic curve coefficients and their relationship to Rule 4.

### src/utils/peiconextractor.cpp
- [ ] **Win32/PE Integration:** Document the logic for extracting icons from Windows executables.
