import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

c = c.replace('mediaPopup.open();', 'mediaPopup.visible = true;')
c = c.replace('mediaPopup.close();', 'mediaPopup.visible = false;')

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)
