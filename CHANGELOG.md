# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Dev-Autostart & Environment Injection:** Updated `justfile` to generate a development autostart entry (`~/.config/autostart/`) that synchronizes with the `just run` environment. Both the development launcher and autostart now inject `XDG_DATA_DIRS` and `QT_PLUGIN_PATH` into their `Exec` lines, ensuring local plugins and themes load correctly upon login.

### Fixed
- **Preview Geometry Sync:** Resolved "Altitude Confusion" via Absolute Sync, ensuring window preview thumbnails and vertical offsets are perfectly synchronized with zoomed icons.


## [0.8.0] - 2026-05-12

### Added
- **Interaction Flooring Constitution (Rule 17):** Implemented a rigorous 5-unit vertical stack (Floor, Indicator, Gap, Icon, Ceiling) to ensure absolute mathematical consistency between visual rendering and interaction logic.
- **State-Aware Geometry Engine (Rule 15):** New layout system that dynamically toggles between a stable grid (idle state) and recursive displacement (interactive state), resolving architectural race conditions and startup gaps.
- **Absolute Sync Hit-Testing:** Mathematically precise interaction engine that aligns mouse orbits 1:1 with visual zoomed pixels, eliminating interaction drift and deadzones.
- **Absolute Zoom Independence (Rule 5):** Strict decoupling of dock panel thickness from icon magnification, ensuring a stable geometric foundation during the parabolic zoom wave.
- **Multi-Monitor System:** Full support for Primary Only, All Screens, and Follow Active Screen modes with integrated per-screen settings overrides for size, edge, and style.
- **Modular Settings Interface:** Completely redesigned multi-page UI using Kirigami FormCards with a nested visual hierarchy for streamlined configuration.
- **Advanced Visual Materials:** Hardware-accelerated Acrylic and Mica-style background themes with real-time blur and noise control.
- **Split Mode Layout:** Native task management separating pinned launchers from active windows with a reactive etched-glass separator pill.
- **Ghost Input Region:** System-level mouse tracking that decouples Wayland interaction from visual panel geometry, ensuring icons remain interactive when visually overflowing thin panels.
- **Architectural Blueprint Mode:** Specialized diagnostic view with a synchronized high-contrast drafting grid for live geometry verification.
- **Keyboard Navigation Core:** Integrated support for Meta+F5 activation and full arrow-key dock navigation.
- **Workspace Awareness:** Native task filtering based on Virtual Desktops and Plasma Activities.
- **Distribution Packaging:** Integrated configuration support for Arch, Fedora (COPR), openSUSE (OBS), Debian, and Ubuntu.

### Fixed
- **Sticky Preview Conflict:** Resolved interaction deadlock where window previews would trap the mouse hover state, blocking neighboring icons (fixed via Trial 4: Icon-Gated Visibility).
- **1.0x Interaction Orbit:** Resolved "Click-through" bug where thin panels would physically clip the interaction zone (fixed via Rule 18: Decoupled Catch Zone).
- **Blur Expansion Bug:** Isolated KWindowEffects background blur to the visual panel area, preventing frosted "ghost halos" in interaction deadzones.
- **Preview Misalignment:** Synchronized vertical thumbnail offsets using the `visualIconTop` bridge, ensuring previews float at a consistent altitude regardless of zoom state.
- **Settings UI Collision:** Resolved text overlaps in the configuration pages by implementing the **Safe Spacing Mandate (Rule 20)** and removing negative margins.
- **Shadow Clipping:** Restored natural volumetric shadow fade by correctly binding geometry to SDF padding.

## [0.7.0] - 2026-03-28

### Added

- Progress bar on dock icons for apps reporting task progress (e.g. file copy in Dolphin)
- Badge display mode setting: Number, Dot, or Off
- Attention animation duration setting with auto-stop (default 5 seconds, 0 for infinite)
- "Clear Notifications" context menu action for manually dismissing notification badges
- Do Not Disturb integration — attention animations are suppressed when system DND is active

### Fixed

- Notification badges now always clear on focus, even when SmartLauncher count was previously active
- Attention animation no longer runs infinitely for persistent notification badges
- Dodge mode now correctly resumes after closing the settings window

## [0.6.0] - 2026-03-02

### Added

- Notification badge count on dock icons (via D-Bus RegisterWatcher and SmartLauncher Unity API)
- SNI (StatusNotifierItem) NeedsAttention monitoring for tray-based attention requests
- Six attention animation styles: Bounce, Wiggle, Pulse, Glow, Dot color, and Blink
- Attention animation setting in Appearance settings page
- Single-instance enforcement — launching Krema again while it's already running is now silently ignored
- Automatic startup on KDE Plasma login
- Desktop launcher entry visible in application menu

## [0.5.1] - 2026-03-01

### Fixed

- Fixed icon rendering on HiDPI displays when icon normalization or icon scale is active
- Fixed dock edge trigger unreachable in AutoHide/DodgeWindows mode when KDE panel occupies the screen edge

## [0.5.0] - 2026-02-22

Initial public release.

### Added

- Pinned app launcher with drag-and-drop reordering
- Running app tracking via KDE Task Manager
- Parabolic zoom animation on hover
- Live window preview on hover via PipeWire
- Middle-click to close windows from preview
- Context menu with pin/unpin, new instance, and quit actions
- AutoHide, DodgeWindows, and AlwaysVisible visibility modes
- Floating dock style with acrylic blur background
- Icon size normalization for visually consistent icons
- Icon scale setting for uniform icon padding
- Notification badge indicators
- KDE Plasma 6 native integration (Layer Shell, KConfig, Kirigami)
- Full keyboard accessibility (Meta+F5, arrow navigation, focus ring)
- Screen reader support via AT-SPI accessible properties
- Settings UI with Kirigami FormCard delegates
