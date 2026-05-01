// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.bhyoo.krema 1.0

FormCard.FormCardPage {
    title: i18n("Visibility")

    FormCard.FormCard {
        FormCard.FormComboBoxDelegate {
            text: i18n("Visibility mode")
            displayMode: FormCard.FormComboBoxDelegate.Dialog
            model: [i18n("Always visible"), i18n("Auto hide"), i18n("Dodge windows")]
            currentIndex: DockSettings.visibilityMode
            onActivated: function(index) { DockSettings.visibilityMode = index }
        }
        FormCard.FormDelegateSeparator { visible: DockSettings.visibilityMode === 0 }
        FormCard.FormSwitchDelegate {
            text: i18n("Reserve screen space")
            checked: DockSettings.reserveSpace
            onCheckedChanged: DockSettings.reserveSpace = checked
            visible: DockSettings.visibilityMode === 0
        }
        FormCard.FormDelegateSeparator { visible: DockSettings.visibilityMode === 2 }
        FormCard.FormSwitchDelegate {
            text: i18n("Only dodge active window")
            checked: DockSettings.dodgeActiveOnly
            onCheckedChanged: DockSettings.dodgeActiveOnly = checked
            visible: DockSettings.visibilityMode === 2
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormComboBoxDelegate {
            text: i18n("Screen edge")
            displayMode: FormCard.FormComboBoxDelegate.Dialog
            model: [i18n("Top"), i18n("Bottom"), i18n("Left"), i18n("Right")]
            currentIndex: DockSettings.edge
            onActivated: function(index) { DockSettings.edge = index }
        }
    }
}
