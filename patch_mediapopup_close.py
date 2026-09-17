import re

with open('src/qml/components/MediaPopup.qml', 'r') as f:
    c = f.read()

# Make it close when mouse leaves popup and chip
c = c.replace('id: popupHoverHandler', 'id: popupHoverHandler\n        onHoveredChanged: {\n            if (!hovered && !hoverHandler.hovered) {\n                popup.close();\n            }\n        }')

with open('src/qml/components/MediaPopup.qml', 'w') as f:
    f.write(c)
