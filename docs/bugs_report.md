## [🟢 Fixed] Media Popup Visual Bugs (Clipping, Overlay, Background Cutoff)
- **Reported Issue**: User reported the media hover popup was severely clipped ("features not there"), overlapping the dock incorrectly, and looking ugly.
- **Root Causes**:
  1. Wayland Compositor cut off anything beyond the `surfaceSize` calculated by `DockView::surfaceHeight`.
  2. `QQC2.Popup` generated a broken Wayland subsurface inside LayerShell.
  3. `ColumnLayout` was evaluating its `implicitHeight` to 0 for the Album Art, making the background rectangle stop halfway down the popup.
- **Solution**:
  - Bumped `tooltipReserve` buffer to `600px` in `dockview.cpp`.
  - Replaced `QQC2.Popup` with a root-level `Item` anchored using absolute coordinates mapped from `MediaChip`.
  - Statically bound `implicitHeight: 320 - 32` for the Album Art.
- **Verification**: Verified using offline headless QML renderer `test_popup.qml`.

## Bug Report: Ghost Hitbox & Separator Drift after Multi-Island Scaffold
**Status:** 🟢 Fixed
**Reported:** 2026-09-17 (During Multi-Island Scaffold refactor)

### 1. Identified Logic
- `Component.onCompleted: root._currentDockRepeater = dockRepeater` was accidentally removed from `islandDelegate`.
- The global hit-testing logic in `dockMouseArea` and `pinnedSeparator` relied on `dockPanel.x + dockRow.x + item.x`.

### 2. Root Cause
- The removal of `_currentDockRepeater` broke `appIconCount`, resolving to `0`. Hit-testing was skipped entirely.
- By moving `IslandModule` into a `Row` layout inside a `Loader`, its coordinates (`item.x`) were subjected to new structural offsets that the old math (`dockRow.x + item.x`) didn't account for, shifting hitboxes by the `islandMargin` gap.

### 3. The Proposal & Trial
- **Trial 1 (Success):** 
  - Restored the `_currentDockRepeater` assignment inside `islandDelegate` to revive `appIconCount`.
  - Replaced all hardcoded coordinate summations (`dockRow.x + item.x`) with `item.mapToItem(root, ...)` in `visualCenter` calculations and `pinnedSeparator` placement. 
  - This natively extracts the true visual coordinates regardless of how deep the icons are nested inside zones or scaffold layouts.

## Bug Report: Settings Window Wayland Click-Through (Input Region Mask)
**Status:** 🟢 Fixed
**Reported:** 2026-09-17 (After Edit Mode Decoupling)

### 1. Identified Logic
- `DockVisibilityController::applyInputRegion()` in the C++ backend manually compiles the Wayland Input Region.
- `if (m_liveEditMode && m_settingsWidth > 0) { finalHitbox += QRect(m_settingsX, m_settingsY, m_settingsWidth, m_settingsHeight); }`

### 2. Root Cause
- When decoupling the "Advanced Edit Mode" toggle from the Settings dialog, the C++ code was left unaltered.
- The C++ backend strictly required `m_liveEditMode` to be TRUE before it would add the Settings window dimensions to the Wayland Input Region.
- As a result, opening Settings without Edit Mode being active passed a `(0,0,0,0)` mask to Wayland, rendering the entire window click-through.

### 3. The Proposal & Trial
- **Trial 1 (Success):** Removed the `m_liveEditMode` conditional restriction entirely. The C++ backend now safely verifies `m_settingsWidth > 0` (which is natively managed by the QML loader bounding logic) and reliably passes the correct Settings hit-box to the compositor.

## Bug Report: The Zoom Hover Loop (Flapping) & Tile Background Offset
**Status:** 🟢 Fixed
**Reported:** 2026-09-24 (After adding experimental square tile backgrounds)

### 1. Identified Logic
- `main.qml` handles primary axis hover via `slotStart` and `slotEnd` mapped to `item.width`.
- Secondary axis hover relies on a strict circular radius: `dist <= (item.iconSize / 2)`.
- `updateZoomFactors()` calculates the zoom magnitude based on `Math.abs(mPos - visualCenter)`.
- The dock centers itself (`dockRow.x`) dynamically by calculating `childrenRect.width`.

### 2. Root Cause
- When the experimental square tile backgrounds were added, the visual footprint of the app became a square larger than the image circle. 
- The user logically hovered the corner of the square. The hit-tester rejected the mouse because `dist > iconSize/2`.
- When rejected, `zoomFactor` dropped to 1.0, shrinking the dock.
- When the dock shrank, `dockRow.x` shifted right to re-center.
- This dynamic shift pushed the icon back *underneath* the stationary mouse.
- The hit-tester triggered again, zoomed the dock, shifted it left, and dropped the mouse again.
- This created a violent 60fps mathematical feedback loop (Flapping).
- (Additionally, an intermediate attempt to use a static mathematical grid broke multi-island coordinate offsets, causing the zoom center to jump randomly. This was reverted).

### 3. The Proposal & Trial
- **Trial 1 (Success):** 
  - Restored `updateZoomFactors` to use the dynamic `visualCenter` mapping to preserve coordinate alignment.
  - Replaced the strict circular secondary hit-tester with a square bounding box (`dx <= limit && dy <= limit`).
  - **The True Fix (Hysteresis):** Injected a +12px mathematical hysteresis buffer into both the primary and secondary hit-test limits *only* when the icon is actively hovered. 
  - This "dead zone" absorbs the dynamic layout shift, completely breaking the binary feedback loop.
