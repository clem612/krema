# Work State

> A file for passing task status between sessions. Updated at the end of each session.
> Loaded once at the start of a session via @-import in CLAUDE.md (modifications during a session are not reflected in the current context).

## Current Milestone

M8 Completed → Preparing for M9 (Widget System + System Tray)

## Completed Items

- [x] M1-M7: Fully completed
- [x] Implemented Accessibility Stage 5 + Keyboard Navigation
- [x] E2E Testing Infrastructure (PoC for 10 mechanisms)
- [x] Released v0.7.0
- [x] M8a-M8d: Virtual Desktops, Multi-Monitor, Per-Screen Settings, Follow Active
- [x] Multi-distro packaging infrastructure established
  - COPR (Fedora 42/43/Rawhide): 6/6 builds successful
  - OBS (openSUSE Tumbleweed/Slowroll, Fedora, Debian 13, Ubuntu 25.04-26.04): 17/17 builds successful
  - Launchpad PPA (Ubuntu 25.10 questing, 26.04 resolute): Published
  - AUR: Maintained existing operation
- [x] Cross-distro build compatibility
  - LayerShellQt setDesiredSize compile-time detection (KREMA_COMPAT_NO_LAYERSHELL_DESIRED_SIZE)
  - QString QT_NO_CAST_FROM_ASCII compatibility
  - openSUSE ninja/autostart path conditional handling
- [x] Added multi-distro deployment pipeline to /release skill
- [x] Updated README distro badges + installation guide
- [x] SettingsWindow Refactoring: Replaced polling loop with direct configViewItem reference

## Known Issues

- AllScreens/FollowActive: Needs verification on actual dual-monitor setup
- QML fade/slide transitions not implemented (currently instant show/hide)
- Per-screen settings UI page not implemented (backend only)
- PipeWire global stream capture not implemented

## On Hold Items

- [ ] **Settings/Dolphin Identity Crisis**: Wayland App ID mismatch (org.kde.systemsettings vs systemsettings) causing "Ghost Gaps" and center-icon deadzones. Identity Bridge and Fuzzy Hit-Test (10px) implemented but require further deep architectural analysis to fix completely.

## Next Tasks

- Review M8 full release (v0.8.0)
- M9: Widget System + System Tray
