# Feature: Dynamic Indicator Proportions

## Feature Overview
**Goal:** Ensure that status indicators scale naturally with the icons, maintaining a cohesive visual ratio at all sizes (from 24px up to 150px).

**Primary Files:**
- `src/qml/AppIcon.qml`

---

## Version History

### v1.0 - The 10% Golden Ratio
**Status:** Approved and Working
**Reasoning:** Replaced hardcoded 4px dots with a dynamic formula to fulfill **Rule 6 (UI Blindness Prevention)**. This ensures that indicators never appear too large on small docks or too small on large docks.

#### 1. Dynamic Dot Height (`_dotHeight`)
Locked to a 10% ratio of the base icon size, with a 2px minimum safety clamp.
```qml
readonly property real _dotHeight: Math.max(2, Math.round(iconSize * 0.10))
```

#### 2. Proportional Active Dash (`_activeDotWidth`)
Ensures the active "dash" is visually distinct but never outgrows the icon's horizontal width. Locked to 35% of icon width.
```qml
readonly property real _activeDotWidth: Math.max(_dotHeight * 2, Math.round(iconSize * 0.35))
```

### v1.1 - The Pure Proportional Gap
**Status:** Approved and Working
**Reasoning:** Refined the `_indicatorGap` to remove the hardcoded 4px baseline. This fixed the issue where small icons (24px) had disproportionately large air gaps between the dots and the icon.

#### 1. Proportional Gap Math
The gap now scales linearly with the icon size, ensuring a tight visual unit at all scales.
```qml
_indicatorGap: Math.max(2, Math.round(iconSize * 0.08) + Math.round(iconSize * 0.15 * (1.0 - OffsetSlider)))
```
