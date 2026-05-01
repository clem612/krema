// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.bhyoo.krema 1.0

FormCard.FormCardPage {
    title: i18n("Multi-Monitor")

    FormCard.FormCard {
        FormCard.FormComboBoxDelegate {
            text: i18n("Monitor mode")
            model: [i18n("Primary monitor only"), i18n("All monitors"), i18n("Follow active screen")]
            currentIndex: DockSettings.monitorMode
            onActivated: function(index) { DockSettings.monitorMode = index }
        }
    }
}
