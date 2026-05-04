// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import QtQuick.Window
import com.bhyoo.krema 1.0

FormCard.FormCardPage {
    id: bgPage
    title: i18n("Theme & Style")

    // --- PILLAR 1: MATERIAL ---
    FormCard.FormHeader { title: i18n("Base Material") }
    FormCard.FormCard {
        FormCard.FormComboBoxDelegate {
            id: styleCombo
            text: i18n("Style")
            description: i18n("The primary texture of the dock background.")
            // Cleaned up the confusing options. 
            // 0 = Adaptive, 1 = Solid, 2 = Acrylic
            model: [i18n("Adaptive (System Default)"), i18n("Solid Color"), i18n("Acrylic (Translucent)")]
            currentIndex: DockSettings.backgroundStyle
            onActivated: function(index) { DockSettings.backgroundStyle = index }
        }
    }

    // --- PILLAR 2: COLOR & OPACITY ---
    // Now always visible so Opacity is available for all styles
    FormCard.FormHeader { title: i18n("Color & Opacity") }
    FormCard.FormCard {
        
        // Toggle for System Color Override (Hide if Adaptive)
        FormCard.FormSwitchDelegate {
            visible: DockSettings.backgroundStyle > 0
            text: i18n("Use System Accent Color")
            description: i18n("Automatically match the dock to your current Plasma theme.")
            checked: DockSettings.useSystemColor
            onToggled: DockSettings.useSystemColor = checked
        }

        FormCard.FormDelegateSeparator { 
            visible: DockSettings.backgroundStyle > 0 && !DockSettings.useSystemColor 
        }

        // Custom Color Picker (Hide if Adaptive OR using System Color)
        FormCard.AbstractFormDelegate {
            visible: DockSettings.backgroundStyle > 0 && !DockSettings.useSystemColor
            contentItem: RowLayout {
                QQC2.Label { Layout.fillWidth: true; text: i18n("Custom Tint Color") }
                Rectangle {
                    width: Kirigami.Units.gridUnit * 2
                    height: Kirigami.Units.gridUnit * 1.2
                    radius: Kirigami.Units.smallSpacing
                    color: DockSettings.tintColor
                    border.color: Kirigami.Theme.disabledTextColor
                    border.width: 1
                    MouseArea { 
                        anchors.fill: parent
                        onClicked: colorPickerPopup.open() 
                    }
                }
            }
        }

        FormCard.FormDelegateSeparator { visible: DockSettings.backgroundStyle > 0 }

        // Opacity Slider (ALWAYS VISIBLE)
        FormCard.AbstractFormDelegate {
            contentItem: ColumnLayout {
                RowLayout {
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Background Opacity") }
                    QQC2.Label { text: Math.round(opacitySlider.value * 100) + "%" }
                }
                QQC2.Slider {
                    id: opacitySlider
                    Layout.fillWidth: true
                    from: 0.0; to: 1.0; stepSize: 0.05
                    value: DockSettings.backgroundOpacity
                    onMoved: DockSettings.backgroundOpacity = value
                }
            }
        }
    }

    // --- PILLAR 3: GEOMETRY ---
    // (Note: You might move this to a "Layout" page later, but for now it lives here)
    FormCard.FormHeader { title: i18n("Geometry") }
    FormCard.FormCard {
        FormCard.FormSpinBoxDelegate {
            label: i18n("Corner Radius")
            description: i18n("How round the edges of the dock should be.")
            from: 0; to: 24
            value: DockSettings.cornerRadius
            onValueChanged: DockSettings.cornerRadius = value
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormSpinBoxDelegate {
            label: i18n("Panel Thickness")
            from: 10; to: DockSettings.iconSize + 24; stepSize: 2
            value: DockSettings.panelHeight
            onValueChanged: {
                DockSettings.panelHeight = value
                DockSettings.save()
            }
        }
        
        FormCard.FormDelegateSeparator {}

        FormCard.FormSwitchDelegate {
            text: i18n("Floating Dock")
            description: i18n("Detach the dock from the screen edge.")
            checked: DockSettings.floating
            onToggled: DockSettings.floating = checked
        }
    }

    // THE CUSTOM COLOR PICKER POPUP (Kept exactly as you had it)
    QQC2.Popup {
        id: colorPickerPopup
        parent: bgPage.Window.window ? bgPage.Window.window.contentItem : bgPage
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: Kirigami.Units.gridUnit * 18
        modal: true
        focus: true
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

        property real rVal: 0
        property real gVal: 0
        property real bVal: 0
        property color tempColor: Qt.rgba(rVal, gVal, bVal, 1.0)

        onOpened: {
            let c = Qt.color(DockSettings.tintColor);
            rVal = c.r; gVal = c.g; bVal = c.b;
        }

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: i18n("Custom Tint Color")
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 4
                radius: Kirigami.Units.smallSpacing
                color: colorPickerPopup.tempColor
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1
            }

            GridLayout {
                columns: 2
                Layout.fillWidth: true
                QQC2.Label { text: "R:" }
                QQC2.Slider { Layout.fillWidth: true; from: 0; to: 1; value: colorPickerPopup.rVal; onMoved: colorPickerPopup.rVal = value }
                QQC2.Label { text: "G:" }
                QQC2.Slider { Layout.fillWidth: true; from: 0; to: 1; value: colorPickerPopup.gVal; onMoved: colorPickerPopup.gVal = value }
                QQC2.Label { text: "B:" }
                QQC2.Slider { Layout.fillWidth: true; from: 0; to: 1; value: colorPickerPopup.bVal; onMoved: colorPickerPopup.bVal = value }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                QQC2.Button { text: i18n("Cancel"); onClicked: colorPickerPopup.close() }
                QQC2.Button {
                    text: i18n("Save")
                    highlighted: true
                    onClicked: {
                        DockSettings.tintColor = colorPickerPopup.tempColor.toString();
                        DockSettings.save();
                        colorPickerPopup.close();
                    }
                }
            }
        }
    }
}
