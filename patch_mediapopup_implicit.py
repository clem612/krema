import re

with open('src/qml/components/MediaPopup.qml', 'r') as f:
    c = f.read()

# Replace Album Art Rectangle layout logic
c = c.replace('Layout.preferredHeight: 320 - 32', 'implicitHeight: width')

with open('src/qml/components/MediaPopup.qml', 'w') as f:
    f.write(c)
