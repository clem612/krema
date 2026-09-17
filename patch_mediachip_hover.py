import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

# Add hover handler to the main MouseArea or the chip root
# Actually MediaChip's root is a QQC2.ItemDelegate or just an Item?
# MediaChip is a QQC2.Control or similar?
# Let's check what root is.
