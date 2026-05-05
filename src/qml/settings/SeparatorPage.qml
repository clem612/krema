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
    id: separatorPage
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

        // --- SECTION 1: SEPARATOR STYLE ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Appearance")
                color: "#80FFFDD0" // 50% opacity Krema Accent
                font.bold: true
                font.letterSpacing: 1.1
                font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                // STYLE DROPDOWN
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        QQC2.Label { text: i18n("Style"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: i18n("The visual design of the divider."); color: "#80FFFDD0"; font.pixelSize: 12 }
                    }
                    KremaComboBox {
                        Layout.preferredWidth: 180
                        Layout.maximumWidth: 180
                        model: [i18n("Classic Line"), i18n("Blueprint Dots")]
                        currentIndex: DockSettings.separatorStyle
                        onActivated: function(index) { DockSettings.separatorStyle = index }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // OPACITY SLIDER
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Opacity"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: Math.round(sepOpacitySlider.value * 100) + "%"; color: "#80FFFDD0"; font.bold: true }
                    }
                    QQC2.Slider {
                        id: sepOpacitySlider
                        Layout.fillWidth: true
                        from: 0.0; to: 1.0; stepSize: 0.05
                        value: DockSettings.separatorOpacity
                        onMoved: DockSettings.separatorOpacity = value
                    }
                }
            }
        }
    }
}
