// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import com.bhyoo.krema 1.0

// Import our custom UI Kit
import "../components"

QQC2.ScrollView {
    id: monitorPage
    contentWidth: availableWidth
    clip: true

    // Standard spacing used across all pages
    topPadding: 16
    bottomPadding: 32
    leftPadding: 16
    rightPadding: 16

    ColumnLayout {
        width: parent.width
        spacing: 32

        // --- SECTION 1: MONITOR CONFIG ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Monitor Configuration")
                color: "#80FFFDD0" // 50% opacity Krema Accent
                font.bold: true; font.letterSpacing: 1.1; font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        QQC2.Label { text: i18n("Display Mode"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { 
                            text: i18n("Choose which monitors should display the dock."); 
                            color: "#80FFFDD0"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true 
                        }
                    }
                    KremaComboBox {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 200 // Prevents the dropdown from stretching too wide
                        model: [i18n("Primary monitor only"), i18n("All monitors"), i18n("Follow active screen")]
                        currentIndex: DockSettings.monitorMode
                        onActivated: function(index) { DockSettings.monitorMode = index }
                    }
                }
            }
        }
    }
}
