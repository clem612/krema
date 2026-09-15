import QtQuick 2.15

Item {
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            console.log("[DEBUG_VIS] QML opacity:", dockPanel.opacity, "dockVisible:", DockVisibility.dockVisible, "hovered:", DockVisibility.hovered, "mouseY:", dockMouseArea.mouseY);
        }
    }
}
