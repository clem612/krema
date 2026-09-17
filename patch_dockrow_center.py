import re

with open('src/qml/main.qml', 'r') as f:
    c = f.read()

# Replace in dockRow x
c = re.sub(
    r'let totalW = implicitWidth \+ mediaW',
    r'let totalW = childrenRect.width + mediaW',
    c
)
# Replace in dockRow y
c = re.sub(
    r'let totalH = implicitHeight \+ mediaH',
    r'let totalH = childrenRect.height + mediaH',
    c
)

with open('src/qml/main.qml', 'w') as f:
    f.write(c)
