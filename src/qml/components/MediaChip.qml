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

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            if (hovered) {
                popupTimer.start();
            } else {
                popupTimer.stop();
                if (!mediaPopup.isHovered) {
                    mediaPopup.close();
                }
            }
        }
    }
    
    Timer {
        id: popupTimer
        interval: 400
        onTriggered: {
            if (hoverHandler.hovered) {
                mediaPopup.open();
            }
        }
    }
    
    MediaPopup {
        id: mediaPopup
        chipHoverHandler: hoverHandler
        y: -height - 10
        x: (root.width - width) / 2
    }
    
    // Only show if the setting is true AND there is a player
    visible: DockSettings.showMediaChip && Mpris.hasPlayer
    
    
    
    // Calculate optimal width based on content
    property real optimalWidth: Math.max(180, Math.min(450, (mainLayout ? mainLayout.implicitWidth + (bgRect.currentMargin * 2) : 180)))
    
    // We bind the width so that the Wayland panel knows how wide it needs to be.
    width: visible ? (typeof DockView !== "undefined" && DockView.isVertical ? optimalWidth : optimalWidth) : 0


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
        
        // Responsive metrics
        property real currentMargin: Math.max(2, Math.min(6, root.height * 0.1))
        property real contentHeight: root.height - (currentMargin * 2)
        property bool isCompact: root.height < 36
        
        RowLayout {
            id: mainLayout
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
                    radius: bgRect.radius
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

        }
    }

}
