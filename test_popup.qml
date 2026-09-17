import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Window {
    width: 600
    height: 800
    visible: true
    color: "gray"

    Item {
        id: mpris
        property string trackName: "Awesome Song"
        property string artistName: "The Artist"
        property string albumArtUrl: ""
        property real length: 300000000
        property real position: 150000000
        property bool shuffle: false
        property string loopStatus: "None"
        property real volume: 0.8
        property bool isPlaying: true
    }
    
    Rectangle {
        id: mediaChip
        width: 150
        height: 48
        y: 700
        x: 225
        color: "black"
        radius: 24
        
        HoverHandler {
            id: hoverHandler
            onHoveredChanged: {
                if (hovered) mainMediaPopup.visible = true;
            }
        }
    }
    
    Item {
        id: mainMediaPopup
        z: 999
        visible: true
        width: 320
        height: 400
        
        x: mediaChip.x + (mediaChip.width - width) / 2
        y: mediaChip.y - height - 16
        
        property QtObject chipHoverHandler: hoverHandler
        property bool isHovered: popupHoverHandler.hovered
        
        HoverHandler {
            id: popupHoverHandler
            onHoveredChanged: {
                if (!hovered && chipHoverHandler && !chipHoverHandler.hovered) {
                    mainMediaPopup.visible = false;
                }
            }
        }
        
        Rectangle {
            id: bgRect
            anchors.fill: parent
            color: Qt.rgba(0.1, 0.1, 0.1, 0.9)
            radius: 12
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                
                // Large Album Art
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: width
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.05)
                    
                    Rectangle {
                        id: maskRect
                        anchors.fill: parent
                        radius: 8
                        visible: true
                    }
                    
                    Image {
                        id: albumImage
                        anchors.fill: parent
                        source: mpris.albumArtUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: true
                    }
                    
                    MultiEffect {
                        anchors.fill: albumImage
                        source: albumImage
                        maskEnabled: true
                        maskSource: maskRect
                        visible: mpris.albumArtUrl !== ""
                    }
                    
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 64
                        height: 64
                        source: "media-optical"
                        color: "white"
                        opacity: 0.3
                        visible: mpris.albumArtUrl === ""
                    }
                }
                
                // Track Info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: mpris.trackName !== "" ? mpris.trackName : "No Media"
                        font.pixelSize: 18
                        font.bold: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                    }
                    
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: mpris.artistName
                        font.pixelSize: 14
                        opacity: 0.7
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                    }
                }
                
                // Scrubber
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    function formatTime(microsecs) {
                        var secs = Math.floor(microsecs / 1000000);
                        var m = Math.floor(secs / 60);
                        var s = secs % 60;
                        return m + ":" + (s < 10 ? "0" : "") + s;
                    }
                    
                    QQC2.Label {
                        text: parent.formatTime(mpris.position)
                        font.pixelSize: 12
                        opacity: 0.7
                        color: "white"
                    }
                    
                    QQC2.Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: mpris.length > 0 ? mpris.length : 1
                        value: mpris.position
                    }
                    
                    QQC2.Label {
                        text: parent.formatTime(mpris.length)
                        font.pixelSize: 12
                        opacity: 0.7
                        color: "white"
                    }
                }
                
                // Controls
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    
                    QQC2.ToolButton {
                        icon.name: "media-playlist-shuffle"
                        checked: mpris.shuffle
                    }
                    
                    QQC2.ToolButton {
                        icon.name: "media-skip-backward"
                    }
                    
                    QQC2.ToolButton {
                        icon.name: mpris.isPlaying ? "media-playback-pause" : "media-playback-start"
                        icon.width: 32
                        icon.height: 32
                    }
                    
                    QQC2.ToolButton {
                        icon.name: "media-skip-forward"
                    }
                    
                    QQC2.ToolButton {
                        icon.name: "media-playlist-repeat"
                        checked: mpris.loopStatus !== "None"
                    }
                }
                
                // Volume
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Kirigami.Icon {
                        source: mpris.volume === 0 ? "audio-volume-muted" : "audio-volume-high"
                        width: 16
                        height: 16
                        color: "white"
                    }
                    
                    QQC2.Slider {
                        Layout.fillWidth: true
                        from: 0.0
                        to: 1.0
                        value: mpris.volume
                    }
                }
            }
        }
    }
}
