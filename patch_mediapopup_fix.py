with open('src/qml/components/MediaPopup.qml', 'r') as f:
    c = f.read()

c = c.replace('id: popup\n    visible: falseHoverHandler', 'id: popupHoverHandler')

with open('src/qml/components/MediaPopup.qml', 'w') as f:
    f.write(c)
