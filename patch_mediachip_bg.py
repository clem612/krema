import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

old_bg = """    Rectangle {
        id: bgRect
        anchors.centerIn: parent
        // Margin from top/bottom to match the pill look
        width: parent.width - Kirigami.Units.smallSpacing * 2
        height: parent.height - Kirigami.Units.smallSpacing * 2
        
        radius: height / 2
        
        color: Qt.rgba(1, 1, 1, 0.05)
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1"""

new_bg = """    Rectangle {
        id: bgRect
        anchors.centerIn: parent
        
        // Exact same background math as IslandModule for consistency
        width: parent.width + (DockView.isVertical ? 0 : DockSettings.islandMargin * 2)
        height: parent.height + (DockView.isVertical ? DockSettings.islandMargin * 2 : 0)
        
        radius: DockSettings.islandCornerRadius === 0 ? Math.min(width, height) / 2 : DockSettings.islandCornerRadius
        
        color: Qt.rgba(255, 255, 255, 0.05)
        border.color: Qt.rgba(255, 255, 255, 0.1)
        border.width: 1"""

if old_bg in c:
    c = c.replace(old_bg, new_bg)
else:
    print("WARNING: Could not find old_bg in MediaChip.qml")

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)
