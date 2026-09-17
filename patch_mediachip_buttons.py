import re

with open('src/qml/components/MediaChip.qml', 'r') as f:
    c = f.read()

buttons = """
            // Previous Button
            MouseArea {
                Layout.preferredWidth: bgRect.contentHeight * 0.8
                Layout.preferredHeight: bgRect.contentHeight * 0.8
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
                        source: "media-skip-backward"
                        color: Kirigami.Theme.textColor
                    }
                }
                
                onClicked: {
                    Mpris.previous();
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

            // Next Button
            MouseArea {
                Layout.preferredWidth: bgRect.contentHeight * 0.8
                Layout.preferredHeight: bgRect.contentHeight * 0.8
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
                        source: "media-skip-forward"
                        color: Kirigami.Theme.textColor
                    }
                }
                
                onClicked: {
                    Mpris.next();
                }
            }
"""

# Replace the original Play/Pause button
c = re.sub(
    r'// Play/Pause Button.*?onClicked: \{\s*Mpris\.playPause\(\);\s*\}\s*\}',
    buttons,
    c, flags=re.DOTALL
)

with open('src/qml/components/MediaChip.qml', 'w') as f:
    f.write(c)
