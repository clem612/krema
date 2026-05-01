// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.bhyoo.krema 1.0

FormCard.FormCardPage {
    title: i18n("Virtual Desktops")

    FormCard.FormCard {
        FormCard.FormComboBoxDelegate {
            text: i18n("Display mode")
            model: [i18n("Show all windows"), i18n("Dim other desktops"), i18n("Current desktop only")]
            currentIndex: DockSettings.virtualDesktopMode
            onActivated: function(index) { DockSettings.virtualDesktopMode = index }
        }
        FormCard.FormDelegateSeparator { visible: DockSettings.virtualDesktopMode === 1 }
        FormCard.AbstractFormDelegate {
            visible: DockSettings.virtualDesktopMode === 1
            contentItem: ColumnLayout {
                RowLayout {
                    Layout.fillWidth: true
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Other desktop opacity") }
                    QQC2.Label { text: Math.round(dimOpacitySlider.value * 100) + "%" }
                }
                QQC2.Slider {
                    id: dimOpacitySlider; Layout.fillWidth: true; from: 0.1; to: 0.9; stepSize: 0.05
                    value: DockSettings.otherDesktopOpacity; onMoved: DockSettings.otherDesktopOpacity = value
                }
            }
        }
    }
}
