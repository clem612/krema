import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

popup_code = """
    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            if (hovered) {
                popupTimer.start();
            } else {
                popupTimer.stop();
                if (!mediaPopup.contentItem.hovered && !mediaPopup.hovered) {
                    mediaPopup.close();
                }
            }
        }
    }
    
    Timer {
        id: popupTimer
        interval: 400
        onTriggered: {
            if (hoverHandler.hovered) {
                mediaPopup.open();
            }
        }
    }
    
    MediaPopup {
        id: mediaPopup
        y: -height - 10
        x: (root.width - width) / 2
    }
"""

c = re.sub(r'(Item \{\n    id: root.*?\n)', r'\1' + popup_code, c, flags=re.DOTALL)

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)
