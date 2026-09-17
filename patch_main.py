import re

with open('src/qml/main.qml', 'r') as f:
    c = f.read()

old_media_chip = """        MediaChip {
            id: mediaChip
            z: 2
            x: !DockView.isVertical ? (dockRow.x + dockRow.implicitWidth + dockRow.baseSpacing) : dockRow.x
            y: DockView.isVertical ? (dockRow.y + dockRow.implicitHeight + dockRow.baseSpacing) : dockRow.y
            width: visible ? (DockView.isVertical ? dockRow.implicitWidth : 180) : 0
            height: visible ? (!DockView.isVertical ? dockRow.implicitHeight : 180) : 0
        }"""

new_media_chip = """        MediaChip {
            id: mediaChip
            z: 2
            x: !DockView.isVertical ? (dockRow.x + dockRow.implicitWidth + dockRow.baseSpacing + DockSettings.islandMargin) : dockRow.x
            y: DockView.isVertical ? (dockRow.y + dockRow.implicitHeight + dockRow.baseSpacing + DockSettings.islandMargin) : dockRow.y
            width: visible ? (DockView.isVertical ? dockRow.implicitWidth : 180 + (DockSettings.islandMargin * 2)) : 0
            height: visible ? (!DockView.isVertical ? dockRow.implicitHeight : 180 + (DockSettings.islandMargin * 2)) : 0
        }"""

if old_media_chip in c:
    c = c.replace(old_media_chip, new_media_chip)
else:
    print("WARNING: Could not find media chip in main.qml")

with open('src/qml/main.qml', 'w') as f:
    f.write(c)
