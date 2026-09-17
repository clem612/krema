import re

with open('src/qml/components/MediaPopup.qml', 'r') as f:
    c = f.read()

image_block = """
                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: 8
                    visible: false
                }
                
                Image {
                    id: albumImage
                    anchors.fill: parent
                    source: Mpris.albumArtUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }
                
                MultiEffect {
                    anchors.fill: albumImage
                    source: albumImage
                    maskEnabled: true
                    maskSource: maskRect
                    visible: Mpris.albumArtUrl !== ""
                }"""
c = re.sub(r'                Image \{\s*anchors\.fill: parent\s*source: Mpris\.albumArtUrl\s*fillMode: Image\.PreserveAspectCrop\s*visible: Mpris\.albumArtUrl !== ""\s*layer\.enabled: true\s*layer\.effect: ShaderEffect \{.*?\}\s*\}', image_block, c, flags=re.DOTALL)
c = c.replace('import QtQuick.Layouts', 'import QtQuick.Layouts\nimport QtQuick.Effects')

with open('src/qml/components/MediaPopup.qml', 'w') as f:
    f.write(c)
