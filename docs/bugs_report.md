# Bug Reports & Resolutions

> **Mandate Reference (Rule 11):** This file is an immutable history of all bugs, trials, and verified fixes. Never delete old entries; append new entries to the bottom to maintain a chronological history.

## [2026-05-20] Bug #26: Edge Placement Desync (Stuck at Bottom)

**Status:** 🟢 Fixed

**Symptoms:**
When changing the Edge placement in the Settings Window (e.g., from Bottom to Left), the actual Dock Panel and Wayland Window remained stuck at the bottom of the screen. However, the Ghost Blueprint and Settings Window correctly detached and moved to the left edge of the screen, creating a severe visual tear.

**Root Cause (State Desync):**
1. The UI buttons in `VisibilityPage.qml` were modifying the global `DockSettings.edge`.
2. The Ghost Blueprint and Settings Window were hardcoded to read from this global `DockSettings.edge`, causing them to instantly snap to the new location.
3. The actual Wayland Window and `dockPanel` relied on `DockView.edge`, which is fed by `ScreenSettings`.
4. If a local override existed for the current monitor in `kremarc` (e.g., `[Screen_HDMI-A-1] Edge=1`), `ScreenSettings` would block the global update. Thus, the Wayland Window never moved, and `DockView.edge` never updated.

**The Proposal & Fix:**
1. **Visual Lock:** Bound `ghostBlueprint` and `settingsUnifiedLoader` strictly to `DockView.edge` and `DockView.isVertical`. This mathematically forces them to stay within the true Wayland Window bounds, preventing visual tearing.
2. **Override Clearance:** Updated the UI buttons in `VisibilityPage.qml` to forcefully call `DockView.screenSettings.clearOverride("Edge")`. This deletes any stale local overrides, allowing the global setting to successfully punch through to the C++ backend and move the window.
3. **Tracking System:** Implemented the `Configuration Desync Tracker` (`--debug-config`) in `DebugManager` and `ScreenSettings` to intercept and expose any future blocked configurations in the terminal.

**Verification:**
Tested with `--debug-config`. Verified that clicking "Left" clears the override, successfully updates the Wayland `LayerShell` anchors, and moves the entire dock system harmoniously.

## [2026-05-20] Bug #27: Indicators Permanently Stuck on Edge Change

**Status:** 🟢 Fixed

**Symptoms:**
When moving the dock from the Bottom edge to the Top edge, and then back to the Bottom, the indicator dots remained permanently stuck at the Top of the panel.

**Root Cause (QML Anchor Binding Failure):**
The `indicatorRow` in `AppIcon.qml` used conditional QML anchors (e.g., `anchors.top: DockView.edge === 0 ? parent.top : undefined`). However, dynamically assigning `undefined` to a QML anchor does *not* clear the previous anchor in the QQuickItem backend; it simply fails to evaluate. Thus, when the edge changed, the `parent.top` anchor was never broken, causing the indicators to be permanently glued to the top of the icon.

**The Proposal & Fix:**
Stripped the conditional `anchors` completely from `indicatorRow`. Replaced them with pure mathematical `x` and `y` equations bound to `DockView.edge` and `DockView.isVertical`. This ensures the position is calculated explicitly every time the edge changes, completely bypassing the flawed QML anchor state machine.

**Verification:**
Tested with `--debug-config`. Verified that clicking "Left" clears the override, successfully updates the Wayland `LayerShell` anchors, and moves the entire dock system harmoniously.

## [2026-05-23] Bug #28: Close App Button in Context Menu (Hyprland)

**Status:** 🟢 Fixed

**Symptoms:**
When clicking "Close" in the Dock Context Menu on Hyprland, the application fails to close and nothing happens.

**Root Cause (Lua Interception):**
The `HyprlandIpc::dispatch` utility sends `/dispatch closewindow address:0x...` over the Hyprland UNIX socket. However, the user is running a Lua plugin (`hyprland-lua-plugins`) which intercepts standard `hyprctl` socket dispatches. The socket throws a Lua error: `expected a dispatcher (e.g. hl.dsp.window.close())` instead of closing the window. Our IPC handler previously only had a fallback syntax for `focuswindow`, but completely ignored `closewindow`.

**The Proposal & Fix:**
Add a Lua fallback branch inside `HyprlandIpc::dispatch` for `closewindow`. If the socket responds with a `lua` or `hl.dispatch` error, and the command is `closewindow address:`, the system will dynamically rewrite the command to `hl.dsp.window.close({window="address:..."})` and re-send it to bypass the interception.

**Verification:**
Tested the exact IPC fallback command natively via a Python socket script on a dummy application window. Confirmed the Lua dispatch correctly resolves and successfully closes the window without crashing the dock or Hyprland.

## [2026-05-25] Bug #29: Active Indicator Fails to Update on External Window Focus

**Status:** 🟢 Fixed

**Symptoms:**
When scrolling on an application icon in the dock, the active window indicator (dash/dot) updates correctly to reflect the cycled window. However, when clicking on a window externally (e.g., via the window manager or Alt+Tab), the indicator fails to update to reflect the newly active window instance.

**Root Cause (Proxy Model DataChanged Filter):**
`KdeTasksProxyModel::onSourceDataChanged` was designed to only emit an `ActiveChildIndexRole` update if `TaskManager::AbstractTasksModel::IsActive` was explicitly present in the `roles` list provided by the KDE backend. When a window is activated externally, the window manager sometimes emits a generic state change without explicitly populating the `roles` list with `IsActive`. As a result, the QML indicator was starved of data binding updates. 

**The Proposal & Fix:**
Modified `KdeTasksProxyModel::onSourceDataChanged` to unconditionally emit `dataChanged` for `ActiveChildIndexRole` against the parent application group whenever ANY child window emits a data change. Since computing `ActiveChildIndex` is computationally cheap, it guarantees the QML frontend is always perfectly synchronized with the true active window state, completely bypassing the backend's inconsistent role-list population.

**Verification:**
Verified that QML bindings for `activeDotIndex` now fire correctly regardless of whether the window was activated internally via `DockActions::cycleWindows` or externally via the window manager.
