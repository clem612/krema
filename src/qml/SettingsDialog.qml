// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import com.bhyoo.krema 1.0

Kirigami.ApplicationWindow {
    objectName: "configuration"
    id: settingsWindow

    
    // --- 1. Latte Dimensions (Tall and Narrow) ---
    width: 450
    height: 700
    
    // Frameless floating look
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    
    property bool isPinned: false
    property var configViewItem: settingsWindow

    // 1. Fix the method signature for C++
    function open(module) {
        settingsWindow.visible = true
        settingsWindow.requestActivate()
    }

    onVisibleChanged: {
        if (typeof DockVisibility !== "undefined") {
            DockVisibility.liveEditMode = settingsWindow.visible;
            DockVisibility.setInteracting(settingsWindow.visible);
        }
    }

    // --- MAIN CHASSIS ---
    Rectangle {
            id: settingsChassis
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            radius: 12
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                // This is the padding for EVERYTHING inside the window
                anchors.margins: Kirigami.Units.gridUnit 
                spacing: Kirigami.Units.largeSpacing

            // --- HEADER ---
	    Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50 // Slightly taller
                    color: "transparent"
                    
                    DragHandler {
                        onActiveChanged: if (active) settingsWindow.startSystemMove()
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.largeSpacing // Space between icon, text, and buttons
                        
                    Kirigami.Icon {
                        source: "preferences-system" // Changed to a standard system icon for now
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        }
                        
                    QQC2.Label {
                        text: "Krema Settings"
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                        Layout.fillWidth: true
                        }

                    QQC2.ToolButton {
                        icon.name: settingsWindow.isPinned ? "window-pin" : "window-unpin"
                        onClicked: settingsWindow.isPinned = !settingsWindow.isPinned
                        QQC2.ToolTip.text: i18n("Keep window open")
                    }

                    QQC2.ToolButton {
                        icon.name: "window-close"
                        onClicked: settingsWindow.visible = false
                    }
                }
            }

            // --- TABS ---
            QQC2.TabBar {
                id: bar
                Layout.fillWidth: true
                QQC2.TabButton { text: i18n("Behavior") }
                QQC2.TabButton { text: i18n("Appearance") }
                QQC2.TabButton { text: i18n("Preview") }
            }

            // --- CONTENT AREA ---
	    StackLayout {
                    id: settingsStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: bar.currentIndex

                    Loader { 
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        source: "settings/BehaviorPage.qml" 
                    }
                    Loader { 
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        source: "settings/AppearancePage.qml" 
                    }
                    Loader { 
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        source: "settings/PreviewPage.qml" 
                    }
                }

            // --- SEPARATOR ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Kirigami.Theme.textColor
                opacity: 0.1
            }

            // --- BOTTOM ACTION BAR ---
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                
                QQC2.Button {
                    text: i18n("+ Add Widgets...")
                    flat: true
                    enabled: false
                }
                Item { Layout.fillWidth: true }
                QQC2.Button {
                    text: i18n("Close")
                    onClicked: settingsWindow.visible = false
                }
            }
        }
    }
}    
