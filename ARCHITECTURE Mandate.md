## Krema Dock: Mathematical & Interaction Mandates
This document serves as the absolute source of truth for the dock's layout, math, and interaction logic. All QML properties, UI controls, and visual elements must strictly inherit from these rules.

### 1. The Supreme Law of Gravity (Grounding)
The dock operates in two strictly isolated coordinate systems.
- **The Outside World (Screen Flooring):** The Dock Panel anchors to the screen edge using `floating_offset`. This handles the physical distance from the screen to the exterior of the panel box.
- **The Inside World (Dock Flooring):** The Icons and Indicators are anchored to the panel's interior using `dock_floor_padding` (the distance from the panel edge to the indicators).
- **Geometric Gravity:** The internal layout container (`dockRow`) MUST be anchored flush (0px offset) to the panel's screen-facing edge. The "Gravity Chain" is physical and unbreakable: Screen -> Floating Gap -> Panel Edge -> Floor Padding -> Indicators -> Icon.

### 2. The Illusion of Symmetry (The Empty Gap Rule)
Visual symmetry is achieved not by centering the icon unit, but by matching the empty gaps on both sides of the unzoomed icon.
- **The Floor Unit:** The total space occupied below the icon (Padding + Indicators + Gap).
- **The Empty Gap Rule:** Symmetry is perfectly realized when the empty space above the icon (`ceiling_padding`) is exactly equal to the empty space below the indicators (`dock_floor_padding`).
- **Universal Application:** This rule must be maintained regardless of panel thickness, icon size, or dynamic indicator scaling.
- **The Max Height Envelope:** The maximum mathematical thickness of a slot is: `iconSize + Floor Unit + ceiling_padding`.
- **Subordination:** Symmetry is a visual illusion subordinate to Gravity. We do not use "Center anchoring" (e.g., `anchors.centerIn`). We use edge grounding and mathematically enforce the symmetric boundary.

### 3. The Pixel-Perfect Hitbox Law (Stable Virtual Origin)
Interaction boundaries must strictly respect the visual pixels of the icon, ignoring transparent bounding boxes or invisible containers. To achieve this without introducing deadzones (the "Moving Target" problem), hit-testing MUST use a Stable Virtual Origin.
- **The Ban on Buffers:** "Fuzzy logic" or adding pixel buffers (e.g., +10px margins) to hide jitter is strictly forbidden. 
- **The Unscaled Slot Base:** The Chassis defines a fixed, unscaled "Slot" for each icon (grounded by Rule 1). Hit-testing is calculated by mapping the mouse coordinates back to the center of this Unscaled Slot, *before* any visual scaling transformations are applied. 
- **Virtual Zoom Target:** The mathematical hit-boundary scales geometrically outward from the Stable Virtual Origin.
- **Hover State:** An icon is only "hovered" when the mapped cursor is mathematically inside the 2D boundaries of the dynamically scaled Unscaled Slot.
- **Exit State:** The instant the cursor leaves the exact boundary of the mathematically scaled slot, the hover state for that specific icon is terminated.

### 4. The Decoupled Parabolic Zoom Rule
The zoom wave is mathematically decoupled from the pixel-perfect hover state.
- **Horizontal Continuity:** The zoom effect spans horizontally across the icons as a continuous wave, tracking the cursor's global X-coordinate on the panel, regardless of whether the cursor is actively inside a pixel-perfect icon boundary.
- **Vertical Limits:** The vertical scale of the zoom is bound by the icon's mathematical scale factor. The hitbox grows dynamically with the zoom scale but must continually obey the Pixel-Perfect Law.

### 5. The Independent Panel Height & Visual Overflow (The Top-Down Reveal)
The dock panel's thickness (height) is decoupled from the size of the icons, utilizing the "Fixed Floor, Moving Ceiling" principle.
- **The Moving Ceiling:** The panel's inner (free-facing) edge is the only part of the background that moves when height is adjusted. Resizing the panel is a "Top-Down Reveal" mechanism.
- **Uncovering the Icon (Visual Overflow):** When the panel thickness is reduced, the "Ceiling" moves toward the "Floor". Because the icon is locked by Gravity (Rule 1) to the Fixed Floor, the shrinking ceiling simply *uncovers* the icon from the top, allowing it to visually overflow strictly toward the screen center.
- **Illusion of Symmetry:** Symmetry is achieved only at the Max Height Envelope. During overflow, symmetry is sacrificed to maintain the Unbreakable Anchor Chain.

