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
   implicitWidth: 780 // Slightly wider to accommodate horizontal tabs comfortably
   implicitHeight: 620

   property bool isPinned: false
   property var configViewItem: settingsWindow
   
   // State Tracking for Tabs
   property int currentCategoryIndex: 0
   property int currentSubItemIndex: 0

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

       for (var i = 0; i < settingsWindow.menuData.length; i++) {
           var cat = settingsWindow.menuData[i]
           if (cat.id === target) {
               currentCategoryIndex = i
               pageLoader.source = cat.page
               return
           }
           if (cat.subItems) {
               for (var j = 0; j < cat.subItems.length; j++) {
                   if (cat.subItems[j].id === target) {
                       currentCategoryIndex = i
                       currentSubItemIndex = j
                       pageLoader.source = cat.subItems[j].page
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
       // Save to disk whenever the window is hidden (Kill-Proofing)
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

       ColumnLayout {
           anchors.fill: parent
           spacing: 0

           // --- 1. TOP NAVIGATION BAR (MAIN CATEGORIES) ---
           Rectangle {
               Layout.fillWidth: true
               Layout.preferredHeight: 60
               color: "#121112"

               RowLayout {
                   anchors.fill: parent
                   anchors.leftMargin: 24
                   anchors.rightMargin: 16
                   spacing: 16

                   // BRANDING
                   Label { 
                       text: "Krema"
                       color: "#FFFDD0" 
                       font.bold: true
                       font.pixelSize: 18
                       font.letterSpacing: 1.2
                       Layout.rightMargin: 16
                   }

                   // MAIN TABS
                   ListView {
                       id: mainTabBar
                       Layout.fillWidth: true
                       Layout.fillHeight: true
                       orientation: ListView.Horizontal
                       model: settingsWindow.menuData
                       currentIndex: settingsWindow.currentCategoryIndex
                       clip: true
                       boundsBehavior: Flickable.StopAtBounds

                       delegate: Item {
                           width: contentRow.width + 32
                           height: ListView.view.height
                           
                           property bool isSelected: index === settingsWindow.currentCategoryIndex

                           Rectangle {
                               anchors.bottom: parent.bottom
                               width: parent.width
                               height: 3
                               color: "#FFFDD0"
                               visible: isSelected
                           }

                           RowLayout {
                               id: contentRow
                               anchors.centerIn: parent
                               spacing: 8
                               Kirigami.Icon { 
                                   source: modelData.icon
                                   color: isSelected ? "#FFFDD0" : "#80FFFDD0"
                                   Layout.preferredWidth: 18; Layout.preferredHeight: 18 
                               }
                               Label { 
                                   text: modelData.name
                                   color: isSelected ? "#FFFDD0" : "#80FFFDD0"
                                   font.bold: isSelected
                               }
                           }

                           MouseArea {
                               anchors.fill: parent
                               hoverEnabled: true
                               cursorShape: Qt.PointingHandCursor
                               onClicked: {
                                   settingsWindow.currentCategoryIndex = index;
                                   var cat = settingsWindow.menuData[index];
                                   if (cat.subItems) {
                                       settingsWindow.currentSubItemIndex = 0;
                                       pageLoader.source = cat.subItems[0].page;
                                   } else {
                                       pageLoader.source = cat.page;
                                   }
                               }
                           }
                       }
                   }

                   // WINDOW CONTROLS
                   RowLayout {
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
           }

           Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

           // --- 2. SUB-NAVIGATION BAR (SUB-CATEGORIES) ---
           Rectangle {
               id: subNavContainer
               Layout.fillWidth: true
               // Only take up space if the current category has subItems
               Layout.preferredHeight: hasSubItems ? 48 : 0
               visible: hasSubItems
               color: "#1C1A1C"
               clip: true

               property bool hasSubItems: settingsWindow.menuData[settingsWindow.currentCategoryIndex].subItems !== undefined

               ListView {
                   id: subTabBar
                   anchors.fill: parent
                   orientation: ListView.Horizontal
                   model: subNavContainer.hasSubItems ? settingsWindow.menuData[settingsWindow.currentCategoryIndex].subItems : []
                   currentIndex: settingsWindow.currentSubItemIndex
                   clip: true
                   boundsBehavior: Flickable.StopAtBounds
                   
                   // Center the pills if there aren't many
                   anchors.leftMargin: 16
                   
                   delegate: Item {
                       width: subContent.width + 24
                       height: ListView.view.height

                       property bool isSelected: index === settingsWindow.currentSubItemIndex

                       Rectangle {
                           anchors.centerIn: parent
                           width: parent.width
                           height: 28
                           radius: 14 // Pill shape
                           color: isSelected ? "#1AFFFDD0" : (subMouse.containsMouse ? "#0AFFFDD0" : "transparent")
                           Behavior on color { ColorAnimation { duration: 150 } }
                       }

                       RowLayout {
                           id: subContent
                           anchors.centerIn: parent
                           spacing: 6
                           Kirigami.Icon { 
                               source: modelData.icon || ""
                               color: isSelected ? "#FFFDD0" : "#80FFFDD0"
                               Layout.preferredWidth: 14; Layout.preferredHeight: 14
                           }
                           Label { 
                               text: modelData.name
                               color: isSelected ? "#FFFDD0" : "#80FFFDD0"
                               font.weight: isSelected ? Font.Medium : Font.Normal
                           }
                       }

                       MouseArea {
                           id: subMouse
                           anchors.fill: parent
                           hoverEnabled: true
                           cursorShape: Qt.PointingHandCursor
                           onClicked: {
                               settingsWindow.currentSubItemIndex = index;
                               pageLoader.source = modelData.page;
                           }
                       }
                   }
               }
           }

           Rectangle { 
               Layout.fillWidth: true; 
               Layout.preferredHeight: 1; 
               color: "#2A282A"
               visible: subNavContainer.visible 
           }

           // --- 3. DYNAMIC CONTENT AREA ---
           Loader { 
               id: pageLoader
               Layout.fillWidth: true
               Layout.fillHeight: true
               // Add a tiny bit of margin so scrollbars aren't hugging the edge
               Layout.margins: 4
               source: "settings/BackgroundPage.qml" 
           }
       }
   }
}
