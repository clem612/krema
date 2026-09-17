import re

with open('.claude/work-state.md', 'r') as f:
    c = f.read()

c = re.sub(
    r'- \*\*Fix Implemented:\*\* Added `media-skip-backward`.*?## Next Steps',
    r'- **Fix Implemented:** Added `media-skip-backward` and `media-skip-forward` buttons flanking the play/pause button.\n- **Media Chip Popup:** Implemented a full rich media hover popup (`MediaPopup.qml`).\n  - Extended the C++ `MprisController` with `length`, `position`, `volume`, `shuffle`, and `loopStatus` properties.\n  - Added a QTimer to track playback position in real-time.\n  - Created a glass-pill styled QtQuick Popup containing a large album art display, metadata, scrubber timeline, and interactive volume/shuffle/repeat controls.\n\n## Next Steps',
    c, flags=re.DOTALL
)

with open('.claude/work-state.md', 'w') as f:
    f.write(c)
