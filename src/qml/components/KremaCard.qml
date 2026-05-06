// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: contentLayout.implicitHeight + 32
    
    // The "Inset" look: slightly darker than the main #1C1A1C chassis
    color: "#121112" 
    radius: 12
    border.color: "#2A282A" // Subtle stroke
    border.width: 1

    // This allows us to put anything inside the card when we use it
    default property alias content: contentLayout.data

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
    }
}
