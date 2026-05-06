# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Multi-monitor support with three modes: Primary Only, All Screens, and Follow Active Screen
- Per-screen settings override: each monitor can have independent icon size, edge, visibility mode, background, and pinned launchers
- Follow Active Screen mode with three trigger types: mouse position, active window focus, and composite
- Virtual desktop filtering: show windows from current desktop only, or all desktops with dimmed icons for other desktops
- Fedora (COPR), openSUSE (OBS), Debian, and Ubuntu packaging support
- Compile-time LayerShellQt API detection for cross-distribution compatibility
- "Reserve screen space" toggle for Always Visible mode, allowing the dock to physically block maximized windows (Exclusive Zone) or allow them to slide underneath (Latte-style "Windows Can Cover")
- "Reserve screen space" toggle for Always Visible mode, which dynamically adapts to floating padding to ensure maximized windows stop exactly at the dock's edge
- Strict "Split Mode" task management: creates two distinct zones for pinned launchers and unpinned running windows
- Reactive etched-glass separator pill that dynamically centers itself in the gap between pinned and active zones
- Auto-Sort Enforcement: Drag-and-drop now respects the boundary, physically preventing unpinned apps from entering the pinned section
- Architectural "Blueprint Mode": Features a translucent navy background with a high-contrast white drafting grid that automatically centers and synchronizes during live panel resizing
- Enhanced Settings UI: Improved layout consistency using Kirigami units, with instant configuration persistence and "Dock Gravity" to keep icons anchored to the panel edge
- System-level "Ghost" input region that decouples Wayland mouse tracking from visual panel geometry, ensuring icons remain interactive when visually overflowing thin panels
- Proportional "Skin" hitbox logic that dynamically adjusts the clickable area of each icon based on its current visual zoom state
- Consolidated icon-related settings (Size, Spacing, Zoom, Scale, and Attention) into a unified Icons page for a more streamlined configuration experience
- Implemented a nested visual hierarchy in the Settings sidebar, using specific indentation and icon scaling to clearly distinguish sub-pages from top-level categories.

### Fixed

- Build compatibility with LayerShellQt < 6.4 (Ubuntu 25.04, Debian 13)
- Build compatibility with strict `QT_NO_CAST_FROM_ASCII` flag on non-Arch distributions
- Dock icon detection now resolves app icons more reliably by combining launcher URL, desktop entry ID variants, and display-name fallbacks
- Running Steam game windows now keep game-specific icons instead of reverting to the generic Steam icon after dock reordering
- Drag ghost icon now uses the same task icon source as dock items, preventing temporary icon swaps while reordering
- Fixed blurry, low-resolution window icons for Steam/Proton games by prioritizing system theme icons over raw window pixels
- Eliminated the "Drag Proxy" discrepancy where dock items would change quality or transparency while being reordered
- Improved reliability of screen space reservation during startup by debouncing layout updates, preventing race conditions with the window manager
- Eliminated "Model Ghosting" where the dock failed to visually update after pin/unpin actions without a window refresh
- Corrected separator alignment math to ensure pixel-perfect centering during parabolic zoom
- Resolved "Unsupported Interceptor" property warnings by consolidating animation behaviors
- Resolved "ConfigurationView not found" error by updating C++ lookup logic and QML function signatures to correctly catch backend arguments
- Fixed window crashes and layout breakage in the Settings Dialog caused by duplicate layout containers and mismatched closing braces
- Standardized Settings window header icons to prevent missing asset placeholders (the "Question Mark" bug)

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
