import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

# Add import QtQuick.Effects
if 'import QtQuick.Effects' not in c:
    c = c.replace('import QtQuick.Layouts', 'import QtQuick.Layouts\nimport QtQuick.Effects')

old_album_art = """            // Album Art
            Rectangle {
                width: parent.height - 8
                height: width
                radius: width / 2
                color: Qt.rgba(1, 1, 1, 0.1)
                clip: true
                
                Image {
                    anchors.fill: parent
                    source: Mpris.albumArtUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: Mpris.albumArtUrl !== ""
                }
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: parent.width * 0.6
                    height: parent.height * 0.6
                    source: "media-playback-start"
                    visible: Mpris.albumArtUrl === ""
                    color: Kirigami.Theme.textColor
                }
            }"""

new_album_art = """            // Album Art
            Item {
                width: parent.height - 8
                height: width
                
                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: Kirigami.Units.smallSpacing
                    color: Qt.rgba(1, 1, 1, 0.1)
                    visible: Mpris.albumArtUrl === ""
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.6
                        height: parent.height * 0.6
                        source: "media-playback-start"
                        color: Kirigami.Theme.textColor
                    }
                }
                
                Image {
                    id: albumImage
                    anchors.fill: parent
                    source: Mpris.albumArtUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: false // MultiEffect handles visibility
                }
                
                MultiEffect {
                    anchors.fill: albumImage
                    source: albumImage
                    maskEnabled: true
                    maskSource: maskRect
                    visible: Mpris.albumArtUrl !== ""
                }
            }"""

c = c.replace(old_album_art, new_album_art)

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)
