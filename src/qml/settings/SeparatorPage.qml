// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.bhyoo.krema 1.0

FormCard.FormCardPage {
    title: i18n("Separator")

    FormCard.FormCard {
        FormCard.FormComboBoxDelegate {
            text: i18n("Style")
            model: [i18n("Classic Line"), i18n("Blueprint Dots")]
            currentIndex: DockSettings.separatorStyle
            onActivated: function(index) { DockSettings.separatorStyle = index }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.AbstractFormDelegate {
            contentItem: ColumnLayout {
                RowLayout {
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Opacity") }
                    QQC2.Label { text: Math.round(sepOpacitySlider.value * 100) + "%" }
                }
                QQC2.Slider {
                    id: sepOpacitySlider; Layout.fillWidth: true
                    from: 0.0; to: 1.0; value: DockSettings.separatorOpacity
                    onMoved: DockSettings.separatorOpacity = value
                }
            }
        }
    }
}
