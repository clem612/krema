import QtQuick
import QtQuick.Effects

Item {
    width: 100
    height: 100
    
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: 10
        visible: false
    }
    
    Rectangle {
        id: src
        anchors.fill: parent
        color: "red"
        visible: false
    }
    
    MultiEffect {
        anchors.fill: parent
        source: src
        maskEnabled: true
        maskSource: mask
    }
}