### 6. The Dynamic UI Blindness Prevention (Slider Rule)
User-facing configuration controls (sliders, spinboxes) must never operate blindly. They must dynamically bind to the mathematical limits of the dock's current state.
- **Math Always Wins:** If a mathematical rule caps a value (e.g., panel thickness cannot exceed the Max Height Envelope), the UI slider controlling that value must instantly adopt this mathematical cap as its new maximum.
- **Zero Dead Zones:** Sliders must never be allowed to move into ranges that produce no visual changes. If the mathematical limit is 100px, the slider max is 100px, even if its hardcoded absolute maximum is 200px.

### 7. The Dimensional Sync Protocol (Scaling Toggle)
Icon size and panel thickness must support both independent and proportional scaling during a Visual Overflow state, governed by a strict synchronization toggle.
- **Independent Mode (Absolute Thickness):** When desynchronized, resizing the icons alters the Max Height Envelope (Rule 5) but leaves the absolute pixel height of the dock panel unchanged. The visual overflow size changes dynamically, but the gravity floor remains mathematically fixed.
- **Synchronized Mode (Proportional Lock):** When synchronized, the current ratio between the panel thickness and the Max Height Envelope is locked. Modifying the base icon size will automatically calculate and apply a new panel thickness to preserve the exact visual overflow ratio.
- **Mathematical Subordination:** Sync calculations are strictly subordinate to Rule 5 and Rule 6. A synchronized scale operation can never force the panel thickness to exceed the Max Height Envelope.

### 8. The Omnidirectional Axis & Floating Offset Mandate
The dock's mathematical logic and geometric rules are strictly edge-agnostic. Furthermore, the internal geometry of the dock must remain strictly isolated from its global position on the screen.

- **Axis Transposition:**
    - **Primary Axis (Length):** The axis parallel to the screen edge (X-axis for Top/Bottom; Y-axis for Left/Right). The Parabolic Zoom Rule (Rule 4) and layout flow strictly along this axis.
    - **Cross Axis (Thickness):** The axis perpendicular to the screen edge (Y-axis for Top/Bottom; X-axis for Left/Right). Max thickness limits, grounding, and visual overflow (Rules 1 & 5) are calculated against this axis.
- **The Floating Offset (External Geometry):** The Dock Panel anchors to the physical screen edge offset by a dynamic `floating_offset` variable (e.g., `0px` for flush, `10px` for floating). This offset dictates the panel's global position on the Cross Axis but MUST remain entirely mathematically invisible to the internal sizing, scaling, and hitbox calculations of the dock.
- **Isolated Panel-Edge Grounding (Internal Geometry):** The icons must be permanently anchored to the specific *inner boundary of the Dock Panel* that corresponds to the active screen edge. The icons are entirely blind to the `floating_offset` and the physical screen edge.
- **Origin Flipping:** The directional origin of the zoom effect (`transformOrigin`) must automatically flip to originate from the panel's anchored inner boundary.
- **Padding Translation:**
    - `dock_floor_padding` is the internal distance between the indicators and the panel's anchored inner boundary (The Floor).
    - `ceiling_padding` is the internal distance between the unzoomed icon and the panel's free-facing inner boundary (The Ceiling).
    - The Symmetry Illusion (Rule 2) enforces that `ceiling_padding` MUST exactly equal `dock_floor_padding` along the Cross Axis to maintain the visual illusion, completely independent of any `floating_offset`.

### 9. The Modular Black Box Contract
The Dock Chassis is strictly a "Slot Manager," responsible only for defining the unzoomed territory (The Slot) and delivering the global mouse coordinates. Individual components (Icons, Widgets, Separators) are "Black Boxes" responsible for their own internal logic.
- **Slot Territorialism:** The Chassis defines the unzoomed width/height of a slot based on the Gravity Protocol. The component inside is guaranteed this space but must not exceed it without visual overflow permission.
- **Internal Sovereignty:** Each module is responsible for its own Gravity (Rule 1) implementation. The Chassis does not "reach inside" to position a module's image.
- **Hitbox Reporting:** The Chassis performs a high-level "Slot Hit-Test," but the Module must provide the final "Pixel-Perfect" confirmation (Rule 3).
