import re

with open('src/qml/main.qml', 'r') as f:
    c = f.read()

# Replace MediaChip x calculation again
c = re.sub(
    r'x: !DockView\.isVertical \? \(dockRow\.x \+ dockRow\.childrenRect\.width \+ dockRow\.baseSpacing\) : dockRow\.x',
    r'x: !DockView.isVertical ? (dockRow.x + dockRow.childrenRect.x + dockRow.childrenRect.width + dockRow.baseSpacing) : dockRow.x',
    c
)
# And for Y
c = re.sub(
    r'y: DockView\.isVertical \? \(dockRow\.y \+ dockRow\.implicitHeight \+ dockRow\.baseSpacing \+ DockSettings\.islandMargin\) : dockRow\.y',
    r'y: DockView.isVertical ? (dockRow.y + dockRow.childrenRect.y + dockRow.childrenRect.height + dockRow.baseSpacing) : dockRow.y',
    c
)

with open('src/qml/main.qml', 'w') as f:
    f.write(c)
