// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import com.bhyoo.krema 1.0

/**
 * @brief Tier 2: Logical Island.
 * Groups items for organizational logic and provides a subtle glass background.
 */
Item {
    id: root
    property var islandData

    default property alias content: container.data

    width: implicitWidth
    height: implicitHeight

    implicitWidth: DockView.isVertical ? parent.width : container.implicitWidth + (DockSettings.islandMargin * 2)
    implicitHeight: DockView.isVertical ? container.implicitHeight + (DockSettings.islandMargin * 2) : container.implicitHeight

    x: DockView.isVertical ? 0 : -DockSettings.islandMargin
    y: DockView.isVertical ? -DockSettings.islandMargin : 0

    Rectangle {
        anchors.fill: parent
        // Rule 18: Island Glass - Premium Visual Separation
        
        color: typeof DockVisibility !== "undefined" && DockVisibility.liveEditMode ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(255, 255, 255, 0.05)
        border.color: typeof DockVisibility !== "undefined" && DockVisibility.liveEditMode ? Kirigami.Theme.highlightColor : Qt.rgba(255, 255, 255, 0.1)
        border.width: typeof DockVisibility !== "undefined" && DockVisibility.liveEditMode ? 2 : 1
        radius: DockSettings.islandCornerRadius === 0 ? Math.min(width, height) / 2 : DockSettings.islandCornerRadius
        visible: container.children.length > 0
    }

    // Latte-style Inline Drag Handle
    Rectangle {
        id: dragHandle
        anchors.centerIn: parent
        width: Math.max(container.width + 16, 48)
        height: Math.max(container.height + 16, 48)
        radius: parent.radius
        color: "transparent"
        border.color: "white"
        border.width: 1
        // Simulate dashed line (not natively supported in Rectangle without canvas/shader, so we just use opacity)
        opacity: typeof DockVisibility !== "undefined" && DockVisibility.liveEditMode ? 0.8 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        
        QQC2.Label {
            text: "Drag to move"
            anchors.centerIn: parent
            color: "white"
            font.bold: true
            style: Text.Outline
            styleColor: "black"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.OpenHandCursor
            onPressed: cursorShape = Qt.ClosedHandCursor
            onReleased: cursorShape = Qt.OpenHandCursor
            // Real drag logic will go here
        }
    }

    Item {
        id: container
        x: DockView.isVertical ? 0 : DockSettings.islandMargin
        y: DockView.isVertical ? DockSettings.islandMargin : 0
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
