# Krema Bug Report & Diagnostic History

> **Purpose:** This file tracks the lifecycle of complex bugs. It serves as our institutional memory to prevent repeating the same failed fixes.
> 
> **Status Classifications:**
> - 🔴 **Persistent:** We have attempted to fix this 3 or more times unsuccessfully. This triggers a mandatory **Architectural Audit** to determine if our implementation fundamentally violates the `ARCHITECTURE Mandate.md`, or if the Mandate itself requires refinement. The Mandate is the absolute source of truth.
> - 🟡 **Investigating:** Currently debugging or testing a potential fix.
> - 🟢 **Fixed:** Empirically verified to be resolved across multiple sessions.

---

## 1. The "Ghost Mouse" / Internal Deadzones
- **Status:** 🟡 Investigating (Testing Final Fix)
- **Description:** The zoom and hover interaction would randomly drop (deactivate) while the cursor was visually over the center or top edge of an icon, especially during parabolic movement.
- **Steps to Reproduce:** Approach the dock from the top edge quickly while zoom is at maximum (e.g., 2.0x). The hover drops out inside the visual boundaries of the icon.
- **Failed Attempts (The "Persistent" Phase):**
  1. *Attempt 1 (Fuzzy Buffers):* Tried adding +/- 10px buffers. Result: Interaction felt sloppy; didn't fix animation lag.
  2. *Attempt 2 (Center-Distance Math):* Tried calculating 1D distance from the slot center. Result: Failed because it ignored the visual layout shift caused by Rule 1 (Grounding) and Rule 2 (Symmetry).
  3. *Attempt 3 (Target-Push Layout):* Tried fixing layout jitter, but left the "Orbit Check" in place. Result: The Orbit Check artificially clipped the top half of the zoomed icons because they grow asymmetrically from the floor.
- **Current Fix Strategy (The "Ironclad" Method):**
  - Completely removed the `Orbit Check`.
  - Disabled `MouseArea.onExited` to prevent signal jitter during panel animations.
  - Rely exclusively on absolute global-to-local coordinate mapping (`iconImage.mapFromGlobal`) combined with a mathematically strict "Surface Firewall."
- **Root Cause Analysis:** *(Pending Verification)*

---

*(Template for future bugs)*
## [Bug Name]
- **Status:** [🔴 / 🟡 / 🟢]
- **Description:** ...
- **Steps to Reproduce:** ...
- **Failed Attempts:** ...
- **Current Fix Strategy:** ...
- **Root Cause Analysis:** *(Filled when marked 🟢 Fixed)*
