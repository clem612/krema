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
    title: i18n("Background & Panel")

    FormCard.FormCard {
        FormCard.FormComboBoxDelegate {
            id: styleCombo
            text: i18n("Style")
            model: [i18n("Panel Inherit"), i18n("Transparent"), i18n("Tinted"), i18n("Acrylic")]
            currentIndex: DockSettings.backgroundStyle
            onActivated: function(index) { DockSettings.backgroundStyle = index }
        }

        FormCard.FormDelegateSeparator { visible: DockSettings.backgroundStyle !== 1 }

        FormCard.AbstractFormDelegate {
            visible: DockSettings.backgroundStyle !== 1
            contentItem: ColumnLayout {
                RowLayout {
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Opacity") }
                    QQC2.Label { text: Math.round(opacitySlider.value * 100) + "%" }
                }
                QQC2.Slider {
                    id: opacitySlider; Layout.fillWidth: true
                    from: 0.0; to: 1.0; stepSize: 0.05
                    value: DockSettings.backgroundOpacity
                    onMoved: DockSettings.backgroundOpacity = value
                }
            }
        }

        FormCard.FormDelegateSeparator { visible: DockSettings.backgroundStyle === 2 }

        FormCard.FormSwitchDelegate {
            visible: DockSettings.backgroundStyle === 2
            text: i18n("Use system color")
            checked: DockSettings.useSystemColor
            onToggled: DockSettings.useSystemColor = checked
        }

        FormCard.FormDelegateSeparator { visible: DockSettings.backgroundStyle === 2 && !DockSettings.useSystemColor }

        FormCard.AbstractFormDelegate {
            visible: DockSettings.backgroundStyle === 2 && !DockSettings.useSystemColor
            contentItem: RowLayout {
                QQC2.Label { Layout.fillWidth: true; text: i18n("Tint color") }
                Rectangle {
                    width: 40; height: 24; radius: 4
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

        FormCard.FormDelegateSeparator {}

        FormCard.FormSpinBoxDelegate {
            label: i18n("Panel thickness")
            from: 10; to: DockSettings.iconSize + 24; stepSize: 2
            value: DockSettings.panelHeight
            onValueChanged: {
                DockSettings.panelHeight = value
                DockSettings.save()
            }
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormSpinBoxDelegate {
            label: i18n("Corner radius")
            from: 0; to: 24
            value: DockSettings.cornerRadius
            onValueChanged: DockSettings.cornerRadius = value
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormSwitchDelegate {
            text: i18n("floating")
            checked: DockSettings.floating
            onToggled: DockSettings.floating = checked
        }
    }

    // THE CUSTOM COLOR PICKER POPUP
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
