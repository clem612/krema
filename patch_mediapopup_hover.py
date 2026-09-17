import re

with open('src/qml/components/MediaPopup.qml', 'r') as f:
    c = f.read()

# Add a HoverHandler to the popup contentItem
hover_handler = """
    property bool isHovered: popupHoverHandler.hovered
    
    HoverHandler {
        id: popupHoverHandler
    }
    
    Rectangle {"""
c = c.replace('    Rectangle {', hover_handler, 1)

with open('src/qml/components/MediaPopup.qml', 'w') as f:
    f.write(c)
