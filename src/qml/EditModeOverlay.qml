// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import com.bhyoo.krema 1.0

Item {
    id: root
    visible: typeof DockVisibility !== "undefined" && DockVisibility.liveEditMode
    
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.2)
        opacity: root.visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
    }
    
    QQC2.Label {
        text: i18n("Advanced Edit Mode")
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: Kirigami.Units.largeSpacing
        font.bold: true
        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
        color: "white"
        style: Text.Outline
        styleColor: "black"
    }
    
    QQC2.Label {
        text: i18n("Drag islands between the Start, Center, and End zones. (Persistence Backend WIP)")
        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.largeSpacing * 4
        anchors.horizontalCenter: parent.horizontalCenter
        color: "white"
        style: Text.Outline
        styleColor: "black"
    }

    // Interactive Zone Overlays
    // Placed precisely where the zones would be physically on the screen
    Component {
        id: zoneBoxComponent
        Rectangle {
            color: dropArea.containsDrag ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
            border.color: dropArea.containsDrag ? Kirigami.Theme.highlightColor : "white"
            border.width: dropArea.containsDrag ? 4 : 2
            radius: Kirigami.Units.smallSpacing
            
            property string title: ""
            
            QQC2.Label {
                text: parent.title
                anchors.centerIn: parent
                color: "white"
                opacity: dropArea.containsDrag ? 1.0 : 0.5
                font.bold: true
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
            }
            
            DropArea {
                id: dropArea
                anchors.fill: parent
                // In the future, this will update the C++ parsedIslandLayout and save to KConfig
            }
        }
    }

    Loader {
        active: root.visible
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            
            // Start Zone
            Loader {
                sourceComponent: zoneBoxComponent
                x: DockView.isVertical ? parent.width / 4 : DockSettings.floatingPadding
                y: DockView.isVertical ? DockSettings.floatingPadding : parent.height / 4
                width: DockView.isVertical ? parent.width / 2 : parent.width / 4
                height: DockView.isVertical ? parent.height / 4 : parent.height / 2
                onLoaded: item.title = "Start Zone"
            }
            
            // Center Zone
            Loader {
                sourceComponent: zoneBoxComponent
                anchors.centerIn: parent
                width: DockView.isVertical ? parent.width / 2 : parent.width / 3
                height: DockView.isVertical ? parent.height / 3 : parent.height / 2
                onLoaded: item.title = "Center Zone"
            }
            
            // End Zone
            Loader {
                sourceComponent: zoneBoxComponent
                x: DockView.isVertical ? parent.width / 4 : parent.width - width - DockSettings.floatingPadding
                y: DockView.isVertical ? parent.height - height - DockSettings.floatingPadding : parent.height / 4
                width: DockView.isVertical ? parent.width / 2 : parent.width / 4
                height: DockView.isVertical ? parent.height / 4 : parent.height / 2
                onLoaded: item.title = "End Zone"
            }
        }
    }
}
