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
- **The Empty Gap Rule:** Symmetry is perfectly realized when the empty space above the icon (`panel_ceiling_padding`) is exactly equal to the empty space below the indicators (`dock_floor_padding`).
- **Universal Application:** This rule must be maintained mathematically regardless of panel thickness, icon size, or dynamic indicator scaling. The "air" on both sides must remain identical even during a visual overflow state.
- **The Max Height Envelope:** The maximum mathematical thickness of a slot is: `iconSize + Floor Unit + panel_ceiling_padding`.
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
- **Absolute Zoom Independence:** The Zoom Scale variable (`maxZoomFactor`) and visual projection are strictly decoupled from physical Panel Thickness. The dock panel MUST NOT increase or decrease its thickness in response to zoom magnification. Icons zoom freely as visual projections and are permitted to overflow the panel boundary indefinitely without triggering a panel resize.

### 6. The Dynamic UI Blindness Prevention (Slider Rule)
User-facing configuration controls (sliders, spinboxes) must never operate blindly. They must dynamically bind to the mathematical limits of the dock's current state.
- **Math Always Wins:** If a mathematical rule caps a value (e.g., panel thickness cannot exceed the Max Height Envelope), the UI slider controlling that value must instantly adopt this mathematical cap as its new maximum.
- **Zero Dead Zones:** Sliders must never be allowed to move into ranges that produce no visual changes. If the mathematical limit is 100px, the slider max is 100px, even if its hardcoded absolute maximum is 200px.

### 7. The Dimensional Sync Protocol (Scaling Toggle)
Icon size and panel thickness must support both independent and proportional scaling during a Visual Overflow state, governed by a strict synchronization toggle.
- **Independent Mode (Absolute Thickness):** When desynchronized, resizing the icons alters the Max Height Envelope (Rule 5) but leaves the absolute pixel height of the dock panel unchanged. The visual overflow size changes dynamically, but the gravity floor remains mathematically fixed.
- **Synchronized Mode (Proportional Lock):** When synchronized, the current ratio between the panel thickness and the Max Height Envelope is locked. Modifying the base icon size will automatically calculate and apply a new panel thickness to preserve the exact visual overflow ratio.
- **Permanent Radius Sync:** The corner radius is exempt from the synchronization toggle. It MUST always scale 1:1 proportionally with the base icon size to maintain a consistent visual "roundness" across all dock scales.
- **Mathematical Subordination:** Sync calculations are strictly subordinate to Rule 5 and Rule 6. A synchronized scale operation can never force the panel thickness or radius to exceed the Max Height Envelope.

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
    - `panel_ceiling_padding` is the internal distance between the unzoomed icon and the panel's free-facing inner boundary (The Ceiling).
    - The Symmetry Illusion (Rule 2) enforces that `panel_ceiling_padding` MUST exactly equal `dock_floor_padding` along the Cross Axis to maintain the visual illusion, completely independent of any `floating_offset`.

### 10. The Surgical Edit Mandate
To maintain system stability and prevent regression cascades, all modifications to the codebase must be targeted and minimal.
- **Chunking:** Refactors exceeding 50 lines must be broken into isolated, verifiable steps.
- **Baseline Integrity:** Never rewrite stable geometry or logic blocks in a single operation. Modify one property or visual block at a time.

### 11. The Proactive Reporting Mandate
The AI agent must identify and report any bugs, binding loops, or mathematical anomalies found in the logs BEFORE attempting a fix.
- **Transparency:** All anomalies must be explained technically to the user.
- **Empirical Reproduction:** For bug fixes, the failure state must be reproduced and logged before the fix is applied.

### 12. Geometry Debugging Mandate
All physical and interactive components must support a standardized diagnostic layer, enabled via the `--debug-geom` and `--debug-hit` flags.
- **Standardized Logging:** Components must provide real-time reporting of their X, Y, Width, and Height to the terminal in the mandated functional formats.
- **Visual Baseline:** Debug logs are the ultimate authority for verifying Mandates #1-#11. If a visual element looks correct but the log shows a mathematical error, the geometry is considered "broken."

### 13. The Island Protocol
Every logical group (App, Widget, Folder) shall be encapsulated as an 'Island'. Each Island maintains its own grounded origin and symmetry math.
- **Recursive Containers:** Islands can contain other modules, inheriting the same Gravity and Symmetry constraints as leaf modules.

### 14. The Coupling Lock Protocol
To safeguard geometric integrity (Rule 1 & Rule 2), Island coupling and membership changes are protected by an explicit 'Lock' state. 
- **Immutable State:** When locked, the dock's logical layout is immutable.
- **Intentionality:** Modifications to the Island's structure or links between islands require an intentional unlock action (Edit Mode).

### 15. The Dynamic Repulsion Protocol
To prevent visual overlap and maintain individual "territory" during interaction, zoomed icons must physically displace their neighbors.
- **Dynamic Slot Sizing:** The primary axis of an icon's layout slot (Width for horizontal, Height for vertical) must scale 1:1 with its visual zoom factor.
- **Collision Avoidance:** The resulting layout repulsion ensures that no two icons can visually occupy the same coordinate space, preserving the Parabolic Wave's mathematical clarity.
- **Hit-test Stability:** Repulsion-driven movement must be compensated for by 'Ironclad' coordinate mapping (Rule 3) to prevent hover-state flicker during icon displacement.

