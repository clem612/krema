// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard 

Rectangle {
    id: aboutRoot
    color: Kirigami.Theme.backgroundColor
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.gridUnit
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "com.bhyoo.krema"
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: width
            Layout.alignment: Qt.AlignHCenter
        }

        QQC2.Label {
            text: "Krema"
            font.bold: true
            font.pointSize: 20
            Layout.alignment: Qt.AlignHCenter
        }

        QQC2.Label {
            text: i18n("A fast, modular dock for KDE Plasma 6")
            opacity: 0.7
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Kirigami.Units.gridUnit
        }

        FormCard.FormCard {
            Layout.fillWidth: true
            FormCard.FormTextDelegate {
                text: i18n("Version")
                description: "1.0.0-beta"
            }
            FormCard.FormDelegateSeparator {}
            FormCard.FormTextDelegate {
                text: i18n("Author")
                description: "Byeonghoon Yoo"
            }
            FormCard.FormDelegateSeparator {}
            FormCard.FormTextDelegate {
                text: i18n("License")
                description: "GPL-3.0-or-later"
            }
        }

        Item { Layout.fillHeight: true }

        QQC2.Button {
            text: i18n("Report Bug")
            icon.name: "tools-report-bug"
            flat: true
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
