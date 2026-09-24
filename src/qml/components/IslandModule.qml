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
        
        property bool isLiveEdit: typeof DockVisibility !== "undefined" && DockVisibility.liveEditMode
        color: isLiveEdit ? Qt.rgba(0, 0, 0, 0.45) : (DockSettings.backgroundStyle === 1 ? Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.5) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08))
        border.color: isLiveEdit ? Kirigami.Theme.highlightColor : (DockSettings.rimLightEnabled ? Qt.rgba(1, 1, 1, DockSettings.rimLightOpacity) : "transparent")
        border.width: isLiveEdit ? 2 : (DockSettings.rimLightEnabled ? 1 : 0)
        radius: DockSettings.islandCornerRadius === 0 ? Math.min(width, height) / 2 : DockSettings.islandCornerRadius
        visible: container.children.length > 0
    }

    // Latte-style Inline Drag Handle
    Rectangle {
        id: dragHandle
        anchors.centerIn: parent
        // 10% larger than the island itself
        property real marginExpansion: parent.height * 0.10
        width: parent.width + marginExpansion
        height: parent.height + marginExpansion
        radius: DockSettings.islandCornerRadius === 0 ? Math.min(width, height) / 2 : DockSettings.islandCornerRadius + (marginExpansion / 2)
        color: "transparent"
        border.color: "white"
        border.width: 1
        // Simulate dashed line (not natively supported in Rectangle without canvas/shader, so we just use opacity)
        opacity: typeof DockVisibility !== "undefined" && DockVisibility.liveEditMode ? 0.85 : 0.0
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
            drag.axis: DockView.isVertical ? Drag.YAxis : Drag.XAxis
            
            onReleased: {
                dragDummy.x = 0
                dragDummy.y = 0
            }
        }
    }

    transform: Translate {
        x: dragDummy.x
        y: dragDummy.y
    }

    Item {
        id: container
        x: DockView.isVertical ? 0 : DockSettings.islandMargin
        y: DockView.isVertical ? DockSettings.islandMargin : 0
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
