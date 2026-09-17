import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import com.bhyoo.krema 1.0

Item {
    id: popup
    visible: false
    width: 320
    
    // The bridge is a transparent hover zone that connects the popup to the chip below,
    // eliminating the dead zone where the cursor would lose hover.
    property real bridgeHeight: Kirigami.Units.largeSpacing + 8
    height: popupLayout.implicitHeight + 32 + bridgeHeight
    
    // Transparent background, we will draw our own glass pill
    function formatTime(microsecs) {
        var secs = Math.floor(microsecs / 1000000);
        var m = Math.floor(secs / 60);
        var s = secs % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
    
    
    
    
    

    property QtObject chipHoverHandler
    property QtObject globalHoverHandler
    
    property bool isHovered: {
        if (popupHoverHandler.hovered) return true;
        if (globalHoverHandler && globalHoverHandler.hovered) {
            let mx = globalHoverHandler.point.position.x;
            let my = globalHoverHandler.point.position.y;
            return (mx >= x && mx <= x + width && my >= y && my <= y + height);
        }
        return false;
    }
    
    // Block background clicks/scrolls from falling through to the dock
    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onTapped: {} // Consume the tap
    }
    
    WheelHandler {
        onWheel: function(event) { event.accepted = true; } // Consume scrolls
    }
    
    HoverHandler {
        id: popupHoverHandler
    }
    
    onIsHoveredChanged: {
        console.log("[MediaPopup] isHovered changed:", isHovered);
        if (!isHovered) {
            popupHideTimer.restart();
        } else {
            popupHideTimer.stop();
        }
    }
    
    Timer {
        id: popupHideTimer
        interval: 300
        onTriggered: {
            console.log("[MediaPopup] popupHideTimer triggered. popup hovered:", popup.isHovered, "chip:", (chipHoverHandler ? chipHoverHandler.hovered : false));
            
            if (!popup.isHovered && chipHoverHandler && !chipHoverHandler.hovered) {
                console.log("[MediaPopup] Hiding popup!");
                popup.visible = false;
            }
        }
    }
    
    Rectangle {
        id: bgRect
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height - popup.bridgeHeight
        color: Qt.rgba(0.1, 0.1, 0.1, 0.9)
        radius: 12
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        
        ColumnLayout {
            id: popupLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 12
            
            // Large Album Art
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 320 - 32
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.05)
                

                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: 8
                    color: "black"
                    visible: false
                    layer.enabled: true
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
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    opacity: 0.7
                }
                
                QQC2.Slider {
                    Layout.fillWidth: true
                    from: 0.0
                    to: 1.0
                    value: Mpris.volume
                    onMoved: Mpris.volume = value
                    
                    // Sleek minimal style
                    background: Rectangle {
                        x: parent.leftPadding
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 4
                        width: parent.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Rectangle {
                            width: parent.parent.visualPosition * parent.width
                            height: parent.height
                            color: Kirigami.Theme.highlightColor
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        implicitWidth: 12
                        implicitHeight: 12
                        radius: 6
                        color: parent.pressed ? Qt.lighter(Kirigami.Theme.highlightColor, 1.2) : Kirigami.Theme.highlightColor
                        border.color: Qt.rgba(0, 0, 0, 0.2)
                        border.width: 1
                    }
                }
            }
        }
    }
}
