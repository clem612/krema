@.claude/work-state.md
@.claude/rules/token-efficiency.md

# Gemini Project Context: Krema Dock

## 1. Project Identity & Vision
Krema is a dedicated dock for **KDE Plasma 6 (Wayland)**. It is the "spiritual successor" to Latte Dock, focused on performance, visual smoothness, and deep KDE integration.

## 2. Session Protocol (Mandatory)
Before answering any prompts, Gemini must:
1. **The Master Mind Review:** Read `.claude/work-state.md` to identify current tasks and the knowledge index.
2. **Technical Memory Refresh:** Follow links in `work-state.md` to read `docs/bugs_report.md` and relevant research logs in `docs/research/`.
3. **Verify Progress & Vision:** 
   - Find the current milestone in `ROADMAP.md` (marked with ⬅️).
   - Cross-reference the task with `ARCHITECTURE Mandate.md` to ensure the proposed logic obeys the mathematical laws.
4. **On Session Close:** Synchronize ALL tracking files:
   - Update `work-state.md` (Status & History).
   - Update `ROADMAP.md` (Milestone progress).
   - Update `docs/bugs_report.md` (New trials, failures, or fixes).
   - Update/Create logs in `docs/research/` (New architectural discoveries or KDE research).
5. **Transparency & Proposal Phase:** Before any file edit, Gemini must provide a "Refactor Proposal":
   - **Identified Logic:** What specific lines look "optimizable"?
   - **Functional Assessment:** What does this logic currently achieve (e.g., handles separators, fixes Electron icons)?
   - **Optimization Strategy:** How will the new code preserve this EXACT behavior while being more efficient?
   - **Confirmation:** Wait for user approval before applying.

## 3. Development Workflow
- **Never guess KDE APIs.** If an API is unknown, verify it via `/usr/include/` headers.
- **Scale Check:** - Small: 1-2 files, existing APIs.
  - Medium: New KDE APIs or 3+ files (Requires header verification).
  - Large: New modules or 3+ new files (Requires architectural audit).
- **Testing:** Use **kwin-mcp** for scenario execution. Work is "Done" only when all scenarios pass and `git diff` shows no regression.

## 4. Technical Standards
- **Stack:** C++23, Qt 6, KDE Frameworks 6 (KF6).
- **Performance:** 60fps mandatory. Use GPU-native paths (PipeWire DMA-BUF, QRhi). Avoid CPU→GPU copies.
- **KDE Integration:**
  - Prefer KDE APIs (Kirigami / Kirigami Addons) over plain QQC2.
  - Use `Kirigami.Theme` and `Kirigami.Units`. No hardcoded colors/sizes.
  - **Configuration:** Use KConfigXT (.kcfg schemas). *Note: KConfigSkeleton(Singleton=false) requires manual `load()`.*
  - **Singletons:** Use `qmlRegisterSingletonType` with a factory for multi-engine environments (Dock + Settings).
- **Architecture:** - **Functional Preservation:** Optimization must be "Non-Subtractive."
  - **Respect the "Mess":** If code handles a specific app (Steam, Neshi), it is a "Functional Constraint." Refactor syntax, but never the logic branch.

## 5. Wayland & Layer-Shell Rules
- **Surfaces:** `surfaceHeight` must account for animation overflow (zoom/bounce).
- **Input Region:** Must be explicitly set; an empty QRegion accepts ALL input (bad).
- **Lifecycle:** ALWAYS null-check `screen()` (nullptr on virtual compositors).
- **Focus:** Multi-surface apps should have a single surface holding `KeyboardInteractivityExclusive`.

## 6. Documentation & SEO Strategy
- **Keywords:** latte dock alternative, kde plasma 6 dock, kde dock wayland.
- **Latte Dock:** Refer to Krema as a "spiritual successor"—never a "fork" or "clone."

## 7. Anti-Patterns to Prevent
- **JS Timers:** Do not use for business logic; use Qt/KDE signals (e.g., `dataChanged`) instead.
- **JS Array Assignment:** Do not replace `Repeater.model` with raw JS arrays (destroys delegates).
- **Async State:** Avoid polling; subscribe to KDE/Qt signals. Use Timers only for UI debouncing/delays.
- **Hitbox Math:** Never use `currentEdge += itemSize` for hovers. Always use **"Center-Distance Math"** (The Ghost Grid Rule) to preserve gaps.

