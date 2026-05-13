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
    id: iconsPage
    contentWidth: availableWidth
    clip: true

    // Let the ScrollView handle margins natively
    topPadding: 16
    bottomPadding: 32
    leftPadding: 16
    rightPadding: 16

    ColumnLayout {
        id: iconsLayout
        width: parent.width
        spacing: 32

        // Slot Envelope Calculation (Rule 7)
        // Must match AppIcon.qml exactly.
        function calculateMaxEnv(size) {
            let floorPad = Math.max(4, Math.round(size * 0.25))
            let dot = Math.max(2, Math.round(size * 0.10))
            let gap = Math.max(2, Math.round(size * 0.125) + Math.round(size * 0.15 * (1.0 - DockSettings.indicatorOffset)))
            return size + floorPad + dot + gap + floorPad
        }
        // --- SECTION 1: SIZING & GEOMETRY ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Sizing & Geometry")
                color: theme.textDim // 50% opacity Krema Accent
                font.bold: true
                font.letterSpacing: 1.1
                font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                // ICON SIZE
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Base Icon Size"); color: theme.text; font.bold: true }
                        QQC2.Label { text: iconSizeSlider.value + "px"; color: theme.textDim; font.bold: true }
                    }
                    QQC2.Slider {
                        id: iconSizeSlider; Layout.fillWidth: true; 
                        from: 24; to: 96; stepSize: 4; 
                        value: DockSettings.iconSize; 
                        onMoved: updateIconSize(value)
                        onPressedChanged: {
                            if (!pressed) {
                                updateIconSize(value)
                                DockSettings.save()
                            }
                        }

                        function updateIconSize(newVal) {
                                 let oldIconSize = DockSettings.iconSize;
                                 if (newVal === oldIconSize) return;

                                 // Rule 7 Permanent Radius Sync: Capture current ratio before updating size
                                 let radiusRatio = DockSettings.cornerRadius / oldIconSize;

                                 if (DockSettings.syncPanelThickness) {
                                     let oldMaxEnv = iconsLayout.calculateMaxEnv(oldIconSize);
                                     let ratio = DockSettings.panelHeight / oldMaxEnv;
                                     
                                     DockSettings.iconSize = newVal;
                                     
                                     let newMaxEnv = iconsLayout.calculateMaxEnv(newVal);
                                     let newThickness = Math.min(newMaxEnv, Math.round(ratio * newMaxEnv));
                                     
                                     DockSettings.panelHeight = newThickness;
                                 } else {
                                     DockSettings.iconSize = newVal;
                                     // Proactive Clamp: If icon shrinks, the max envelope might shrink below current panelHeight
                                     let currentMax = iconsLayout.calculateMaxEnv(newVal);
                                     if (DockSettings.panelHeight > currentMax) {
                                         DockSettings.panelHeight = currentMax;
                                     }
                                 }
                                 
                                 // Rule 7 Permanent Radius Sync: Apply the captured ratio to the new size
                                 let newRadius = Math.round(radiusRatio * newVal);

                                 // Proactive Clamp: Corner radius cannot exceed half of panel height (Rule 6)
                                 let maxRadius = Math.floor(DockSettings.panelHeight / 2);
                                 if (newRadius > maxRadius) {
                                     newRadius = maxRadius;
                                 }
                                 DockSettings.cornerRadius = newRadius;
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // ICON SPACING
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Icon Spacing (Gaps)"); color: theme.text; font.bold: true }
                        QQC2.Label { text: iconSpacingSlider.value + "px"; color: theme.textDim; font.bold: true }
                    }
                    QQC2.Slider {
                        id: iconSpacingSlider; Layout.fillWidth: true; 
                        from: 0; to: 16; stepSize: 1; 
                        value: DockSettings.iconSpacing; 
                        onMoved: DockSettings.iconSpacing = value
                        onPressedChanged: {
                            if (!pressed) {
                                DockSettings.save();
                                if (SettingsController) SettingsController.sync();
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // ZOOM FACTOR
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Hover Zoom Factor"); color: theme.text; font.bold: true }
                        QQC2.Label { text: zoomFactorSlider.value.toFixed(1) + "x"; color: theme.textDim; font.bold: true }
                    }
                    QQC2.Slider {
                        id: zoomFactorSlider; Layout.fillWidth: true; 
                        from: 1.0; to: 2.0; stepSize: 0.1; 
                        value: DockSettings.maxZoomFactor; 
                        onMoved: {
                            DockSettings.maxZoomFactor = value;
                        }
                        onPressedChanged: {
                            if (!pressed) {
                                DockSettings.maxZoomFactor = value;
                                DockSettings.save();
                                if (SettingsController) SettingsController.sync();
                            }
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // INDICATOR OFFSET (Global internal scale/padding)
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Indicator Offset"); color: theme.text; font.bold: true }
                        QQC2.Label { text: Math.round(indicatorOffsetSlider.value * 100) + "%"; color: theme.textDim; font.bold: true }
                    }
                    QQC2.Slider {
                        id: indicatorOffsetSlider; Layout.fillWidth: true; 
                        from: 0.5; to: 1.0; stepSize: 0.05; 
                        value: DockSettings.indicatorOffset; 
			onMoved: { 
                                 DockSettings.indicatorOffset = value;
                                 
                                 // Proactive Clamp: Changing gap changes the max envelope
                                 let currentMax = iconsLayout.calculateMaxEnv(DockSettings.iconSize);
                                 if (DockSettings.panelHeight > currentMax) {
                                     DockSettings.panelHeight = currentMax;
                                 }
                                 
                                 // Proactive Clamp: Recalculate radius bound based on new potential height
                                 let maxRadius = Math.floor(DockSettings.panelHeight / 2);
                                 if (DockSettings.cornerRadius > maxRadius) {
                                     DockSettings.cornerRadius = maxRadius;
                                 }
                             }
                        onPressedChanged: if (!pressed) DockSettings.save()
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // NORMALIZATION SWITCH
                KremaSwitch {
                    Layout.fillWidth: true
                    text: i18n("Icon Size Normalization")
                    checked: DockSettings.iconNormalization
		    onToggled: { 
                             DockSettings.iconNormalization = checked;
                             DockSettings.save();
                         }
                }
                QQC2.Label { 
                    text: i18n("Automatically adjusts icons with excess transparent padding so they appear visually consistent."); 
                    color: theme.textDim; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
            }
        }
    }
}
