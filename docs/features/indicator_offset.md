# Feature: Dynamic Indicator Offset

## Feature Overview
**Goal:** Allow users to adjust the distance between the indicators and the icon unit while strictly preserving visual symmetry and grounding stability.

**Primary Files:**
- `src/qml/AppIcon.qml` (Elastic Slot Math)
- `src/qml/settings/IconsPage.qml` (UI Slider)

---

## Version History

### v1.0 - The Elastic Symmetry Implementation
**Status:** Approved and Working
**Reasoning:** Implemented a functional "Indicator Offset" slider that upholds **Rule 2: The Illusion of Symmetry**. Unlike previous attempts that used aggressive shifting, this version uses an "Elastic Slot" that expands proportionally.

#### 1. Proportional Gap Logic
The distance between the dot and the icon is calculated as a percentage of the icon size, ensuring the gap ratio feels consistent regardless of the dock's scale.

#### 2. The Elastic Slot Math
Whenever the user increases the gap, the dock mathematically calculates a matching "Ceiling Padding" to ensure the icon remains perfectly centered within the panel background.
- **Formula:** `_maxTheoreticalThickness = iconSize + FloorUnit + CeilingPadding`.
- **Constraint:** `CeilingPadding` MUST exactly equal the empty `FloorPadding`.

#### 3. Top-Down Reveal Support
Since the slot expands symmetrically, the panel background smoothly grows taller to accommodate the new gap. Because the icons are grounded by **Geometric Gravity** to the floor, they physically move away from the indicators as the "Ceiling" of the panel rises.
