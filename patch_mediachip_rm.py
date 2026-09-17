import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

# Remove the inline MediaPopup
c = re.sub(r'    MediaPopup \{\s*id: mediaPopup.*?\n    \}', '', c, flags=re.DOTALL)

# Update hover logic
c = c.replace('mediaPopup.visible = true;', 'if (typeof mainMediaPopup !== "undefined") { mainMediaPopup.chipHoverHandler = hoverHandler; mainMediaPopup.visible = true; }')
c = c.replace('!mediaPopup.isHovered', 'typeof mainMediaPopup !== "undefined" && !mainMediaPopup.isHovered')
c = c.replace('mediaPopup.visible = false;', 'if (typeof mainMediaPopup !== "undefined") mainMediaPopup.visible = false;')

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)
