// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Window
import com.bhyoo.krema 1.0
import "../components"

QQC2.ScrollView {
    id: appearancePage
    contentWidth: availableWidth
    clip: true
    
    // We bind to the global settings window's advanced mode state
    property bool advancedMode: typeof configViewItem !== "undefined" ? configViewItem.isAdvancedMode : false

    topPadding: 24
    bottomPadding: 32
    leftPadding: 48
    rightPadding: 48

    ColumnLayout {
        id: mainLayout
        width: parent.width
        spacing: 32

        // ==========================================
        // SECTION: VISUAL STYLE
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16

            QQC2.Label {
                text: i18n("Visual Style")
                color: theme.text
                font.pointSize: 14
                font.weight: Font.DemiBold
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: theme.border }

            // COLOR MODE
            RowLayout {
                Layout.fillWidth: true
                QQC2.Label { text: i18n("Color Mode"); color: theme.text; font.pointSize: 10 }
                Item { Layout.fillWidth: true } // Spacer
                RowLayout {
                    spacing: 0
                    Repeater {
                        model: [
                            { label: i18n("Light"), value: 0 },
                            { label: i18n("Dark"), value: 1 }
                        ]
                        delegate: QQC2.Button {
                            id: themeBtn
                            property bool isSelected: DockSettings.settingsThemeMode === modelData.value
                            text: modelData.label
                            leftPadding: 24; rightPadding: 24
                            background: Rectangle {
                                implicitHeight: 28
                                color: themeBtn.isSelected ? theme.accent : (themeBtn.hovered ? Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.1) : "transparent")
                                border.color: theme.border; border.width: 1
                                radius: index === 0 ? 4 : (index === 1 ? 4 : 0) // Basic segmented look
                                Rectangle { // hide overlapping border
                                    width: 1; height: parent.height; color: themeBtn.isSelected ? theme.accent : theme.border; visible: index === 1; anchors.left: parent.left
                                }
                            }
                            contentItem: QQC2.Label {
                                text: themeBtn.text
                                color: themeBtn.isSelected ? theme.base : theme.text
                                font.weight: themeBtn.isSelected ? Font.Bold : Font.Normal
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: { DockSettings.settingsThemeMode = modelData.value; DockSettings.save(); }
                        }
                    }
                }
            }
            
            // BASE MATERIAL
            RowLayout {
                Layout.fillWidth: true
                QQC2.Label { text: i18n("Base Material"); color: theme.text; font.pointSize: 10 }
                Item { Layout.fillWidth: true } // Spacer
                QQC2.ComboBox {
                    Layout.preferredWidth: 200
                    model: [
                        { label: i18n("System Adaptive"), value: 0 },
                        { label: i18n("Transparent"), value: 1 },
                        { label: i18n("Solid Color"), value: 2 },
                        { label: i18n("Acrylic Blur"), value: 3 },
                        { label: i18n("Accent Tint"), value: 4 }
                    ]
                    textRole: "label"
                    valueRole: "value"
                    currentIndex: {
                        for (let i = 0; i < model.length; i++) {
                            if (model[i].value === DockSettings.backgroundStyle) return i;
                        }
                        return 0;
                    }
                    onActivated: { DockSettings.backgroundStyle = currentValue; DockSettings.save(); }
                }
            }
        }

        // ==========================================
        // SECTION: COLOR & OPACITY (Advanced Only or dynamically visible)
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16
            visible: DockSettings.backgroundStyle !== 1 

            QQC2.Label {
                text: i18n("Color & Opacity")
                color: theme.text
                font.pointSize: 14
                font.weight: Font.DemiBold
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: theme.border }

            // TINT COLOR SOURCE
            RowLayout {
                Layout.fillWidth: true
                visible: DockSettings.backgroundStyle === 2 || DockSettings.backgroundStyle === 3
                QQC2.Label { text: i18n("Tint Color Source"); color: theme.text; font.pointSize: 10 }
                Item { Layout.fillWidth: true }
                QQC2.ComboBox {
                    Layout.preferredWidth: 200
                    model: [ i18n("Custom Solid Color"), i18n("System Accent Color"), i18n("Wallpaper Color") ]
                    currentIndex: DockSettings.useWallpaperColor ? 2 : (DockSettings.useSystemColor ? 1 : 0)
                    onActivated: {
                        if (currentIndex === 0) { DockSettings.useWallpaperColor = false; DockSettings.useSystemColor = false; }
                        else if (currentIndex === 1) { DockSettings.useWallpaperColor = false; DockSettings.useSystemColor = true; }
                        else if (currentIndex === 2) { DockSettings.useWallpaperColor = true; DockSettings.useSystemColor = false; }
                        DockSettings.save();
                    }
                }
            }

            // CUSTOM COLOR PICKER
            RowLayout {
                Layout.fillWidth: true
                visible: colorSourceComboVisible() && (DockSettings.backgroundStyle === 2 || DockSettings.backgroundStyle === 3)
                function colorSourceComboVisible() { return !DockSettings.useWallpaperColor && !DockSettings.useSystemColor; }

                QQC2.Label { text: i18n("Custom Tint Color"); color: theme.text; font.pointSize: 10 }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 48; height: 24; radius: 4
                    color: DockSettings.tintColor
                    border.color: theme.border; border.width: 1
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: colorPickerPopup.open() }
                }
            }

            // OPACITY SLIDER
            RowLayout {
                Layout.fillWidth: true
                QQC2.Label { 
                    text: DockSettings.backgroundStyle === 4 ? i18n("Accent Intensity") : i18n("Background Opacity")
                    color: theme.text; font.pointSize: 10 
                }
                Item { Layout.preferredWidth: 64 }
                QQC2.Slider {
                    id: opacitySlider
                    Layout.fillWidth: true
                    from: 0.3; to: 1.0; stepSize: 0.05
                    value: DockSettings.backgroundOpacity
                    onMoved: { DockSettings.backgroundOpacity = value; DockSettings.save(); }
                }
                QQC2.Label { 
                    text: Math.round(opacitySlider.value * 100) + "%"
                    color: theme.textDim; font.pointSize: 10; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight
                }
            }
        }

        // ==========================================
        // SECTION: EDGE HIGHLIGHT
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                QQC2.Label {
                    text: i18n("Edge Highlight (Rim Light)")
                    color: theme.text
                    font.pointSize: 14
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
                KremaSwitch {
                    checked: DockSettings.rimLightEnabled
                    onToggled: { DockSettings.rimLightEnabled = checked; DockSettings.save(); }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: theme.border }

            // RIM LIGHT OPACITY (Advanced Only)
            RowLayout {
                Layout.fillWidth: true
                visible: appearancePage.advancedMode && DockSettings.rimLightEnabled
                QQC2.Label { text: i18n("Intensity"); color: theme.text; font.pointSize: 10 }
                Item { Layout.preferredWidth: 64 }
                QQC2.Slider {
                    id: rimLightSlider; Layout.fillWidth: true
                    from: 0.05; to: 0.5; stepSize: 0.05
                    value: DockSettings.rimLightOpacity
                    onMoved: { DockSettings.rimLightOpacity = value; DockSettings.save(); }
                }
                QQC2.Label { text: Math.round(rimLightSlider.value * 100) + "%"; color: theme.textDim; font.pointSize: 10; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
            }
        }
    }

    // --- CUSTOM COLOR PICKER POPUP ---
    QQC2.Popup {
        id: colorPickerPopup
        parent: appearancePage.Window.window ? appearancePage.Window.window.contentItem : appearancePage
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: Kirigami.Units.gridUnit * 18
        modal: true
        focus: true
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

        background: Rectangle { color: theme.card; radius: 12; border.color: theme.border; border.width: 1 }

        property real rVal: 0
        property real gVal: 0
        property real bVal: 0
        property color tempColor: Qt.rgba(rVal, gVal, bVal, 1.0)

        onOpened: {
            let tint = DockSettings.tintColor;
            let c = (tint && tint.length > 0) ? Qt.color(tint) : Qt.color("white");
            rVal = c.r; gVal = c.g; bVal = c.b;
        }

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label { text: i18n("Custom Tint Color"); font.weight: Font.Bold; color: theme.text; Layout.alignment: Qt.AlignHCenter }

            Rectangle {
                Layout.fillWidth: true; height: Kirigami.Units.gridUnit * 4; radius: 8
                color: colorPickerPopup.tempColor; border.color: theme.border; border.width: 1
            }

            GridLayout {
                columns: 2; Layout.fillWidth: true
                QQC2.Label { text: "R:"; color: theme.textDim; font.bold: true }
                QQC2.Slider { Layout.fillWidth: true; from: 0; to: 1; value: colorPickerPopup.rVal; onMoved: colorPickerPopup.rVal = value }
                QQC2.Label { text: "G:"; color: theme.textDim; font.bold: true }
                QQC2.Slider { Layout.fillWidth: true; from: 0; to: 1; value: colorPickerPopup.gVal; onMoved: colorPickerPopup.gVal = value }
                QQC2.Label { text: "B:"; color: theme.textDim; font.bold: true }
                QQC2.Slider { Layout.fillWidth: true; from: 0; to: 1; value: colorPickerPopup.bVal; onMoved: colorPickerPopup.bVal = value }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                QQC2.Button { text: i18n("Cancel"); onClicked: colorPickerPopup.close() }
                QQC2.Button {
                    text: i18n("Save"); highlighted: true
                    onClicked: { DockSettings.tintColor = colorPickerPopup.tempColor.toString(); DockSettings.save(); colorPickerPopup.close(); }
                }
            }
        }
    }
}
