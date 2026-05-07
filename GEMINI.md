# Gemini Project Context: Krema Dock

## 1. Project Identity & Vision
Krema is a dedicated dock for **KDE Plasma 6 (Wayland)**. It is the "spiritual successor" to Latte Dock, focused on performance, visual smoothness, and deep KDE integration.

## 2. Session Protocol (Mandatory)
Before answering any prompts, Gemini must:
1. **Check Work State:** Read `.claude/work-state.md` to identify current tasks and known issues.
2. **Verify Progress:** Check `ROADMAP.md` for the current milestone (marked with ⬅️).
3. **On Session Close:** Update `work-state.md` and `ROADMAP.md` with progress.
4. **Transparency & Proposal Phase:** Before any file edit, Gemini must provide a "Refactor Proposal":
    - **Identified Logic:** What specific lines look "optimizable"?
    - **Functional Assessment:** What does this logic currently achieve (e.g., handles separators, fixes Electron icons)?
    - **Optimization Strategy:** How will the new code preserve this EXACT behavior while being more efficient?
    - **Confirmation:** Wait for user approval before applying.

## 3. Development Workflow
### Phase 1: Planning & Verification
- **Never guess KDE APIs.** If an API is unknown, verify it via `/usr/include/` headers.
- **Scale Check:** - Small: 1-2 files, existing APIs.
    - Medium: New KDE APIs or 3+ files (Requires header verification).
    - Large: New modules or 3+ new files (Requires architectural audit).

### Phase 2: Implementation & Testing
- Use **kwin-mcp** for scenario execution.
- Work is only "Done" when all scenarios pass and `git diff` shows no regression in `tests/e2e/`.

## 4. Technical Standards
- **Stack:** C++23, Qt 6, KDE Frameworks 6 (KF6).
- **Tooling:** `CMakeLists.txt` for builds, `justfile` for task automation.
- **Performance:** - 60fps mandatory (declarative Qt Quick animations only).
    - Use GPU-native paths (PipeWire DMA-BUF, QRhi hardware backend).
    - Avoid CPU→GPU texture copies.
- **KDE Integration:**
    - Prefer KDE APIs over plain Qt APIs.
    - Use `Kirigami.Theme` and `Kirigami.Units`. No hardcoded colors/sizes.
    - Use KConfigXT for settings (.kcfg schemas).
- **Architecture & Data Flow:**
    - **Functional Preservation:** Existing logic is assumed to be an intentional fix for a fragile edge case. Optimization is only permitted if it is "Non-Subtractive."
    - **Respect the "Mess":** If a piece of code handles a specific app (like Steam or Neshi), it is a "Functional Constraint," not "Technical Debt." Refactor the *syntax*, but never the *logic branch*.

## 5. Wayland & Layer-Shell Rules (Critical)
- **Surfaces:** `surfaceHeight` must account for animation overflow (zoom/bounce).
- **Input Region:** Must be explicitly set; an empty QRegion accepts ALL input (bad for docks).
- **Mouse Tracking:** Use a single authoritative level at the Panel level, not individual items.
- **Life Cycle:** Null-check `screen()` (can be null on virtual compositors).

## 6. Documentation & SEO Strategy
- Use `marketing/strategy.md` for keywords. 
- **Latte Dock:** Refer to Krema as a "spiritual successor"—never a "fork" or "clone."
- Updates to `CMakeLists.txt` (dependencies) must also be updated in `packaging/arch/PKGBUILD`.

## 7. Anti-Patterns to Prevent
- **JS Timers:** Do not use for business logic; use Qt/KDE signals instead.
- **JS Array Assignment:** Do not replace `Repeater.model` with raw JS arrays (destroys/recreates delegates). Use `ListModel` for GPU resources.
- **Hardcoding UI:** Never use `GridLayout` for settings; use `FormCard` (Kirigami Addons).
- **Hitbox Cumulative Math:** Never use a cumulative loop (`currentEdge += itemSize`) to detect hovers. This mathematically deletes gaps and causes the hover to "stick" to the left edges.
- **The Ghost Grid Rule:** Always use "Center-Distance Math" for hitboxes. Calculate a mathematically perfect, unscaled, and static `itemCenterX` in the Repeater. Then, inside `updateHoveredItem`, check if the mouse distance from that static center is within a percentage (e.g., 90%) of the dynamic visual width (`(DockSettings.iconSize * item.currentScale) / 2`). This prevents binding loops and preserves actual gaps.

## 8. Functional Invariants (Mandatory Preservation)
- **State Stability (The Safe Floor):** No optimization may allow UI-critical variables (width, height, scale, overflow) to reach 0 or null unless the dock is explicitly being destroyed. 
- **Heterogeneous Model Logic:** Docks are not uniform. Logic must account for separators, indicators, and placeholders. If a loop assumes all items are identical Icons, it is a bug.
- **Verified Feature Integrity:** If a feature (e.g., Steam icons, dash indicators) is currently working, any change that alters its code path must be flagged in the "Proposal Phase" for manual verification.
