import re

with open('src/qml/components/IslandModule.qml', 'r') as f:
    c = f.read()

# Make it use DockSettings.islandMargin and DockSettings.islandCornerRadius
c = c.replace('implicitWidth: DockView.isVertical ? parent.width : container.implicitWidth + 16',
              'implicitWidth: DockView.isVertical ? parent.width : container.implicitWidth + (DockSettings.islandMargin * 2)')
c = c.replace('implicitHeight: DockView.isVertical ? container.implicitHeight + 16 : container.implicitHeight',
              'implicitHeight: DockView.isVertical ? container.implicitHeight + (DockSettings.islandMargin * 2) : container.implicitHeight')

c = c.replace('x: DockView.isVertical ? 0 : -8', 'x: DockView.isVertical ? 0 : -DockSettings.islandMargin')
c = c.replace('y: DockView.isVertical ? -8 : 0', 'y: DockView.isVertical ? -DockSettings.islandMargin : 0')

c = c.replace('x: DockView.isVertical ? 0 : 8', 'x: DockView.isVertical ? 0 : DockSettings.islandMargin')
c = c.replace('y: DockView.isVertical ? 8 : 0', 'y: DockView.isVertical ? DockSettings.islandMargin : 0')

c = c.replace('radius: Math.min(width, height) / 2',
              'radius: DockSettings.islandCornerRadius === 0 ? Math.min(width, height) / 2 : DockSettings.islandCornerRadius')

with open('src/qml/components/IslandModule.qml', 'w') as f:
    f.write(c)