### 16. The Proportional Gap Protocol
To maintain consistent visual rhythm and prevent 'cramping' at high scales, the empty space (Gap) between icons must scale proportionally with the current zoom level.
- **Linear Scaling:** The gap between Icon A and Icon B must scale based on the average zoom factor of both icons.
- **Rhythmic Preservation:** This ensures that the ratio between 'Ink' and 'Air' remains constant, providing a premium, high-fidelity visual experience regardless of the dock's magnification state.

### 17. The Interaction Flooring Constitution (The Unit Mandate)
To ensure absolute mathematical consistency between visual rendering and interaction logic, the dock's vertical (or cross-axis) stack is governed by a strict variable-based constitution.

- **The 5-Unit Stack:** Every interactive slot is composed of five fundamental units:
    1.  `Floor Padding` (Internal space between the panel's anchored edge and the indicators)
    2.  `Indicator` (Visual dot/dash height)
    3.  `Gap` (Space between indicator and icon image)
    4.  `Icon` (The visual icon pixels, subject to zoom)
    5.  `Panel Ceiling Padding` (Internal space above the icon, mirroring Unit #1 per Rule 2)
- **Dedicated Unit Variables:** Every gap, padding, indicator size, and physical layout element MUST be defined as its own explicit, mathematically calculated unit variable (e.g., `_unitPanelFloor`, `_unitIndicator`, `_unitIconIndicatorGap`).
- **The Ban on Implicit Math (Magic Numbers):** Hardcoded pixel values (e.g., `+ 5`, `- 12`) and implicit math within layout constraints or hit-testing (orbit) formulas are strictly forbidden. All geometric logic must be derived by summing these explicit unit variables.
- **Constitutional Sync:** Hit-testing (Rule 3) and Wayland Input Regions must utilize the same unit variables as the visual delegates to ensure the "Interaction Orbit" is perfectly synchronized with the visual pixels at all times.

### 18. The Decoupled Catch Zone (Rule of Geometry Sovereignty)
To ensure absolute interaction reliability regardless of the dock's aesthetic configuration, mouse tracking must be decoupled from the visual panel background.
- **Full-Surface Coverage:** The QML `MouseArea` MUST NOT be anchored to the visual panel (`anchors.fill: parent`). Instead, it must cover the entire `root` Item (the full Wayland input region).
- **Thickness Independence:** This prevents "interaction suffocation" where thin or ultra-slim panels (e.g. 10px) would otherwise clip the mouse catch zone and cause 1.0x zoom click-through failures.

### 19. Kinetic Zoom Physics (The "Kremy" Transition)
All zoom transitions must exhibit a weighted, liquid motion to provide a premium user experience and prevent "stutter" during orbit exits.
- **Elastic Return:** When the mouse exits the interaction orbit, icons must not snap instantly to 1.0x. Instead, they must follow a smoothed easing curve (e.g., `Easing.OutBack` or `CubicBezier`) to gracefully return to their rest state.
- **Intensity Bridging:** This kinetic behavior is driven by an animated `_zoomIntensity` property, which bridges the gap between raw hit-test booleans and the visual zoom wave.

### 20. The Safe Spacing Mandate (Non-Overlapping UI)
To ensure professional readability and accessibility, all UI elements must respect physical boundaries and prevent visual collisions.
- **Adaptive Wrapping:** All descriptive labels and text blocks MUST utilize `wrapMode: Text.WordWrap` and `Layout.fillWidth: true` to gracefully adapt to window resizing.
- **Breathing Room Protocol:** Direct overlaps and negative margins (e.g., `topMargin: -8`) are strictly forbidden. Every element must possess its own logical territory.
- **Constraint Sovereignty:** When using horizontal layouts (`RowLayout`), width constraints or proportional scaling MUST be enforced to prevent sibling elements from "crushing" each other.

### 21. The Layer & Region Traceability Mandate
To prevent "Ghost" behaviors and ensure system maintainability, every visual layer and logical interaction region MUST be explicitly documented and numbered.
- **Unified Registry:** All new layers (QML) and regions (C++) must be assigned a unique ID and documented with a standardized header (e.g., `// --- Layer #: [Name] ---`).
- **The "Ghost Sheet" Protocol:** Any invisible metadata region (such as KWin blur regions) must be explicitly flagged at its calculation point. Bounding-box expansion bugs (Rule 18) are strictly forbidden; regions must represent the actual visual territory of the components.
- **Documentation Precedence:** This traceability logic is mandatory for all future development and refactors.

### 22. The Variable Documentation Mandate
To maintain the mathematical integrity of the dock's geometry, all variables used for sizing, spacing, and flooring MUST be explicitly documented.
- **Constitutional prefixing:** Variables representing the 5-Unit Stack (Rule 17) must be prefixed with `_unit` and follow the standardized commenting format.
- **Derived Logic:** Any variable derived from the 5-Unit Stack must explain its mathematical intent in the comments.
- **Registry Synchronization:** The `.claude/rules/variable-documentation.md` file must be updated whenever a new constitutional variable is introduced.
