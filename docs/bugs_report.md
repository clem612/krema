# Krema Bug Report & Diagnostic History

> **Purpose:** This file tracks the lifecycle of complex bugs. It serves as our institutional memory to prevent repeating the same failed fixes.
> 
> **Validation Mandate:** ⚠️ NO bug shall be marked **🟢 Fixed** without empirical verification and explicit user confirmation.
> 
> **Status Classifications:**
> - 🔴 **Persistent:** We have attempted to fix this 3 or more times unsuccessfully. This triggers a mandatory **Architectural Audit**.
> - 🟡 **Investigating:** Currently debugging or testing a potential fix.
> - 🟢 **Fixed:** Empirically verified to be resolved across multiple sessions.
> - ⚪ **On Hold:** Dependency pending or deferred by user.

---

## 1. The "Ghost Mouse" / Internal Deadzones
- **Status:** 🟢 Fixed (Verified via Absolute Sync)
- **Description:** The zoom and hover interaction randomly drops while the cursor is visually over the center of an icon.

### [OUTDATED] Discovery: Debug Latency
- **Findings:** This was initially identified as a "Heisenbug" caused by the diagnostic tools themselves. High-frequency logging created sub-pixel latency, causing the QML layout engine to be slightly out of sync with the mouse coordinate mapping.

### [CURRENT] Definitive Resolution: Absolute Sync
- **Root Cause Analysis:** The true culprit was a **Mathematical Disconnection**. The "Interaction Orbit" (trigger zone) used a static "Guess" formula, while the icons used dynamic "Flooring" units. As icons zoomed, the visual pixels shifted away from the guessed orbit.
- **The Fix:** Implemented **Absolute Sync**. Established a five-unit "Flooring Constitution" (`Floor`, `Indicator`, `Gap`, `Icon`, `Ceiling`). The interaction boundaries in `main.qml` now sum these identical visual units to find the visual center.
- **Verification:** Interaction is now 100% stable at any zoom scale or panel thickness. The interaction zone is "magnetically locked" to the visual pixels.

---

## 2. The Dolphin/Settings Identity Crisis
- **Status:** 🟡 Investigating
- **Description:** Wayland App ID mismatch (e.g., `org.kde.systemsettings` vs `systemsettings`) causes "Ghost Gaps" where the dock reserves space for an app that it cannot correctly identify or map to an icon. This is a **naming/metadata issue**, distinct from interaction bugs.
- **Impact:** Causes visual gaps in the dock and potentially prevents pinned icons from showing "running" indicators for certain apps.
- **Current Fix Strategy:** Identity Bridge and Fuzzy Hit-Test (10px) implemented as temporary workarounds. Needs deep architectural analysis.

---

## 3. The Startup Gap Bug (Recursive Desync)
- **Status:** 🟢 Fixed
- **Description:** On application launch, icons appear with massive irregular gaps. The layout only stabilizes after the user hovers over the icons.

### [OUTDATED] Trial 1: Recursive Race Condition Analysis
- **Attempt:** Assumed QML Repeater was creating items too slowly.
- **Fix:** Provided a simple `index * slotSize` fallback.
- **Result:** **FAILED.** Gaps persisted. The recursive binding still took precedence or evaluated with incorrect data.

### [OUTDATED] Trial 2: Ghost Grid Fallback
- **Attempt:** Implemented a non-recursive `baseWidth` for `dockRow` and a `fallback` position in `AppIcon`.
- **Fix:** `return p ? p.x + ... : fallback`.
- **Result:** **FAILED.** Binding loops were detected, suggesting the engine was still fighting between the fallback and the recursive requirement of Rule 15.

### [OUTDATED] Trial 3: Binding Loop Break (Cross-Axis Decoupling)
- **Attempt:** Decoupled the centering logic from `parent.width` to `_maxIconThickness`.
- **Fix:** Used `(dockRow._maxIconThickness - width) / 2` to break the circular dependency.
- **Result:** **FAILED.** The gaps remain huge on launch.

