// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import com.bhyoo.krema 1.0
import org.kde.kirigami as Kirigami

Item {
    id: root

    property bool isAdvancedMode: false
    property bool isPinned: false
    property var configViewItem: root
    property int currentCategoryIndex: 0
    property int currentSubItemIndex: 0
    
    property var menuData: [{
        "id": "behavior",
        "name": i18n("Behavior"),
        "icon": "preferences-system-windows",
        "page": "settings/BehaviorPage.qml"
    }, {
        "id": "appearance",
        "name": i18n("Appearance"),
        "icon": "preferences-desktop-theme",
        "page": "settings/AppearancePage.qml"
    }, {
        "id": "dimensions",
        "name": i18n("Dimensions"),
        "icon": "transform-scale",
        "page": "settings/DimensionsPage.qml",
        "advancedOnly": true
    }, {
        "id": "tasks",
        "name": i18n("Tasks"),
        "icon": "preferences-desktop-icons",
        "page": "settings/TasksPage.qml"
    }]

    function open(module) {
        root.visible = true;
        if (!module)
            return ;

        var target = module.toString().toLowerCase();
        for (var i = 0; i < root.menuData.length; i++) {
            var cat = root.menuData[i];
            if (cat.id === target) {
                currentCategoryIndex = i;
                pageLoader.source = cat.page;
                return ;
            }
        }
    }

    objectName: "configuration"
    
    // Latte-style progressive sizing
    // Expand width in Advanced Mode to fit the extra tabs, keep height constant
    implicitWidth: root.isAdvancedMode ? 760 : 650
    implicitHeight: 640
    
    Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    onVisibleChanged: {
        if (!root.visible && typeof DockSettings !== "undefined")
            DockSettings.save();
    }

    // --- Dynamic Theme Engine ---
    QtObject {
        id: theme

        property bool isDark: DockSettings.settingsThemeMode === 1
        readonly property color base: isDark ? "#181B20" : "#EBE9E4"
        readonly property color sidebar: isDark ? "#111418" : "#D8DCE0"
        readonly property color card: isDark ? "#22262B" : "#FDFBFA"
        readonly property color accent: isDark ? "#7BA4B5" : "#5C7C8A"
        readonly property color text: isDark ? "#F9F7F2" : "#181C20"
        readonly property color textDim: isDark ? "#949DA6" : "#5C646B"
        readonly property color border: isDark ? "#2E343A" : "#CAD0D6"
    }

    // --- THE MAIN CHASSIS ---
    Rectangle {
        id: settingsChassis

        anchors.fill: parent
        color: theme.base
        // --- ADAPTIVE CORNER RADII (Qt 6.8+) ---
        // Top edge sharp
        topLeftRadius: (DockSettings.edge === 0 || DockSettings.edge === 2) ? 0 : 20
        topRightRadius: (DockSettings.edge === 0 || DockSettings.edge === 3) ? 0 : 20
        // Bottom edge sharp
        bottomLeftRadius: (DockSettings.edge === 1 || DockSettings.edge === 2) ? 0 : 20
        bottomRightRadius: (DockSettings.edge === 1 || DockSettings.edge === 3) ? 0 : 20
        border.color: theme.border
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // HEADER TABS & CONTROLS
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                color: theme.base
                topLeftRadius: settingsChassis.topLeftRadius
                topRightRadius: settingsChassis.topRightRadius
                z: 100

                // MAIN TABS
                ListView {
                    id: mainTabBar
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: windowControls.left
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    orientation: ListView.Horizontal
                    model: root.menuData
                    currentIndex: root.currentCategoryIndex
                    spacing: 8
                    clip: true

                    delegate: Item {
                        property bool isSelected: index === root.currentCategoryIndex
                        
                        // Filter out advanced tabs if Advanced Mode is OFF
                        property bool isVisible: root.isAdvancedMode || !modelData.advancedOnly
                        visible: isVisible
                        width: isVisible ? tabContent.width + 32 : 0
                        height: 64
                        opacity: isVisible ? 1 : 0
                        Behavior on width { NumberAnimation { duration: 150 } }
                        Behavior on opacity { OpacityAnimator { duration: 150 } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: 32
                            radius: 16
                            color: isSelected ? theme.text : (tabMouse.containsMouse ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.12) : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        RowLayout {
                            id: tabContent
                            anchors.centerIn: parent
                            spacing: 8
                            Kirigami.Icon {
                                source: modelData.icon
                                color: isSelected ? theme.card : theme.textDim
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                            }
                            Label {
                                text: modelData.name
                                color: isSelected ? theme.card : theme.text
                                font.weight: isSelected ? Font.DemiBold : Font.Normal
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentCategoryIndex = index;
                                var cat = root.menuData[index];
                                pageLoader.source = cat.page;
                            }
                        }
                    }
                }

                // CONTROLS (Advanced + Window Buttons)
                RowLayout {
                    id: windowControls
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40
                    spacing: 12

                    Label {
                        text: i18n("Advanced")
                        color: theme.textDim
                        font.pixelSize: 12
                    }
                    
                    Switch {
                        checked: root.isAdvancedMode
                        onCheckedChanged: {
                            root.isAdvancedMode = checked
                            if (typeof DockVisibility !== "undefined") {
                                DockVisibility.liveEditMode = checked
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 20
                        color: theme.border
                    }

                    QQC2.ToolButton {
                        id: closeBtn
                        width: 36
                        height: 36
                        onClicked: SettingsController.visible = false

                        contentItem: Kirigami.Icon {
                            source: "dialog-close"
                            color: closeBtn.hovered ? "white" : theme.text
                        }

                        background: Rectangle {
                            radius: 8
                            color: closeBtn.hovered ? "#D13438" : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.05)
                            border.color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.1)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                } // end windowControls
            } // end HEADER TABS & CONTROLS

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: theme.border
            }

            // CONTENT LOADER
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    source: "settings/BackgroundPage.qml"
                }
            }
        }
    }
}
