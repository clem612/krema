import re

with open('src/qml/main.qml', 'r') as f:
    c = f.read()

# Add MediaPopup at the end of main.qml, next to tooltipItem
popup = """
    // --- Media Popup ---
    Components.MediaPopup {
        id: mainMediaPopup
        z: 999
        visible: false
        
        // Position it relative to the media chip
        x: {
            if (typeof mediaChip === "undefined" || !mediaChip.visible) return 0;
            // Abs X is dockPanel + dockRow + mediaChip + internal offsets
            let chipAbsX = dockPanel.x + dockRow.x + mediaChip.x;
            return chipAbsX + (mediaChip.width - width) / 2;
        }
        
        y: {
            if (typeof mediaChip === "undefined" || !mediaChip.visible) return 0;
            let sp = Kirigami.Units.largeSpacing;
            let chipAbsY = dockPanel.y + dockRow.y + mediaChip.y;
            
            if (DockView.edge === 0) return chipAbsY + mediaChip.height + sp; // Top
            if (DockView.edge === 1) return chipAbsY - height - sp; // Bottom
            return chipAbsY - height - sp;
        }
    }
"""

c = c.replace('id: tooltipItem;', popup + '\n    Rectangle {\n        id: tooltipItem;')

with open('src/qml/main.qml', 'w') as f:
    f.write(c)
