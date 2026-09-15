import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

QQC2.Popup {
    id: popup
    width: 320
    height: 400
    
    // Transparent background, we will draw our own glass pill
    background: Item {}
    
    padding: 0
    margins: 0
    

    property QtObject chipHoverHandler
    property bool isHovered: popupHoverHandler.hovered
    
    HoverHandler {
        id: popupHoverHandler
        onHoveredChanged: {
            if (!hovered && !chipHoverHandler.hovered) {
                popup.close();
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
                    visible: false
                }
                
                Image {
                    id: albumImage
                    anchors.fill: parent
                    source: Mpris.albumArtUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }
                
                MultiEffect {
                    anchors.fill: albumImage
                    source: albumImage
                    maskEnabled: true
                    maskSource: maskRect
                    visible: Mpris.albumArtUrl !== ""
                }
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 64
                    height: 64
                    source: "media-optical"
                    color: Kirigami.Theme.textColor
                    opacity: 0.3
                    visible: Mpris.albumArtUrl === ""
                }
            }
            
            // Track Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                QQC2.Label {
                    Layout.fillWidth: true
                    text: Mpris.trackName !== "" ? Mpris.trackName : i18n("No Media")
                    font.pixelSize: 18
                    font.bold: true
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
                
                QQC2.Label {
                    Layout.fillWidth: true
                    text: Mpris.artistName
                    font.pixelSize: 14
                    opacity: 0.7
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
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
                    text: formatTime(Mpris.position)
                    font.pixelSize: 12
                    opacity: 0.7
                }
                
                QQC2.Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: Mpris.length > 0 ? Mpris.length : 1
                    value: Mpris.position
                    
                    onMoved: {
                        Mpris.position = value;
                    }
                }
                
                QQC2.Label {
                    text: formatTime(Mpris.length)
                    font.pixelSize: 12
                    opacity: 0.7
                }
            }
            
            // Controls
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 16
                
                QQC2.ToolButton {
                    icon.name: "media-playlist-shuffle"
                    checked: Mpris.shuffle
                    onClicked: Mpris.shuffle = !Mpris.shuffle
                }
                
                QQC2.ToolButton {
                    icon.name: "media-skip-backward"
                    onClicked: Mpris.previous()
                }
                
                QQC2.ToolButton {
                    icon.name: Mpris.isPlaying ? "media-playback-pause" : "media-playback-start"
                    icon.width: 32
                    icon.height: 32
                    onClicked: Mpris.playPause()
                }
                
                QQC2.ToolButton {
                    icon.name: "media-skip-forward"
                    onClicked: Mpris.next()
                }
                
                QQC2.ToolButton {
                    icon.name: "media-playlist-repeat"
                    checked: Mpris.loopStatus !== "None"
                    onClicked: Mpris.loopStatus = Mpris.loopStatus === "None" ? "Playlist" : "None"
                }
            }
            
            // Volume
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Kirigami.Icon {
                    source: Mpris.volume === 0 ? "audio-volume-muted" : "audio-volume-high"
                    width: 16
                    height: 16
                }
                
                QQC2.Slider {
                    Layout.fillWidth: true
                    from: 0.0
                    to: 1.0
                    value: Mpris.volume
                    onMoved: Mpris.volume = value
                }
            }
        }
    }
}
