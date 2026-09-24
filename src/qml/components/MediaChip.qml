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

    MouseArea {
        id: hoverHandler
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton // Let clicks fall through to child buttons
        
        property bool hovered: containsMouse
        
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop();
                popupTimer.start();
            } else {
                popupTimer.stop();
                hideTimer.restart();
            }
        }
        
        onWheel: function(wheel) {
            console.log("[MediaChip] Scrolled", wheel.angleDelta.y, "Player count:", Mpris.playerCount);
            if (Mpris.playerCount > 1) {
                Mpris.cyclePlayer(wheel.angleDelta.y > 0 ? -1 : 1);
            } else {
                console.log("[MediaChip] Cannot cycle: Only 1 player available");
            }
        }
    }
    
    Timer {
        id: hideTimer
        interval: 300
        onTriggered: {
            console.log("[MediaChip] hideTimer triggered. chip hovered:", hoverHandler.hovered, "popup hovered:", (typeof mainMediaPopup !== "undefined" ? mainMediaPopup.isHovered : false));
            if (!hoverHandler.hovered && typeof mainMediaPopup !== "undefined" && !mainMediaPopup.isHovered) {
                console.log("[MediaChip] Hiding popup!");
                mainMediaPopup.visible = false;
            }
        }
    }
    
    Timer {
        id: popupTimer
        interval: 400
        onTriggered: {
            if (hoverHandler.hovered) {
                if (typeof mainMediaPopup !== "undefined") { mainMediaPopup.chipHoverHandler = hoverHandler; mainMediaPopup.visible = true; }
            }
        }
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
        
        property bool isLiveEdit: typeof DockVisibility !== "undefined" && DockVisibility.liveEditMode
        color: isLiveEdit ? Qt.rgba(0, 0, 0, 0.45) : (DockSettings.backgroundStyle === 1 ? Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.5) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08))
        border.color: isLiveEdit ? Kirigami.Theme.highlightColor : (DockSettings.rimLightEnabled ? Qt.rgba(1, 1, 1, DockSettings.rimLightOpacity) : "transparent")
        border.width: isLiveEdit ? 2 : (DockSettings.rimLightEnabled ? 1 : 0)
        
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

        // Latte-style Inline Drag Handle
        Rectangle {
            id: dragHandle
            anchors.centerIn: parent
            property real marginExpansion: parent.height * 0.10
            width: parent.width + marginExpansion
            height: parent.height + marginExpansion
            radius: DockSettings.islandCornerRadius === 0 ? Math.min(width, height) / 2 : DockSettings.islandCornerRadius + (marginExpansion / 2)
            color: "transparent"
            border.color: "white"
            border.width: 1
            opacity: bgRect.isLiveEdit ? 0.85 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 24; height: 24
                source: "transform-move"
                color: "white"
            }

            Item {
                id: dragDummy
                x: 0; y: 0
                Behavior on x { enabled: !dragArea.drag.active; NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                Behavior on y { enabled: !dragArea.drag.active; NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                
                drag.target: dragDummy
                drag.axis: (typeof DockView !== "undefined" && DockView.isVertical) ? Drag.YAxis : Drag.XAxis
                
                onReleased: {
                    dragDummy.x = 0
                    dragDummy.y = 0
                }
            }
        }
    }
    
    transform: Translate {
        x: typeof dragDummy !== "undefined" ? dragDummy.x : 0
        y: typeof dragDummy !== "undefined" ? dragDummy.y : 0
    }

}
