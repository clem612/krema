# Krema Bug Report & Diagnostic History

> **Purpose:** This file tracks the lifecycle of complex bugs. It serves as our institutional memory to prevent repeating the same failed fixes.
> 
> **Validation Mandate:** ⚠️ NO bug shall be marked **🟢 Fixed** without empirical verification and explicit user confirmation.
> 
> **Active Tracking Mandate:** 
> - Status and trials MUST be updated for every attempted fix.
> - Every trial must document the strategy and the specific outcome.
> 
> **Status Classifications:**
> - 🔴 **Persistent:** We have attempted to fix this 3 or more times unsuccessfully. This triggers a mandatory **Architectural Audit**.
> - 🟡 **Investigating:** Currently debugging or testing a potential fix. Use this for all active trials.
> - 🟢 **Fixed:** Empirically verified to be resolved across multiple sessions.
> - ⚪ **On Hold:** Dependency pending or deferred by user.

---

## 1. The "Ghost Mouse" / Internal Deadzones
- **Status:** 🟢 Fixed (Verified via Absolute Sync)
- **Description:** The zoom and hover interaction randomly drops while the cursor is visually over the center of an icon.
- **Definitive Resolution:** Implemented **Absolute Sync**. Established a five-unit "Flooring Constitution" (`Floor`, `Indicator`, `Gap`, `Icon`, `Ceiling`). The interaction boundaries in `main.qml` now sum these identical visual units to find the visual center.

---

## 2. The Dolphin/Settings Identity Crisis
- **Status:** 🟢 Fixed
- **Description:** Wayland App ID mismatch (e.g., `org.kde.systemsettings` vs `systemsettings`) causes "Ghost Gaps" where the dock reserves space for an app that it cannot correctly identify or map to an icon.
- **Definitive Resolution:** Implemented a dynamic lookup bridge in `IdentityManager` using `KService`. The system now automatically attempts to prefix unknown short IDs with `org.kde.` to match standard desktop file naming conventions, eliminating the need for hardcoded overrides and resolving the mapping mismatch.
- **Outcome:** 🟢 Verified. KDE applications now correctly map to their desktop entries and icons.

---

## 3. The Startup Gap Bug (Recursive Desync)
- **Status:** 🟢 Fixed
- **Description:** On application launch, icons appear with massive irregular gaps.
- **Definitive Resolution:** Decoupled the Idle state from the Interactive state using `_zoomActive`. Implemented **State-Aware Layout** (stable grid when idle, recursive displacement when active).

---

## 4. Zoom Scale Reactivity & Orbit Suffocation
- **Status:** 🟢 Fixed
- **Description:** 1.0x zoom scale is "click-through" (unhittable) when settings are open or panel is thin.
- **The Thickness Discovery:** User discovered that increasing visual **Panel Thickness** resolved the bug.
- **Root Cause Analysis:** The `MouseArea` was anchored to the visual panel (`anchors.fill: parent`), physically clipping the interaction zone.
- **Definitive Resolution:** Codified **Rule 18 (Decoupled Catch Zone)**. Anchored the `MouseArea` to the full `root` Item, covering the entire Wayland input region regardless of panel thickness.

---

---

## 5. Shadow Layer Geometry Mismatch
- **Status:** 🟢 Fixed
- **Description:** The volumetric shadow layer renders physically larger than the dock panel envelope.
- **Definitive Resolution:** Bound shadow geometry 1:1 to the `margin` uniform in `main.qml`, ensuring the SDF shader's coordinate space perfectly matches the QML item bounds.
- **Outcome:** 🟢 Verified. Shadow now hugs the panel naturally without bleeding.

## 6. Shader Engine Failure (Acrylic & Mica)
- **Status:** 🟢 Fixed
- **Description:** Acrylic blur engine was non-functional; Mica styling option was missing or incorrect.
- **Definitive Resolution:** 
    1. Enabled platform-level background blur in C++ via `KWindowEffects`.
    2. Synchronized QML/C++ enums (0=Adaptive, 1=Transparent, 2=Solid, 3=Acrylic, 4=Mica).
    3. Isolated visual blur from the expanded interaction zone in `waylanddockplatform.cpp`.
- **Outcome:** 🟢 Verified. Blur is active and confined to the panel; Mica is selectable and metallic.


---

## 7. Window Preview Thumbnail Misalignment (Altitude)
- **Status:** 🟢 Fixed
- **Description:** Window preview thumbnails were rendering with an excessive vertical offset, appearing way too high above the icons.
- **Definitive Resolution:** Implemented a new `visualIconTop` bridge in `main.qml` to pass the exact visual top of the icons to the `PreviewController`.
- **Verification:** User confirmed the "Altitude Confusion" is fixed.

---

## 8. Window Preview & Context Menu Conflict (Sticky Previews)
- **Status:** 🟢 Fixed
- **Description:** The window preview thumbnail covers/overlaps the context menu and intercepts mouse events, making neighbors unhittable and the menu unusable. Previews "stick" open because they trap the mouse in their large input region.
- **Definitive Resolution:** Implemented **Trial 4: Icon-Gated Visibility**. 
    1. **Hover Authority:** Moved the visibility "brain" back to the main dock. The dock now force-closes the preview the moment the mouse exits the active icon's orbit.
    2. **Hover Containment:** Relocated the `HoverHandler` in `PreviewPopup.qml` from the root surface to only the visual thumbnail rectangle.
    3. **Precision Masking:** Implemented a T-shaped precision mask in C++ (refined in Trial 3/4) to ensure the preview surface is only interactive where it is visual.
- **Outcome:** 🟢 Verified. Previews now close naturally when moving between icons, and neighbor icons are no longer blocked.

## 10. RED 2: The "Ghost Sheet" Blur (Rule 18 Violation)
- **Status:** 🟢 Fixed
- **Description:** A blurred rectangle incorrectly filled the empty space between the Dock and the Settings loader.
- **Root Cause Analysis:** The blur effect was tied to the `boundingRect()` of the entire input region, which included disconnected elements and invisible mouse-catch zones.
- **Definitive Resolution:**
    1. **Decoupled Interface:** Added `setBlurRegion` to `DockPlatform`.
    2. **Precision Masking:** `DockVisibilityController` now dispatches a dedicated `blurRegion` that only contains the visual Panel and Settings rects.
    3. **Clean Separation:** The input region (Hitbox) and blur region (Visuals) are now mathematically isolated.
- **Outcome:** 🟢 Verified. Blur is now the "Exact Size of the Panel."

## 11. Tooltip Geometry Desync (Altitude & Tracking)
- **Status:** 🟢 Fixed
- **Description:** Icon name tooltips (for closed apps) were static and did not track zoomed icons, causing them to be overlapped or misaligned during zoom waves.
- **Definitive Resolution:** Applied **Absolute Sync** (Calculated Reality) math to `tooltipItem` in `main.qml`. Tooltips now bind directly to `visualIconX/Y` and `visualIconWidth/Height`, ensuring they smoothly follow the icon's visual top edge and center in real-time.
- **Outcome:** 🟢 Verified. Tooltips now perfectly track zoomed icons across all edges.
