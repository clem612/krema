import re

with open('src/qml/main.qml', 'r') as f:
    c = f.read()

# Replace MediaChip x calculation
c = re.sub(
    r'x: !DockView\.isVertical \? \(dockRow\.x \+ dockRow\.implicitWidth \+ dockRow\.baseSpacing \+ DockSettings\.islandMargin\) : dockRow\.x',
    r'x: !DockView.isVertical ? (dockRow.x + dockRow.childrenRect.width + dockRow.baseSpacing) : dockRow.x',
    c
)

with open('src/qml/main.qml', 'w') as f:
    f.write(c)
