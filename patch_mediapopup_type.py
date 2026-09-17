import re

with open('src/qml/components/MediaPopup.qml', 'r') as f:
    c = f.read()

c = c.replace('QQC2.Popup {', 'Item {', 1)
c = c.replace('background: Item {}', '')
c = c.replace('padding: 0', '')
c = c.replace('margins: 0', '')
c = c.replace('    HoverHandler {\n        id: popupHoverHandler\n        onHoveredChanged: {\n            if (!hovered && !chipHoverHandler.hovered) {\n                popup.close();\n            }\n        }\n    }', '    HoverHandler {\n        id: popupHoverHandler\n        onHoveredChanged: {\n            if (!hovered && chipHoverHandler && !chipHoverHandler.hovered) {\n                popup.visible = false;\n            }\n        }\n    }')
c = c.replace('id: popup', 'id: popup\n    visible: false')

with open('src/qml/components/MediaPopup.qml', 'w') as f:
    f.write(c)
