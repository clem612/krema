// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.bhyoo.krema 1.0

FormCard.FormCardPage {
    title: i18n("Shadow")

    FormCard.FormCard {
        FormCard.FormSwitchDelegate {
            text: i18n("Enable shadow")
            checked: DockSettings.shadowEnabled
            onToggled: DockSettings.shadowEnabled = checked
        }

        FormCard.FormDelegateSeparator { visible: DockSettings.shadowEnabled }

        FormCard.AbstractFormDelegate {
            id: lightXDelegate; visible: DockSettings.shadowEnabled; background: null
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                RowLayout {
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Light X"); color: lightXDelegate.enabled ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor }
                    QQC2.Label { text: lightXSlider.value; color: Kirigami.Theme.disabledTextColor }
                }
                QQC2.Slider { id: lightXSlider; Layout.fillWidth: true; from: -300; to: 300; stepSize: 10; value: DockSettings.shadowLightX; onMoved: DockSettings.shadowLightX = value }
            }
        }

        FormCard.FormDelegateSeparator { visible: DockSettings.shadowEnabled }

        FormCard.AbstractFormDelegate {
            id: lightYDelegate; visible: DockSettings.shadowEnabled; background: null
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                RowLayout {
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Light Y"); color: lightYDelegate.enabled ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor }
                    QQC2.Label { text: lightYSlider.value; color: Kirigami.Theme.disabledTextColor }
                }
                QQC2.Slider { id: lightYSlider; Layout.fillWidth: true; from: -300; to: 300; stepSize: 10; value: DockSettings.shadowLightY; onMoved: DockSettings.shadowLightY = value }
            }
        }

        FormCard.FormDelegateSeparator { visible: DockSettings.shadowEnabled }

        FormCard.AbstractFormDelegate {
            id: lightZDelegate; visible: DockSettings.shadowEnabled; background: null
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                RowLayout {
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Light Z (height)"); color: lightZDelegate.enabled ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor }
                    QQC2.Label { text: lightZSlider.value; color: Kirigami.Theme.disabledTextColor }
                }
                QQC2.Slider { id: lightZSlider; Layout.fillWidth: true; from: 100; to: 2000; stepSize: 20; value: DockSettings.shadowLightZ; onMoved: DockSettings.shadowLightZ = value }
            }
        }

        FormCard.FormDelegateSeparator { visible: DockSettings.shadowEnabled }

        FormCard.AbstractFormDelegate {
            id: lightRadiusDelegate; visible: DockSettings.shadowEnabled; background: null
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                RowLayout {
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Light radius"); color: lightRadiusDelegate.enabled ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor }
                    QQC2.Label { text: lightRadiusSlider.value.toFixed(1) + "px"; color: Kirigami.Theme.disabledTextColor }
                }
                QQC2.Slider { id: lightRadiusSlider; Layout.fillWidth: true; from: 0.5; to: 20.0; stepSize: 0.5; value: DockSettings.shadowLightRadius; onMoved: DockSettings.shadowLightRadius = value }
            }
        }

        FormCard.FormDelegateSeparator { visible: DockSettings.shadowEnabled }

        FormCard.FormSpinBoxDelegate {
            visible: DockSettings.shadowEnabled
            label: i18n("Elevation")
            from: 1; to: 50
            value: DockSettings.shadowElevation
            onValueChanged: DockSettings.shadowElevation = value
        }

        FormCard.FormDelegateSeparator { visible: DockSettings.shadowEnabled }

        FormCard.AbstractFormDelegate {
            id: intensityDelegate; visible: DockSettings.shadowEnabled; background: null
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                RowLayout {
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Shadow intensity"); color: intensityDelegate.enabled ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor }
                    QQC2.Label { text: Math.round(intensitySlider.value * 100) + "%"; color: Kirigami.Theme.disabledTextColor }
                }
                QQC2.Slider { id: intensitySlider; Layout.fillWidth: true; from: 0.0; to: 1.0; stepSize: 0.05; value: DockSettings.shadowIntensity; onMoved: DockSettings.shadowIntensity = value }
            }
        }

        FormCard.FormDelegateSeparator { visible: DockSettings.shadowEnabled }

        FormCard.AbstractFormDelegate {
            id: colorDelegate; visible: DockSettings.shadowEnabled; background: null
            contentItem: RowLayout {
                QQC2.Label { Layout.fillWidth: true; text: i18n("Shadow color"); color: colorDelegate.enabled ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor }
                Rectangle {
                    width: 40; height: 24; radius: 4
                    color: DockSettings.shadowColor
                    border.color: Kirigami.Theme.disabledTextColor
                    MouseArea { anchors.fill: parent; onClicked: shadowColorDialog.open() }
                }
            }
        }
    }
    ColorDialog { id: shadowColorDialog; title: i18n("Choose shadow color"); selectedColor: DockSettings.shadowColor; onAccepted: DockSettings.shadowColor = selectedColor }
}
