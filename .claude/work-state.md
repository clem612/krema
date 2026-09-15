# Work State

## Current Milestone (from ROADMAP.md)
⬅️ Feature: Ryoku Shell Integration (Media Chip) & Visual Polish

## Active Task
- **Media Chip Transport Controls:** The user noted the Media Chip lacked next/previous buttons.
- **Fix Implemented:** Added `media-skip-backward` and `media-skip-forward` buttons flanking the play/pause button.
- **Media Chip Popup:** Implemented a full rich media hover popup (`MediaPopup.qml`).
  - Extended the C++ `MprisController` with `length`, `position`, `volume`, `shuffle`, and `loopStatus` properties.
  - Added a QTimer to track playback position in real-time.
  - Created a glass-pill styled QtQuick Popup containing a large album art display, metadata, scrubber timeline, and interactive volume/shuffle/repeat controls.

## Next Steps
- Awaiting User Approval to commit.
