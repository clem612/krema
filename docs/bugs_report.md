# Krema Bug Report & Diagnostic History

> **Purpose:** This file tracks the lifecycle of complex bugs. It serves as our institutional memory to prevent repeating the same failed fixes.
> 
> **Status Classifications:**
> - 🔴 **Persistent:** We have attempted to fix this 3 or more times unsuccessfully. This triggers a mandatory **Architectural Audit** to determine if our implementation fundamentally violates the `ARCHITECTURE Mandate.md`, or if the Mandate itself requires refinement. The Mandate is the absolute source of truth.
> - 🟡 **Investigating:** Currently debugging or testing a potential fix.
> - 🟢 **Fixed:** Empirically verified to be resolved across multiple sessions.

---

## 1. The "Ghost Mouse" / Internal Deadzones
- **Status:** 🟢 Fixed (Core Logic)
- **Description:** The zoom and hover interaction would randomly drop (deactivate) while the cursor was visually over the center or top edge of an icon, especially during parabolic movement.
- **Trigger Discovery:** The bug reliably resurfaces immediately after the user adjusts the **Zoom Slider** in settings. This suggests a reactivity failure or stale geometry data when `maxZoomFactor` changes.
- **Failed Attempts (The "Persistent" Phase):**
  1. *Attempt 1 (Fuzzy Buffers):* Tried adding +/- 10px buffers. Result: Interaction felt sloppy.
  2. *Attempt 2 (Center-Distance Math):* Tried calculating 1D distance from the slot center. Result: Ignored Rule 2 symmetry shift.
  3. *Attempt 3 (Target-Push Layout):* Tried fixing layout jitter, but left the "Orbit Check" in place. Result: Asymmetrical clipping.
  4. *Attempt 4 (Interaction Mask):* Implemented a pixel-based mask. Result: Failed to account for real-time slider updates.
  5. *Attempt 5 (Initial Sync Protocol):* Forced Wayland input region updates on launch and slider change. Result: Solved second-launch regressions.
  6. *Attempt 6 (Property Shadowing Fix):* Discovered and removed hardcoded `iconSize: 48` in `AppIcon.qml` which overrode user settings. Result: **Definitive Fix for center deadzones.**
- **Final Fix Strategy (The "Ironclad" Method):**
  - **Shadowing Removal:** Unified `iconSize` properties to prevent mathematical range conflicts.
  - **Interaction Mask:** Replaced the global surface firewall with a strict pixel-based mask.
  - **Persistence Hysteresis:** Added a 40px "survive-orbit" to protect hover state against frame-jitter.
  - **Fixed Surface Buffer:** Set MouseArea to a static 200px buffer to prevent clipping during resizes.
- **Root Cause Analysis:** A multi-layered failure: 1) Property shadowing (`48px` property in AppIcon) restricted hit-testing for large icons; 2) QML MouseArea signal jitter during animations; 3) Wayland input region clipping during fast movement; and 4) Performance-induced jitter from high-volume debug logging (The Heisenbug).

---

*(Template for future bugs)*
## [Bug Name]
- **Status:** [🔴 / 🟡 / 🟢]
- **Description:** ...
- **Steps to Reproduce:** ...
- **Failed Attempts:** ...
- **Current Fix Strategy:** ...
- **Root Cause Analysis:** *(Filled when marked 🟢 Fixed)*
