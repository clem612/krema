import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

# Make MediaChip compute an optimal width
width_logic = """
    // Calculate optimal width based on height to preserve proportions
    property real optimalWidth: Math.max(180, root.height * 4.0) + (typeof DockSettings !== "undefined" ? DockSettings.islandMargin * 2 : 16)
    
    // We bind the width so that the Wayland panel knows how wide it needs to be.
    width: visible ? (typeof DockView !== "undefined" && DockView.isVertical ? optimalWidth : optimalWidth) : 0
"""
c = re.sub(r'// We bind the width so that the Wayland panel knows how wide it needs to be\..*?width: visible \? .*? : 0', width_logic, c, flags=re.DOTALL)

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)

with open('src/qml/main.qml', 'r') as f:
    c = f.read()

c = re.sub(
    r'width: visible \? \(DockView\.isVertical \? dockRow\.implicitWidth : 180 \+ \(DockSettings\.islandMargin \* 2\)\) : 0',
    r'width: visible ? (DockView.isVertical ? dockRow.implicitWidth : mediaChip.optimalWidth) : 0',
    c
)
c = re.sub(
    r'height: visible \? \(\!DockView\.isVertical \? dockRow\.implicitHeight : 180 \+ \(DockSettings\.islandMargin \* 2\)\) : 0',
    r'height: visible ? (!DockView.isVertical ? dockRow.implicitHeight : mediaChip.optimalWidth) : 0',
    c
)

with open('src/qml/main.qml', 'w') as f:
    f.write(c)
