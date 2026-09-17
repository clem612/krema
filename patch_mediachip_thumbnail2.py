import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

c = c.replace(
    'radius: Math.max(0, bgRect.radius - bgRect.currentMargin)',
    'radius: bgRect.radius'
)

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)
