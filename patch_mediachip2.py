import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

old_album_art = """            // Album Art
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

new_album_art = """            // Album Art
            Item {
                width: parent.height - 8
                height: width
                
                // 1. The Mask (Solid white, rounded corners)
                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: Kirigami.Units.smallSpacing
                    color: "white"
                    visible: false
                    layer.enabled: true
                }
                
                // 2. The Image (Masked by the Rectangle)
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
                }
                
                // 3. The Placeholder (Shown when no image)
                Rectangle {
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
            }"""

if old_album_art in c:
    c = c.replace(old_album_art, new_album_art)
else:
    print("WARNING: Could not find old album art block!")

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)
