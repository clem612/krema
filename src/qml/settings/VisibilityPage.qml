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
    id: visibilityPage
    contentWidth: availableWidth
    clip: true

    topPadding: 16
    bottomPadding: 32
    leftPadding: 16
    rightPadding: 16

    ColumnLayout {
        width: parent.width
        spacing: 32

        // --- SECTION 1: AUTO-HIDE & DODGE ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Visibility Behavior")
                color: "#80FFFDD0"
                font.bold: true; font.letterSpacing: 1.1; font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                // VISIBILITY MODE
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        QQC2.Label { text: i18n("Visibility Mode"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { 
                            text: i18n("Choose how the dock interacts with other windows."); 
                            color: "#80FFFDD0"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true 
                        }
                    }
		    KremaComboBox {
                       Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                       model: [i18n("Always Visible"), i18n("Auto Hide"), i18n("Dodge Windows")]
                       currentIndex: DockSettings.visibilityMode
                       onActivated: function(index) { DockSettings.visibilityMode = index }
                   }
                }

                Rectangle { 
                    Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A"
                    visible: DockSettings.visibilityMode === 0 || DockSettings.visibilityMode === 2
                }

                // CONDITIONAL: RESERVE SPACE
                KremaSwitch {
                    Layout.fillWidth: true
                    visible: DockSettings.visibilityMode === 0
                    text: i18n("Reserve Screen Space")
                    checked: DockSettings.reserveSpace
                    onToggled: DockSettings.reserveSpace = checked
                }

                // CONDITIONAL: DODGE ACTIVE ONLY
                KremaSwitch {
                    Layout.fillWidth: true
                    visible: DockSettings.visibilityMode === 2
                    text: i18n("Only Dodge Active Window")
                    checked: DockSettings.dodgeActiveOnly
                    onToggled: DockSettings.dodgeActiveOnly = checked
                }
            }
        }

        // --- SECTION 2: PLACEMENT ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Placement")
                color: "#80FFFDD0"
                font.bold: true; font.letterSpacing: 1.1; font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                // SCREEN EDGE
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        QQC2.Label { text: i18n("Screen Edge"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { 
                            text: i18n("Which side of the monitor the dock is attached to."); 
                            color: "#80FFFDD0"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true 
                        }
                    }
		    KremaComboBox {
                       Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                       model: [i18n("Top"), i18n("Bottom"), i18n("Left"), i18n("Right")]
                       currentIndex: DockSettings.edge
                       onActivated: function(index) { DockSettings.edge = index }
                   }
	       }
            }
        }
    }
}