### [CURRENT] Trial 4: State-Aware Layout (Architectural Pivot)
- **Attempt:** Decoupled the Idle state from the Interactive state using `_zoomActive`.
- **Fix:** 
    - `_zoomActive === false`: Use stable Grid (`index * slotSize`).
    - `_zoomActive === true`: Use Recursive Displacement (`p.x + p.w + spacing`).
- **Result:** 🟢 **FIXED.** This mathematically prevents gaps on startup because the recursive chain is "locked out" until the user explicitly interacts with the dock.

### Root Cause Analysis
The recursive chain was inherently unstable during the asynchronous startup of the QML engine. By implementing a **State-Aware Layout**, we provided a solid mathematical foundation that only transitions to dynamic displacement when required by the user.

---

## 4. Zoom Scale Reactivity Inconsistency & Orbit Suffocation
- **Status:** ⚪ On Hold
- **Description:** Two specific anomalies occur **only when the settings window is open**:
    1. **1.0x Save Delay:** The 1.0x zoom scale is "click-through" (unhittable) and only saves/updates when the settings window is closed.
    2. **First-Entry Defect:** For all scales (1.1x to 2.0x), the very first `enterOrbit` is physically lower than the icons. It only updates to match the accurate icon size *after* the user performs their first `exitOrbit`.

### [OUTDATED] Trial 2: Signal Desync Discovery
- **Findings:** Identified that the Dock process was "memory-stuck" due to isolated QML engines and stale `ScreenSettings` fallbacks.
- **Research:** [Zoom Signal Desync](research/zoom_signal_desync.md)

### [OUTDATED] Trial 3: Toggle & Apply Hotfixes
- **The Strategy:** 
    - Implemented a manual "Apply Changes" button to force memory sync.
    - Added an "Enable Hover Zoom" toggle to simplify the 1.0x state.
    - Made `enterOrbit` dynamically scale with zoom.
- **Result:** **FAILED.** The hotfixes did not resolve the core "click-through" or "first-entry" accuracy issues. The bug remains stubborn and occurs only when the Settings window is open.
- **Research:** [Orbit Suffocation](research/orbit_suffocation.md)

### [OUTDATED] Trial 4: Rule 17 Stability Fallbacks (Constitution Refactor)
- **The Strategy:** Codified **Rule 17 (The Unit Mandate)** in the Architecture Mandate. Implemented mathematical "Stability Fallbacks" (`_fallbackFloor`, etc.) in `main.qml` to decouple the Wayland Input Region from asynchronous icon loading. Refactored `currentVisualOverflow` to be "Orbit-Aware" (sizing the surface to the Exit Orbit).
- **Result:** **REVERTED.** The fallback variables were deemed unnecessary and did not resolve the core 1.0x click-through issue. The documentation for Rule 17 was preserved, but the code implementation was discarded to maintain simplicity.
- **Current Status:** ⚪ On Hold. Root cause remains focused on **Wayland Surface Layer Conflict** during `liveEditMode`; seeking external developer assistance.

---

## 5. Window Preview Layering Conflict
- **Status:** 🔴 Persistent
- **Description:** The icon thumbnail window preview covers/overlaps the context menu. The context menu acts as a "hover trap": moving from the icon directly into the menu prevents the icon's hover `exit` event from firing, keeping the auto-preview timer alive. However, the menu itself is not the hover zone (leaving and re-entering the menu from the outside does NOT trigger the icon's hover state).
- **Failed Attempts:**
    - **Trial 1:** Exposed `DockContextMenu.visible` to QML to suppress `_tryAutoPreview` and explicitly clear `hoveredIndex` in `onPositionChanged`. **FAILED:** The preview still triggers and covers the menu.
- **Plan:** Investigate Z-index, Wayland surface layering priority, and how Wayland routes pointer events when a native `QMenu` is open.

---

*(Template for future bugs)*
## [Bug Name]
- **Status:** [🔴 / 🟡 / 🟢]
- **Description:** ...
- **Steps to Reproduce:** ...
- **Failed Attempts:** ...
- **Current Fix Strategy:** ...
- **Root Cause Analysis:** *(Filled when marked 🟢 Fixed)*

