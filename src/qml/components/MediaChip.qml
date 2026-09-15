// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import com.bhyoo.krema 1.0

Item {
    id: root
    
    // Only show if the setting is true AND there is a player
    visible: DockSettings.showMediaChip && Mpris.hasPlayer
    
    // We bind the width so that the Wayland panel knows how wide it needs to be.
    // Let's give it a fixed standard size when visible, to prevent jumping.
    width: visible ? 180 : 0
    height: parent.height
    
    // Clip contents so scrolling text doesn't bleed out
    clip: true
    
    Behavior on width {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        
        radius: DockSettings.islandCornerRadius === 0 ? Math.min(width, height) / 2 : DockSettings.islandCornerRadius
        
        color: Qt.rgba(255, 255, 255, 0.05)
        border.color: Qt.rgba(255, 255, 255, 0.1)
        border.width: 1
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 6
            
            // Album Art
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
            }
            
            // Text Info
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0
                
                QQC2.Label {
                    Layout.fillWidth: true
                    text: Mpris.trackName !== "" ? Mpris.trackName : i18n("No Media")
                    font.pixelSize: 12
                    font.bold: true
                    color: Kirigami.Theme.textColor
                    elide: Text.ElideRight
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: Mpris.artistName
                    font.pixelSize: 10
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.7)
                    elide: Text.ElideRight
                    visible: Mpris.artistName !== ""
                }
            }
            
            // Play/Pause Button
            MouseArea {
                Layout.preferredWidth: parent.height - 8
                Layout.preferredHeight: parent.height - 8
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
}
