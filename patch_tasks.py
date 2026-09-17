import re

with open('/home/clem/.gemini/antigravity/brain/86357bb1-438f-4264-aef3-b2a75747513f/task.md', 'r') as f:
    c = f.read()

c = c.replace('`[/]` Expand `MprisController` C++ model', '`[x]` Expand `MprisController` C++ model')
c = c.replace('`[ ]` Add `length`', '`[x]` Add `length`')
c = c.replace('`[ ]` Add `position`', '`[x]` Add `position`')
c = c.replace('`[ ]` Add `volume`', '`[x]` Add `volume`')
c = c.replace('`[ ]` Add `shuffle`', '`[x]` Add `shuffle`')
c = c.replace('`[ ]` Add `loopStatus`', '`[x]` Add `loopStatus`')
c = c.replace('`[ ]` Implement D-Bus fetching', '`[x]` Implement D-Bus fetching')
c = c.replace('`[ ]` Implement D-Bus setters', '`[x]` Implement D-Bus setters')

c = c.replace('`[ ]` Create QML UI for Media Popup', '`[x]` Create QML UI for Media Popup')
c = c.replace('`[ ]` Add Hover logic', '`[x]` Add Hover logic')
c = c.replace('`[ ]` Create `MediaPopup.qml`', '`[x]` Create `MediaPopup.qml`')
c = c.replace('`[ ]` Hook up new C++ properties', '`[x]` Hook up new C++ properties')

c = c.replace('`[ ]` Testing & Verification', '`[x]` Testing & Verification')
c = c.replace('`[ ]` Test with `krema_icon_sandbox`', '`[x]` Test with `krema_icon_sandbox`')

with open('/home/clem/.gemini/antigravity/brain/86357bb1-438f-4264-aef3-b2a75747513f/task.md', 'w') as f:
    f.write(c)
