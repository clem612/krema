import os
import re

bug_report_path = "docs/bugs_report.md"
with open(bug_report_path, "r") as f:
    bugs = f.read()

new_bug = """
### [BUG] Media Chip Shows "No Media" Despite Active Playback
* **Status**: 🟢 Fixed
* **Identified Logic**: `src/shell/mpriscontroller.cpp` - `updatePlayers()` and `onPropertiesChanged()`.
* **Root Cause**: 
  1. `updatePlayers()` was blindly binding to the *first* MPRIS service it found in the D-Bus registry (e.g., a paused/idle Chromium instance) instead of the service that was actually `Playing`.
  2. The `Metadata` map in Qt D-Bus returns an inner `a{sv}` variant (specifically a `QDBusArgument`), which our code failed to unwrap properly when emitting properties.
* **The Proposal**: 
  1. Modify `updatePlayers()` to query `PlaybackStatus` for all registered MPRIS services and prioritize binding to the one whose status is `Playing`.
  2. Use `qMetaTypeId<QDBusArgument>()` to safely unwrap the variant and extract `xesam:title`.
* **Trials**:
  - Trial 1 (Unwrapping Metadata): Successfully fixed missing titles for active players, but exposed the Chromium binding issue.
  - Trial 2 (Priority Binding): Successfully bound to `ryotunes` and extracted "The Jester and The Queen" metadata.
"""
bugs += new_bug
with open(bug_report_path, "w") as f:
    f.write(bugs)

work_state_path = ".claude/work-state.md"
with open(work_state_path, "r") as f:
    ws = f.read()

ws = re.sub(r'(\*\*Current Status:\*\*).*', r'\1 Debugging MPRIS Controller. Fixed metadata parsing and active player priority logic.', ws)

with open(work_state_path, "w") as f:
    f.write(ws)
