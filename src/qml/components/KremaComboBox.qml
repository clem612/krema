// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Controls.Basic as BasicControls
import org.kde.kirigami as Kirigami

BasicControls.ComboBox {
    id: control

    // 1. Fully Dynamic Sizing (Removed rigid implicitWidth)
    implicitHeight: 32
    leftPadding: 12
    rightPadding: indicator.width + 24

    // 2. The Main Box Text
    contentItem: Text {
        text: control.displayText
        font: control.font
        color: "#FFFDD0"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    // 3. The Main Box Background
    background: Rectangle {
        implicitWidth: 100 // Safe minimum width, but text will push it wider
        implicitHeight: 32
        radius: 6
        border.width: 1
        border.color: control.visualFocus || control.popup.visible ? "#80FFFDD0" : "#333133"
        
        color: {
            if (control.pressed || control.popup.visible) return "#15FFFDD0"
            if (control.hovered) return "#0AFFFDD0"
            return "#121112"
        }
        
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    // 4. The Dropdown Arrow
    indicator: Kirigami.Icon {
        x: control.width - width - 12
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 16
        height: 16
        source: "arrow-down"
        color: control.hovered || control.popup.visible ? "#FFFDD0" : "#80FFFDD0"
    }

    // 5. The Popup Menu
    popup: BasicControls.Popup {
        y: control.height + 4
        // Prevents dropdown from being too thin when the button shrinks for short words
        width: Math.max(control.width, 160) 
        implicitHeight: contentItem.implicitHeight
        padding: 4

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            QQC2.ScrollBar.vertical: QQC2.ScrollBar { }
        }

        background: Rectangle {
            color: "#1C1A1C"
            border.color: "#333133"
            border.width: 1
            radius: 6
        }
    }

    // 6. The Dropdown Items
    delegate: BasicControls.ItemDelegate {
        width: control.popup.width - 8
        height: 32
        
        contentItem: Text {
            text: modelData
            color: control.highlightedIndex === index ? "#1C1A1C" : "#FFFDD0"
            font: control.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: 8
        }
        
        background: Rectangle {
            color: control.highlightedIndex === index ? "#FFFDD0" : "transparent"
            radius: 4
        }
        
        highlighted: control.highlightedIndex === index
    }
}
