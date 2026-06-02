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
        id: panelLayout
        width: parent.width
        spacing: 32

        // Rule 6 Helpers: Mathematical Constitution for the Panel Ceiling
        readonly property real _floorPadding: Math.max(4, Math.round(DockSettings.iconSize * 0.25))
        readonly property real _dotHeight: Math.max(2, Math.round(DockSettings.iconSize * 0.10))
        readonly property real _indicatorGap: Math.max(2, Math.round(DockSettings.iconSize * 0.125) + Math.round(DockSettings.iconSize * 0.15 * (1.0 - DockSettings.indicatorOffset)))
        readonly property real _totalFloorUnit: _floorPadding + _dotHeight + _indicatorGap
        readonly property real _maxEnv: DockSettings.iconSize + _totalFloorUnit + _floorPadding + 16

        // --- SECTION 1: PHYSICAL GEOMETRY ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Geometry & Structure")
                color: theme.textDim
                font.bold: true; font.letterSpacing: 1.1; font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                // PANEL THICKNESS
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Panel Thickness"); color: theme.text; font.bold: true }
                        QQC2.Label { text: thicknessSlider.value + "px"; color: theme.textDim; font.bold: true }
                    }
                    QQC2.Slider {
                        id: thicknessSlider; Layout.fillWidth: true; 
                        // Rule 6: Math Always Wins. Max limit is IconSize + Floor Unit + Panel Ceiling.
                        from: 10; to: Math.floor(panelLayout._maxEnv); stepSize: 2; 
                        value: DockSettings.panelHeight; 
                        onMoved: DockSettings.panelHeight = value
                        onPressedChanged: if (!pressed) DockSettings.save()
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // DIMENSIONAL SYNC (Rule 7)
                KremaSwitch {
                    Layout.fillWidth: true
                    text: i18n("Proportional Scaling Lock")
                    checked: DockSettings.syncPanelThickness
                    onToggled: {
                        DockSettings.syncPanelThickness = checked
                        DockSettings.save()
                    }
                }
                QQC2.Label { 
                    text: i18n("Automatically adjusts panel thickness when resizing icons to preserve the visual overflow ratio."); 
                    color: theme.textDim; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.leftMargin: 32
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // MAXIMUM LENGTH
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Maximum Dock Length"); color: theme.text; font.bold: true }
                        QQC2.Label { text: maxLengthSlider.value + "%"; color: theme.textDim; font.bold: true }
                    }
                    QQC2.Slider {
                        id: maxLengthSlider; Layout.fillWidth: true; 
                        from: 10; to: 100; stepSize: 1; 
                        value: DockSettings.maxLength; 
                        onMoved: DockSettings.maxLength = value
                        onPressedChanged: if (!pressed) DockSettings.save()
                    }
                    QQC2.Label { 
                        text: i18n("In Adaptive mode, this is the maximum allowed width. In Span mode, this dictates the exact panel width (e.g. 100% = full screen)."); 
                        color: theme.textDim; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // PANEL LENGTH MODE
                ColumnLayout {
                    Layout.fillWidth: true
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Panel Length Mode"); color: theme.text; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.RadioButton {
                            text: i18n("Adaptive (Hugs Icons)")
                            checked: DockSettings.panelLengthMode === 0
                            onToggled: if (checked) { DockSettings.panelLengthMode = 0; DockSettings.save() }
                        }
                        QQC2.RadioButton {
                            text: i18n("Span Screen (Fixed Width)")
                            checked: DockSettings.panelLengthMode === 1
                            onToggled: if (checked) { DockSettings.panelLengthMode = 1; DockSettings.save() }
                        }
                    }
                    QQC2.Label { 
                        text: i18n("Adaptive mode shrinks the panel background to wrap your icons. Span mode physically stretches the panel background across the screen like a standard taskbar."); 
                        color: theme.textDim; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // CORNER RADIUS
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Corner Radius"); color: theme.text; font.bold: true }
                        QQC2.Label { text: radiusSlider.value + "px"; color: theme.textDim; font.bold: true }
                    }
                    QQC2.Slider {
                        id: radiusSlider; Layout.fillWidth: true; 
                        // Rule 6: UI Blindness Prevention. Max radius is mathematically capped at 
                        // half of the panel's thickness to prevent 'dead zones' and rendering glitches.
                        from: 0; to: Math.floor(thicknessSlider.value / 2); stepSize: 1; 
                        value: DockSettings.cornerRadius; 
                        onMoved: DockSettings.cornerRadius = value
                        onPressedChanged: if (!pressed) DockSettings.save()
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
                    color: theme.textDim; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
            }
        }
    }
}