## 8. Functional Invariants (Mandatory Preservation)
- **State Stability (The Safe Floor):** No optimization may allow UI-critical variables (width, height, scale, overflow) to reach 0 or null unless destroying the dock.
- **Heterogeneous Model Logic:** Docks are not uniform. Logic must account for separators and indicators. Assuming all items are identical Icons is a BUG.
- **Verified Feature Integrity:** Working features (Steam icons, dash indicators) must be flagged in the "Proposal Phase" if their code path changes.

## 9. Documentation Standards
- **Architectural Mandates:** ALL geometry, interaction, and UI slider logic MUST strictly adhere to the rules defined in `ARCHITECTURE Mandate.md`. This file is the absolute source of truth for dock symmetry and hit-test math.
- **English-Only:** ALL documentation files (`.md`), including `GEMINI.md`, `ROADMAP.md`, `.claude/work-state.md`, and any session artifacts, MUST be written exclusively in English. If existing documentation is in another language, translate it to English before editing.

## 10. Surgical Edit Mandate (Anti-Truncation Protocol)
- **No Full-File Overwrites:** You are strictly forbidden from using `write_file` or attempting to replace the entirety of an existing file.
- **Targeted Diffs Only:** All modifications to existing files MUST be made using surgical `replace` commands targeting specific, small blocks of lines (less than 50 lines per turn).
- **Chunking Large Refactors:** If a refactor requires modifying more than 50 lines of code, you must break the task into multiple, isolated steps. State your plan and await user confirmation before proceeding to the next chunk.
- **Preserve Baseline Integrity:** Never attempt to rewrite an entire geometry engine or logic block in one prompt. Modify one property, one function, or one visual block at a time to ensure the C++ compiler and QML engine remain stable between edits.

## 11. Proactive Reporting Mandate
- **Inform Before Fix:** If you discover a bug, binding loop, rendering glitch, or mathematical inconsistency via terminal logs, visual inspection, or research, you MUST report it to the user and explain the proposed fix BEFORE applying any changes.
- **Zero Silent Fixes:** Never apply "silent fixes" even if they seem trivial, obvious, or internal. Every change to the codebase must be preceded by a report of the identified issue and an approved proposal.

## 12. The Geometry Debugging Mandate
- **Unified Diagnostic Flag:** All components that possess physical shape, form, or interactive boundaries MUST support the `--debug-geom` runtime flag.
- **Comprehensive Logging:** When active, the component must log its critical geometry (`X`, `Y`, `Width`, `Height`) to the terminal whenever it changes. This applies to the Panel, Icons, Indicators, Separators, Mouse Areas, and Wayland Input Regions.
- **Inter-Icon Gap Measurement:** The system must explicitly measure and expose any "Dead Zones" or "Inter-Icon Gaps" where the mouse is inside the dock container but not hovering a specific icon.
- **Future Proofing:** Any new visual or interactive feature added to the dock must implement this logging protocol as part of its initial commit.

## 13. The History & Organization Mandate
- **Immutable History Log for Research & Bugs:** ALL `Research` and `Bug Reports` documentation files (`docs/research/*.md`, `docs/bugs_report.md`) MUST be organized chronologically from **Old to New** (Top to Bottom).
- **Non-Subtractive Updates:** Never delete or overwrite previous research or bug findings in these files. New information must be appended to the bottom of the file. Specify and organize the info so it is clear which info is outdated and which is new (e.g., mark old sections as `[OUTDATED]` and new as `[CURRENT]`). This ensures we never go backwards in current or future sessions.
- **Mandates are Absolute Truths:** The Old-to-New history rule does **NOT** apply to Mandate files (like `ARCHITECTURE Mandate.md` or `GEMINI.md`). Mandates are absolute, uncluttered truths and must not be cluttered with history.
- **Explicit Promotion Required:** NEVER promote any math, logic, or code structure to `ARCHITECTURE Mandate.md` without explicit, direct approval from the user. You may *suggest* a promotion once a feature is proven 100% working and accurate, but you must wait for the "Go".
