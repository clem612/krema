// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

ComboBox {
    id: control
    
    // --- The Popup List Styling ---
    delegate: ItemDelegate {
        width: control.width
        height: 36
        contentItem: Text {
            text: modelData
            color: highlighted ? "#1C1A1C" : "#FFFDD0"
            font: control.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: highlighted ? "#FFFDD0" : "transparent"
            radius: 6
            anchors.fill: parent
            anchors.margins: 2
        }
    }

    // --- The Selected Text Styling ---
    contentItem: Text {
        leftPadding: 12
        rightPadding: control.indicator.width + 12
        text: control.displayText
        font: control.font
        color: "#FFFDD0"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight // This forces long text to add "..." instead of breaking the layout
    }

    // --- The Main Button Background ---
    background: Rectangle {
        implicitWidth: 150
        implicitHeight: 32
        color: "#1C1A1C" // Deep Roast Base
        border.color: control.popup.visible ? "#FFFDD0" : "#333133"
        border.width: 1
        radius: 8
        
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }
}
