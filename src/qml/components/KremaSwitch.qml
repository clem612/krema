// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls

Switch {
    id: control
    spacing: 12
    
    // Custom Viscous Indicator
    indicator: Rectangle {
        implicitWidth: 44
        implicitHeight: 24
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 12
        
        // Track Color: Krema Accent when ON, Dark Gray when OFF
        color: control.checked ? "#FFFDD0" : "#2A282A"
        border.color: control.checked ? "#FFFDD0" : "#333133"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // The Toggle "Thumb"
        Rectangle {
            x: control.checked ? parent.width - width - 2 : 2
            y: 2
            width: 20
            height: 20
            radius: 10
            
            // Thumb Color: Deep Roast when ON, Soft Krema when OFF
            color: control.checked ? "#1C1A1C" : "#80FFFDD0"
            
            // The satisfying "snap" animation (Fixed easing property)
            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }
    }

    // Custom Label Text
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.checked ? "#FFFDD0" : "#B3FFFDD0" // Brighter when active
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
        
        Behavior on color { ColorAnimation { duration: 250 } }
    }
}
