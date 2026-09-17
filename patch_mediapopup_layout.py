import re

with open('src/qml/components/MediaPopup.qml', 'r') as f:
    c = f.read()

c = c.replace('height: bgRect.implicitHeight', 'height: popupLayout.implicitHeight + 32')
c = c.replace('width: parent.width\n        height: popupLayout.implicitHeight + 32\n        implicitHeight: popupLayout.implicitHeight + 32', 'anchors.fill: parent')

with open('src/qml/components/MediaPopup.qml', 'w') as f:
    f.write(c)
