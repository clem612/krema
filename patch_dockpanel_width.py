import re

with open('src/qml/main.qml', 'r') as f:
    c = f.read()

# Replace in _actualContentWidth
c = re.sub(
    r'let baseW = Math\.max\(dockRow\.implicitWidth \+ mediaW \+ 32, Kirigami\.Units\.gridUnit \* 6\)',
    r'let baseW = Math.max(dockRow.childrenRect.width + mediaW + 32, Kirigami.Units.gridUnit * 6)',
    c
)
# Replace in _actualContentHeight
c = re.sub(
    r'let baseH = Math\.max\(dockRow\.implicitHeight \+ mediaH \+ 32, Kirigami\.Units\.gridUnit \* 6\)',
    r'let baseH = Math.max(dockRow.childrenRect.height + mediaH + 32, Kirigami.Units.gridUnit * 6)',
    c
)

with open('src/qml/main.qml', 'w') as f:
    f.write(c)
