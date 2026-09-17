import re

with open('src/qml/components/MediaPopup.qml', 'r') as f:
    c = f.read()

# Make the popup height wrap its content
c = c.replace('width: 320\n    height: 400', 'width: 320\n    height: bgRect.implicitHeight')
c = c.replace('anchors.fill: parent\n            anchors.margins: 16', 'anchors.left: parent.left\n            anchors.right: parent.right\n            anchors.top: parent.top\n            anchors.margins: 16')
c = c.replace('Rectangle {\n        id: bgRect\n        anchors.fill: parent', 'Rectangle {\n        id: bgRect\n        width: parent.width\n        implicitHeight: popupLayout.implicitHeight + 32')
c = c.replace('ColumnLayout {\n            anchors.left', 'ColumnLayout {\n            id: popupLayout\n            anchors.left')

with open('src/qml/components/MediaPopup.qml', 'w') as f:
    f.write(c)
