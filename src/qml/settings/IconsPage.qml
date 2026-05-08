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
        // ONLY fill the width, let the height stretch natively
        width: parent.width
        spacing: 32

        // --- SECTION 1: SIZING & GEOMETRY ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Sizing & Geometry")
                color: "#80FFFDD0" // 50% opacity Krema Accent
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
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Base Icon Size"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: iconSizeSlider.value + "px"; color: "#80FFFDD0"; font.bold: true }
                    }
                    QQC2.Slider {
                        id: iconSizeSlider; Layout.fillWidth: true; 
                        from: 24; to: 96; stepSize: 4; 
                        value: DockSettings.iconSize; 
			onMoved: { 
                                 DockSettings.iconSize = value;
                                 DockSettings.save();
                             }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // ICON SPACING
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Icon Spacing (Gaps)"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: iconSpacingSlider.value + "px"; color: "#80FFFDD0"; font.bold: true }
                    }
                    QQC2.Slider {
                        id: iconSpacingSlider; Layout.fillWidth: true; 
                        from: 0; to: 16; stepSize: 1; 
                        value: DockSettings.iconSpacing; 
			onMoved: { 
                                 DockSettings.iconSpacing = value;
                                 DockSettings.save();
                             }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // ZOOM FACTOR
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Hover Zoom Factor"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: zoomFactorSlider.value.toFixed(1) + "x"; color: "#80FFFDD0"; font.bold: true }
                    }
                    QQC2.Slider {
                        id: zoomFactorSlider; Layout.fillWidth: true; 
                        from: 1.0; to: 2.0; stepSize: 0.1; 
                        value: DockSettings.maxZoomFactor; 
			onMoved: { 
                                 DockSettings.maxZoomFactor = value;
                                 DockSettings.save();
                             }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // INDICATOR OFFSET (Global internal scale/padding)
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Indicator Offset"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: Math.round(indicatorOffsetSlider.value * 100) + "%"; color: "#80FFFDD0"; font.bold: true }
                    }
                    QQC2.Slider {
                        id: indicatorOffsetSlider; Layout.fillWidth: true; 
                        from: 0.5; to: 1.0; stepSize: 0.05; 
                        value: DockSettings.indicatorOffset; 
			onMoved: { 
                                 DockSettings.indicatorOffset = value;
                                 DockSettings.save();
                             }
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
                    color: "#80FFFDD0"; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.topMargin: -8
                }
            }
        }
    }
}
