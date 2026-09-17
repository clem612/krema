import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

# Change optimalWidth to use mainLayout.implicitWidth
optimal_logic = """
    // Calculate optimal width based on content
    property real optimalWidth: Math.max(180, Math.min(450, (mainLayout ? mainLayout.implicitWidth + (bgRect.currentMargin * 2) : 180)))
    
    // We bind the width so that the Wayland panel knows how wide it needs to be.
    width: visible ? (typeof DockView !== "undefined" && DockView.isVertical ? optimalWidth : optimalWidth) : 0
"""
c = re.sub(r'// Calculate optimal width based on height to preserve proportions.*?width: visible \? .*? : 0', optimal_logic, c, flags=re.DOTALL)

# Add id to RowLayout and change anchors
c = re.sub(
    r'RowLayout \{\s*anchors\.fill: parent\s*anchors\.margins: bgRect\.currentMargin',
    r'RowLayout {\n            id: mainLayout\n            anchors.fill: parent\n            anchors.margins: bgRect.currentMargin',
    c
)

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)
