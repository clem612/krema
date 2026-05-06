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
    id: panelPage
    contentWidth: availableWidth
    clip: true

    topPadding: 16
    bottomPadding: 32
    leftPadding: 16
    rightPadding: 16

    ColumnLayout {
        width: parent.width
        spacing: 32

        // --- SECTION 1: PHYSICAL GEOMETRY ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Geometry & Structure")
                color: "#80FFFDD0"
                font.bold: true; font.letterSpacing: 1.1; font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                // PANEL THICKNESS
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Panel Thickness"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: thicknessSlider.value + "px"; color: "#80FFFDD0"; font.bold: true }
                    }
                    QQC2.Slider {
                        id: thicknessSlider; Layout.fillWidth: true; 
                        from: 10; to: DockSettings.iconSize + 24; stepSize: 2; 
                        value: DockSettings.panelHeight; 
                        onMoved: {
                            DockSettings.panelHeight = value
                            DockSettings.save()
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // CORNER RADIUS
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Corner Radius"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: radiusSlider.value + "px"; color: "#80FFFDD0"; font.bold: true }
                    }
                    QQC2.Slider {
                        id: radiusSlider; Layout.fillWidth: true; 
                        from: 0; to: 48; stepSize: 1; 
                        value: DockSettings.cornerRadius; 
                        onMoved: DockSettings.cornerRadius = value 
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // FLOATING SWITCH
                KremaSwitch {
                    Layout.fillWidth: true
                    text: i18n("Floating Dock")
                    checked: DockSettings.floating
                    onToggled: DockSettings.floating = checked
                }
                QQC2.Label { 
                    text: i18n("Detaches the dock from the screen edge for a modern, pill-shaped look."); 
                    color: "#80FFFDD0"; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.topMargin: -8
                }
            }
        }
    }
}
