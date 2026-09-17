import re

with open('.claude/product-quality-lessons.md', 'r') as f:
    c = f.read()

lesson = """
## QML Duplicate ID Instant Failure
**Context:** When inserting new settings into `PanelPage.qml`, I reused an `id: radiusSlider` that was already used at the bottom of the page.
**Failure:** QML strict-aborts on duplicate IDs. The entire `SettingsDialog.qml` stack trace failed silently behind the C++ wrapper, resulting in a completely blank page for the user.
**Lesson:** Always prefix component IDs with their specific domain (e.g. `islandRadiusSlider` instead of `radiusSlider`) when injecting new controls into existing dense QML layouts.
"""

if "QML Duplicate ID Instant Failure" not in c:
    c += lesson

with open('.claude/product-quality-lessons.md', 'w') as f:
    f.write(c)
