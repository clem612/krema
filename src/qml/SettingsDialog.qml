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

    // --- NARROWER WIDTH ---
    implicitWidth: 600 
    implicitHeight: 650

    property bool isPinned: false
    property var configViewItem: settingsWindow
    readonly property int tileHeight: Math.floor(Kirigami.Units.gridUnit * 2.0)

    property var menuData: [
        {
            name: i18n("Behavior"),
            icon: "preferences-system",
            subItems: [
                { id: "visibility", name: i18n("Visibility"), icon: "view-visible", page: "settings/VisibilityPage.qml" },
                { id: "multimonitor", name: i18n("Multi-Monitor"), icon: "video-display", page: "settings/MonitorPage.qml" },
                { id: "virtualdesktops", name: i18n("Virtual Desktops"), icon: "preferences-desktop-virtual", page: "settings/VirtualDesktopsPage.qml" }
            ]
        },
        {
            name: i18n("Appearance & Style"),
            icon: "preferences-desktop-theme",
            subItems: [
                { id: "icons", name: i18n("Icons"), icon: "preferences-desktop-icons", page: "settings/IconsPage.qml" },
                { id: "separator", name: i18n("Separator"), icon: "format-stroke-color", page: "settings/SeparatorPage.qml" },
                { id: "background", name: i18n("Background & Panel"), icon: "preferences-desktop-wallpaper", page: "settings/BackgroundPage.qml" },
                { id: "shadow", name: i18n("Shadow"), icon: "format-text-shadow", page: "settings/ShadowPage.qml" },
                { id: "preview", name: i18n("Window Preview"), icon: "view-preview", page: "settings/PreviewPage.qml" }
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
            // This triggers the C++ updateSize and Input Region logic
            DockVisibility.liveEditMode = settingsWindow.visible;
            DockVisibility.setInteracting(settingsWindow.visible);
        }
    }

    Rectangle {
        id: settingsChassis
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        radius: 12
        border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.15)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit
            spacing: 0

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: tileHeight; color: "transparent"
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: Kirigami.Units.largeSpacing; anchors.rightMargin: Kirigami.Units.largeSpacing
                    Kirigami.Icon { source: "preferences-system"; Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium; Layout.preferredHeight: width }
                    QQC2.Label { text: "Krema Settings"; font.bold: true; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
                    QQC2.ToolButton { icon.name: settingsWindow.isPinned ? "window-pin" : "window-unpin"; onClicked: settingsWindow.isPinned = !settingsWindow.isPinned }
		    QQC2.ToolButton { icon.name: "window-close"; onClicked: SettingsController.visible = false }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Kirigami.Theme.textColor; opacity: 0.1 }

            RowLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0
                Rectangle {
                    Layout.preferredWidth: 200; Layout.fillHeight: true; color: "transparent"
                    StackView { id: sidebarStack; anchors.fill: parent; initialItem: mainMenuComponent }
                }
                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Kirigami.Theme.textColor; opacity: 0.1 }
                Loader { id: pageLoader; Layout.fillWidth: true; Layout.fillHeight: true; source: "settings/VisibilityPage.qml" }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Kirigami.Theme.textColor; opacity: 0.1 }
            
            RowLayout {
                Layout.fillWidth: true; Layout.preferredHeight: tileHeight
                anchors.leftMargin: Kirigami.Units.largeSpacing; anchors.rightMargin: Kirigami.Units.largeSpacing
                QQC2.Button { text: i18n("Add Widgets..."); flat: true; enabled: false; icon.name: "list-add" }
                Item { Layout.fillWidth: true }
		QQC2.Button { text: i18n("Close"); icon.name: "dialog-close"; onClicked: SettingsController.visible = false }
            }
        }
    }

    Component {
        id: mainMenuComponent
        ColumnLayout {
            spacing: 0
            ListView {
                model: settingsWindow.menuData
                Layout.fillWidth: true
                Layout.preferredHeight: count * tileHeight
                currentIndex: -1
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                delegate: QQC2.ItemDelegate {
                    width: parent.width
                    height: tileHeight
                    highlighted: ListView.isCurrentItem
                    leftPadding: Kirigami.Units.largeSpacing
                    rightPadding: Kirigami.Units.largeSpacing
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon { source: modelData.icon; Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium; Layout.preferredHeight: width }
                        QQC2.Label { text: modelData.name; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter; color: highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor }
                        Kirigami.Icon { source: "go-next-symbolic"; Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: width; visible: modelData.subItems !== undefined; opacity: highlighted ? 1.0 : 0.5 }
                    }
                    onClicked: {
                        if (modelData.subItems) sidebarStack.push(subMenuComponent, { "categoryName": modelData.name, "subModel": modelData.subItems })
                        else pageLoader.source = modelData.page
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }

    Component {
        id: subMenuComponent
        ColumnLayout {
            spacing: 0
            property string categoryName: ""
            property var subModel: []
            QQC2.ItemDelegate {
                Layout.fillWidth: true; height: tileHeight
                onClicked: sidebarStack.pop()
                leftPadding: Kirigami.Units.largeSpacing
                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Icon { source: "go-previous-symbolic"; Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium; Layout.preferredHeight: width }
                    QQC2.Label { text: categoryName; font.bold: true; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Kirigami.Theme.textColor; opacity: 0.1 }
            ListView {
                Layout.fillWidth: true; Layout.preferredHeight: count * tileHeight; model: subModel; currentIndex: -1; clip: true
                delegate: QQC2.ItemDelegate {
                    width: parent.width; height: tileHeight
                    highlighted: ListView.isCurrentItem
                    leftPadding: Kirigami.Units.largeSpacing * 2
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon { source: modelData.icon || ""; Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: width }
                        QQC2.Label { text: modelData.name; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter; color: highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor }
                    }
                    onClicked: pageLoader.source = modelData.page
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
