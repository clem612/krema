import re

with open('src/qml/components/IslandModule.qml', 'r') as f:
    c = f.read()

c = c.replace('import QtQuick', 'import QtQuick\nimport com.bhyoo.krema 1.0')

with open('src/qml/components/IslandModule.qml', 'w') as f:
    f.write(c)
