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
    id: virtualDesktopsPage
    contentWidth: availableWidth
    clip: true

    // Standard spacing for a consistent "Krema" feel
    topPadding: 16
    bottomPadding: 32
    leftPadding: 16
    rightPadding: 16

    ColumnLayout {
        width: parent.width
        spacing: 32

        // --- SECTION 1: DESKTOP WORKFLOW ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Desktop Workflow")
                color: "#80FFFDD0" // 50% opacity Krema Accent
                font.bold: true; font.letterSpacing: 1.1; font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                // DISPLAY MODE
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        QQC2.Label { text: i18n("Icon Display Mode"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { 
                            text: i18n("Filter which windows are shown based on your current workspace."); 
                            color: "#80FFFDD0"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true 
                        }
                    }
                    KremaComboBox {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 180
                        model: [i18n("Show all windows"), i18n("Dim other desktops"), i18n("Current desktop only")]
                        currentIndex: DockSettings.virtualDesktopMode
                        onActivated: function(index) { DockSettings.virtualDesktopMode = index }
                    }
                }

                Rectangle { 
                    Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A"
                    visible: DockSettings.virtualDesktopMode === 1 // Only show if "Dim other desktops" is active
                }

                // CONDITIONAL: DIM OPACITY SLIDER
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: DockSettings.virtualDesktopMode === 1
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Inactive Desktop Opacity"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: Math.round(dimOpacitySlider.value * 100) + "%"; color: "#80FFFDD0"; font.bold: true }
                    }
                    QQC2.Slider {
                        id: dimOpacitySlider; Layout.fillWidth: true; 
                        from: 0.1; to: 0.9; stepSize: 0.05; 
                        value: DockSettings.otherDesktopOpacity; 
                        onMoved: DockSettings.otherDesktopOpacity = value 
                    }
                }
            }
        }
    }
}
