# Feature: Illusion of Symmetry

## Feature Overview
**Goal:** Create a perfectly balanced visual aesthetic where icons appear centered within the dock panel, while maintaining a rock-solid mathematical grounding to the screen edge.

**Primary Files:**
- `src/qml/AppIcon.qml`
- `src/qml/main.qml`

---

## Version History

### v1.0 - The Empty Gap Rule
**Status:** Approved and Working
**Reasoning:** Implemented **Rule 2: The Illusion of Symmetry** from `ARCHITECTURE Mandate.md`. This move shifted from centering icons (which was unstable) to matching air gaps (which is rock-solid).

#### 1. The Floor Unit
The dock calculates the total physical space occupied below the icon, known as the "Floor Unit."
- **Components:** `_dockFloorPadding` (12px) + `_dotHeight` + `_indicatorGap`.
- **Significance:** This unit defines the absolute grounding distance for the icon unit.

#### 2. The Empty Gap Rule
Visual symmetry is achieved not by moving the icon, but by matching the empty space (padding) on both sides of the unzoomed icon.
- **The Math:** `_dockCeilingPadding` (the top air gap) is forced to exactly equal `_dockFloorPadding` (the bottom air gap, currently 12px).
- **The Result:** Even though the bottom has indicators and the top doesn't, the "air" on both sides is identical, creating a perfect visual balance.

#### 3. The Max Height Envelope
The maximum thickness of the dock panel is dynamically bound to this symmetry:
- **Formula:** `iconSize + Floor Unit + _dockCeilingPadding`.
- **Function:** This ensures the panel background can never grow larger than its intended "Symmetry Box," preventing UI blindness.
