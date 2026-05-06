// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import com.bhyoo.krema 1.0
import "../components"

QQC2.ScrollView {
    id: behaviorPage
    contentWidth: availableWidth
    clip: true
    topPadding: 16
    bottomPadding: 32
    leftPadding: 16
    rightPadding: 16

    ColumnLayout {
        width: parent.width
        spacing: 32

        // --- THE ONLY REMAINING SECTION: ATTENTION & BADGES ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("App Attention & Badges")
                color: "#80FFFDD0"
                font.bold: true; font.letterSpacing: 1.1; font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                // ATTENTION ANIMATION
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        QQC2.Label { text: i18n("Attention Animation"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: i18n("Visual feedback when an app needs you."); color: "#80FFFDD0"; font.pixelSize: 12 }
                    }
                    KremaComboBox {
                        Layout.preferredWidth: 140
                        model: [i18n("None"), i18n("Bounce"), i18n("Glow")]
                        currentIndex: DockSettings.attentionAnimation
                        onActivated: function(index) { DockSettings.attentionAnimation = index }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // ATTENTION DURATION
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Animation Duration"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { 
                            text: attentionDurationSlider.value === 0 ? i18n("Infinite") : attentionDurationSlider.value + "s"
                            color: "#80FFFDD0"; font.bold: true 
                        }
                    }
                    QQC2.Slider {
                        id: attentionDurationSlider; Layout.fillWidth: true; 
                        from: 0; to: 60; stepSize: 1; 
                        value: DockSettings.attentionAnimationDuration; 
                        onMoved: DockSettings.attentionAnimationDuration = value 
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                // BADGE DISPLAY
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        QQC2.Label { text: i18n("Badge Display"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: i18n("Notification count styles."); color: "#80FFFDD0"; font.pixelSize: 12 }
                    }
                    KremaComboBox {
                        Layout.preferredWidth: 140
                        model: [i18n("None"), i18n("Dot"), i18n("Number")]
                        currentIndex: DockSettings.badgeDisplayMode
                        onActivated: function(index) { DockSettings.badgeDisplayMode = index }
                    }
                }
            }
        }
    }
}
