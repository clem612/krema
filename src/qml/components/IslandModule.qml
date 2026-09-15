// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
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
        
        color: Qt.rgba(255, 255, 255, 0.05)
        border.color: Qt.rgba(255, 255, 255, 0.1)
        border.width: 1
        radius: DockSettings.islandCornerRadius === 0 ? Math.min(width, height) / 2 : DockSettings.islandCornerRadius
        visible: container.children.length > 0
    }

    Item {
        id: container
        x: DockView.isVertical ? 0 : DockSettings.islandMargin
        y: DockView.isVertical ? DockSettings.islandMargin : 0
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
