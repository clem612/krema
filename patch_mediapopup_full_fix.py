import re

with open('src/qml/components/MediaPopup.qml', 'r') as f:
    c = f.read()

# Fix bgRect height
c = c.replace('implicitHeight: popupLayout.implicitHeight + 32', 'height: popupLayout.implicitHeight + 32\n        implicitHeight: popupLayout.implicitHeight + 32')

with open('src/qml/components/MediaPopup.qml', 'w') as f:
    f.write(c)
