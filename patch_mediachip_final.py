import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

# Fix the width calculation to natively include the margin if it wants to be an island
c = c.replace('width: visible ? (180) : 0', 'width: visible ? 180 + (DockView.isVertical ? 0 : DockSettings.islandMargin * 2) : 0')
c = c.replace('height: visible ? (180) : 0', 'height: visible ? 180 + (DockView.isVertical ? DockSettings.islandMargin * 2 : 0) : 0')

# Also fix the bgRect to just fill parent
new_bg = """    Rectangle {
        id: bgRect
        anchors.fill: parent
        
        radius: DockSettings.islandCornerRadius === 0 ? Math.min(width, height) / 2 : DockSettings.islandCornerRadius
        
        color: Qt.rgba(255, 255, 255, 0.05)
        border.color: Qt.rgba(255, 255, 255, 0.1)
        border.width: 1"""

old_bg_pattern = re.compile(r'    Rectangle \{\n        id: bgRect\n        anchors\.centerIn: parent.*?border\.width: 1', re.DOTALL)
c = re.sub(old_bg_pattern, new_bg, c)

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)
