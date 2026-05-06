// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import com.bhyoo.krema 1.0

Item {
    objectName: "configuration"
    id: settingsWindow

    // --- KREMA DIMENSIONS ---
    implicitWidth: 720 
    implicitHeight: 620

    property bool isPinned: false
    property var configViewItem: settingsWindow
    readonly property int tileHeight: 44

    // --- THE REORGANIZED KREMA CATEGORIZATION ---
    property var menuData: [
        {
            name: i18n("Appearance"),
            icon: "preferences-desktop-theme",
            subItems: [
                { id: "background", name: i18n("Background & Blur"), icon: "preferences-desktop-wallpaper", page: "settings/BackgroundPage.qml" },
                { id: "shadow", name: i18n("Shadow Effects"), icon: "format-text-shadow", page: "settings/ShadowPage.qml" },
                { id: "separator", name: i18n("Separators"), icon: "format-stroke-color", page: "settings/SeparatorPage.qml" }
            ]
        },
        {
            name: i18n("Dimensions"),
            icon: "transform-scale",
            subItems: [
                { id: "panel", name: i18n("Panel Geometry"), icon: "measure", page: "settings/PanelPage.qml" },
                { id: "icons", name: i18n("Icon Sizing & Gaps"), icon: "preferences-desktop-icons", page: "settings/IconsPage.qml" }
            ]
        },
        {
            name: i18n("Interaction"),
            icon: "preferences-system",
            subItems: [
                { id: "visibility", name: i18n("Visibility & Hiding"), icon: "view-visible", page: "settings/VisibilityPage.qml" },
                { id: "behavior", name: i18n("Animations & Logic"), icon: "preferences-system-windows", page: "settings/BehaviorPage.qml" },
                { id: "preview", name: i18n("Window Previews"), icon: "view-preview", page: "settings/PreviewPage.qml" }
            ]
        },
        {
            name: i18n("Workspace"),
            icon: "video-display",
            subItems: [
                { id: "multimonitor", name: i18n("Screen Selection"), icon: "video-display", page: "settings/MonitorPage.qml" },
                { id: "virtualdesktops", name: i18n("Virtual Desktops"), icon: "preferences-desktop-virtual", page: "settings/VirtualDesktopsPage.qml" }
            ]
        },
        {
            id: "about",
            name: i18n("About Krema"),
            icon: "help-about",
            page: "settings/AboutPage.qml"
        }
    ]

    function open(module) {
        settingsWindow.visible = true
        if (!module) return
        var target = module.toString().toLowerCase()
        sidebarStack.pop(null)

        for (var i = 0; i < settingsWindow.menuData.length; i++) {
            var cat = settingsWindow.menuData[i]
            if (cat.id === target) {
                pageLoader.source = cat.page
                return
            }
            if (cat.subItems) {
                for (var j = 0; j < cat.subItems.length; j++) {
                    if (cat.subItems[j].id === target) {
                        pageLoader.source = cat.subItems[j].page
                        sidebarStack.push(subMenuComponent, { "categoryName": cat.name, "subModel": cat.subItems })
                        return
                    }
                }
            }
        }
    }

    onVisibleChanged: {
           if (typeof DockVisibility !== "undefined") {
               DockVisibility.liveEditMode = settingsWindow.visible;
               DockVisibility.setInteracting(settingsWindow.visible);
           }
           // Save to disk whenever the window is hidden
           if (!settingsWindow.visible && typeof DockSettings !== "undefined") {
               DockSettings.save();
           }
       }

    // --- THE MAIN CHASSIS ---
    Rectangle {
        id: settingsChassis
        anchors.fill: parent
        color: "#1C1A1C" // Deep Roast Base
        radius: 16
        border.color: "#333133" 
        border.width: 1
        clip: true

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // --- LEFT SIDEBAR ---
            Rectangle {
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                color: "#121112"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 24
                            Label { 
                                text: "Krema"
                                color: "#FFFDD0" 
                                font.bold: true
                                font.pixelSize: 22
                                font.letterSpacing: 1.2
                                Layout.fillWidth: true 
                                verticalAlignment: Text.AlignVCenter 
                            }
                        }
                    }

                    StackView { 
                        id: sidebarStack
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        initialItem: mainMenuComponent 
                    }
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#2A282A" }

            // --- RIGHT CONTENT AREA ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    RowLayout {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 16
                        spacing: 8

                        QQC2.ToolButton { 
                            icon.name: settingsWindow.isPinned ? "window-pin" : "window-unpin"
                            icon.color: settingsWindow.isPinned ? "#FFFDD0" : "#80FFFDD0"
                            onClicked: settingsWindow.isPinned = !settingsWindow.isPinned 
                        }
                        
                        QQC2.ToolButton { 
                            icon.name: "window-close"
                            icon.color: "#80FFFDD0"
                            onClicked: SettingsController.visible = false 
                        }
                    }
                }

                Loader { 
                    id: pageLoader
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 16
                    source: "settings/BackgroundPage.qml" 
                }
            }
        }
    }

    Component {
        id: mainMenuComponent
        ListView {
            model: settingsWindow.menuData
            currentIndex: -1
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            delegate: Rectangle {
                id: menuDelegateRect
                width: parent.width - 32
                height: tileHeight
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 8
                color: {
                    if (ListView.isCurrentItem) return "#1AFFFDD0"
                    if (menuMouse.pressed) return "#15FFFDD0"
                    if (menuMouse.containsMouse) return "#0AFFFDD0"
                    return "transparent"
                }
                
                Behavior on color {
                    ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
                
                MouseArea {
                    id: menuMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.subItems) sidebarStack.push(subMenuComponent, { "categoryName": modelData.name, "subModel": modelData.subItems })
                        else pageLoader.source = modelData.page
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12
                    Kirigami.Icon { 
                        source: modelData.icon
                        color: parent.ListView.isCurrentItem ? "#FFFDD0" : "#80FFFDD0"
                        Layout.preferredWidth: 18; Layout.preferredHeight: 18 
                    }
                    Label { 
                        text: modelData.name
                        color: parent.ListView.isCurrentItem ? "#FFFDD0" : "#80FFFDD0"
                        font.weight: parent.ListView.isCurrentItem ? Font.Bold : Font.Normal
                        Layout.fillWidth: true 
                    }
                    Kirigami.Icon { 
                        source: "go-next-symbolic"
                        color: "#80FFFDD0"
                        Layout.preferredWidth: 16; Layout.preferredHeight: 16
                        visible: modelData.subItems !== undefined 
                    }
                }
            }
        }
    }

    Component {
        id: subMenuComponent
        ColumnLayout {
            spacing: 8
            property string categoryName: ""
            property var subModel: []

            Rectangle {
                Layout.preferredWidth: parent.width - 32
                Layout.alignment: Qt.AlignHCenter
                height: tileHeight
                radius: 8
                color: {
                    if (backMouse.pressed) return "#15FFFDD0"
                    if (backMouse.containsMouse) return "#0AFFFDD0"
                    return "transparent"
                }
                
                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
                
                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sidebarStack.pop()
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    spacing: 12
                    Kirigami.Icon { source: "go-previous-symbolic"; color: "#FFFDD0"; Layout.preferredWidth: 18; Layout.preferredHeight: 18 }
                    Label { text: categoryName; color: "#FFFDD0"; font.bold: true; Layout.fillWidth: true }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A"; Layout.leftMargin: 16; Layout.rightMargin: 16 }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: subModel
                currentIndex: -1
                clip: true
                
                delegate: Rectangle {
                    id: subDelegateRect
                    width: parent.width - 32
                    height: tileHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 8
                    color: {
                        if (ListView.isCurrentItem) return "#1AFFFDD0"
                        if (subMouse.pressed) return "#15FFFDD0"
                        if (subMouse.containsMouse) return "#0AFFFDD0"
                        return "transparent"
                    }
                    
                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    
                    MouseArea {
                        id: subMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pageLoader.source = modelData.page
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        spacing: 12
                        Kirigami.Icon { 
                            source: modelData.icon || ""
                            color: parent.ListView.isCurrentItem ? "#FFFDD0" : "#80FFFDD0"
                            Layout.preferredWidth: 18; Layout.preferredHeight: 18 
                        }
                        Label { 
                            text: modelData.name
                            color: parent.ListView.isCurrentItem ? "#FFFDD0" : "#80FFFDD0"
                            font.weight: parent.ListView.isCurrentItem ? Font.Medium : Font.Normal
                            Layout.fillWidth: true 
                        }
                    }
                }
            }
        }
    }
}
