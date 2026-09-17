import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

# Replace the inner Rectangle and RowLayout with a more responsive design
replacement = """
    Rectangle {
        id: bgRect
        anchors.fill: parent
        
        radius: DockSettings.islandCornerRadius === 0 ? Math.min(width, height) / 2 : DockSettings.islandCornerRadius
        
        color: Qt.rgba(255, 255, 255, 0.05)
        border.color: Qt.rgba(255, 255, 255, 0.1)
        border.width: 1
        
        // Responsive metrics
        property real currentMargin: Math.max(2, Math.min(6, root.height * 0.1))
        property real contentHeight: root.height - (currentMargin * 2)
        property bool isCompact: root.height < 36
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: bgRect.currentMargin
            spacing: Math.max(4, root.height * 0.15)
            
            // Album Art
            Item {
                Layout.preferredWidth: bgRect.contentHeight
                Layout.preferredHeight: bgRect.contentHeight
                
                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: Kirigami.Units.smallSpacing * (bgRect.contentHeight / 32)
                    color: "white"
                    visible: false
                    layer.enabled: true
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
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: maskRect.radius
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
            }
            
            // Text Info
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0
                
                QQC2.Label {
                    Layout.fillWidth: true
                    text: Mpris.trackName !== "" ? Mpris.trackName : i18n("No Media")
                    font.pixelSize: Math.max(9, bgRect.isCompact ? bgRect.contentHeight * 0.7 : bgRect.contentHeight * 0.4)
                    font.bold: true
                    color: Kirigami.Theme.textColor
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: Mpris.artistName
                    font.pixelSize: Math.max(8, bgRect.contentHeight * 0.3)
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.7)
                    elide: Text.ElideRight
                    visible: !bgRect.isCompact && Mpris.artistName !== ""
                }
            }
            
            // Play/Pause Button
            MouseArea {
                Layout.preferredWidth: bgRect.contentHeight
                Layout.preferredHeight: bgRect.contentHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.6
                        height: parent.height * 0.6
                        source: Mpris.isPlaying ? "media-playback-pause" : "media-playback-start"
                        color: Kirigami.Theme.textColor
                    }
                }
                
                onClicked: {
                    Mpris.playPause();
                }
            }
        }
    }
"""

c = re.sub(r'Rectangle \{\s*id: bgRect\s*anchors\.fill: parent.*?onClicked: \{\s*Mpris\.playPause\(\);\s*\}\s*\}\s*\}\s*\}', replacement, c, flags=re.DOTALL)

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)
