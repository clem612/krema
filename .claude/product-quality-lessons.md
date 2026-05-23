# Product Quality Lessons Learned

This file contains the "burned-in" anti-patterns to prevent recurring mistakes.

## 2026-05-19: QML Binding Race Conditions
- **Anti-Pattern:** Assuming that global singletons (DockSettings, etc.) and model data are available synchronously during the `onCompleted` phase or initial property binding of instantiated components (AppIcon).
- **Observation:** Persistent `Unable to assign [undefined] to bool` warnings in logs during startup.
- **Root Cause:** AppIcon properties bind to model/settings values before those values are populated by the backend, leading to temporary `undefined` states.
- **Prevention Rule:** In non-critical visual components, expect and tolerate initial binding warnings if the property eventually stabilizes. Do not over-engineer complex null-guarding logic (e.g., unnecessary property resets) unless the UI exhibits flickering or functional failure.

## 2026-05-23: Vector Graphics Size Checks
- **Anti-Pattern:** Using `icon.availableSizes().isEmpty()` as a safety check before returning a `QIcon` to QML.
- **Observation:** Flatpak vector graphics (SVGs) were successfully found by the extractor but discarded right before rendering, leaving an empty fallback in the UI.
- **Root Cause:** SVGs are vector-based and lack predefined pixel dimensions. They will inherently report an empty list for `availableSizes()` until they are explicitly rendered.
- **Prevention Rule:** Never use `availableSizes().isEmpty()` as a validation step for user-provided icons or themes. If the file exists and forms a valid `QIcon`, trust the QML image provider to resolve it.

## 2026-05-23: Raw IPC Socket Interception
- **Anti-Pattern:** Assuming that standard `hyprctl dispatch <command>` syntaxes will work universally over the Hyprland UNIX socket without error handling.
- **Observation:** Context menu "Close" buttons failed silently with no effect.
- **Root Cause:** Users running the `hyprland-lua-plugins` extension have their raw IPC socket dispatches intercepted and overridden by the Lua interpreter, breaking commands like `closewindow address:` with errors like `expected a dispatcher (e.g. hl.dsp.window.close())`.
- **Prevention Rule:** All hardcoded dispatch commands sent to the Hyprland IPC socket MUST include a fallback handler that dynamically catches Lua execution errors and rewrites the command using the `hl.dsp.*` syntax.
