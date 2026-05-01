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
                   MouseArea { anchors.fill: parent; onClicked: colorDialog.open() }
               }
           }
       }

       // --- Physical Panel Section ---
       FormCard.FormDelegateSeparator {}

       FormCard.FormSpinBoxDelegate {
           label: i18n("Panel thickness")
           from: 30; to: 150; stepSize: 2
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
           text: i18n("Floating")
           checked: DockSettings.floating
           onToggled: DockSettings.floating = checked
       }
   }
   ColorDialog { id: colorDialog; title: i18n("Choose tint color"); selectedColor: DockSettings.tintColor; onAccepted: DockSettings.tintColor = selectedColor }
}
