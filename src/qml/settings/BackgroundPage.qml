// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Krema Contributors

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Window
import com.bhyoo.krema 1.0

// Import our custom UI Kit
import "../components"

QQC2.ScrollView {
    id: bgPage
    clip: true

    ColumnLayout {
	width: bgPage.availableWidth - 32 // 16px margins on each side
        x: 16
        y: 16
        spacing: 32

        // --- PILLAR 1: MATERIAL ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Base Material")
                color: "#80FFFDD0" // 50% opacity Krema Accent
                font.bold: true
                font.letterSpacing: 1.1
                font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        QQC2.Label { text: i18n("Style"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: i18n("The primary texture of the dock background."); color: "#80FFFDD0"; font.pixelSize: 12 }
                    }
		    KremaComboBox {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 220 // This stops it from ever escaping the card
                        model: [i18n("Adaptive (System Default)"), i18n("Solid Color"), i18n("Acrylic (Translucent)")]
                        currentIndex: DockSettings.backgroundStyle
                        onActivated: function(index) { DockSettings.backgroundStyle = index }
                    }
                }
            }
        }

        // --- PILLAR 2: COLOR & OPACITY ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Color & Opacity")
                color: "#80FFFDD0"
                font.bold: true
                font.letterSpacing: 1.1
                font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                KremaSwitch {
                    Layout.fillWidth: true
                    visible: DockSettings.backgroundStyle > 0
                    text: i18n("Use System Accent Color")
                    checked: DockSettings.useSystemColor
                    onToggled: DockSettings.useSystemColor = checked
                }

                Rectangle { 
                    Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A"
                    visible: DockSettings.backgroundStyle > 0 && !DockSettings.useSystemColor 
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: DockSettings.backgroundStyle > 0 && !DockSettings.useSystemColor
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Custom Tint Color"); color: "#FFFDD0"; font.bold: true }
                    Rectangle {
                        width: 48; height: 28; radius: 6
                        color: DockSettings.tintColor
                        border.color: "#333133"; border.width: 1
                        MouseArea { 
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: colorPickerPopup.open() 
                        }
                    }
                }

                Rectangle { 
                    Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A"
                    visible: DockSettings.backgroundStyle > 0 
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Background Opacity"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: Math.round(opacitySlider.value * 100) + "%"; color: "#80FFFDD0"; font.bold: true }
                    }
                    QQC2.Slider {
                        id: opacitySlider
                        Layout.fillWidth: true
                        from: 0.0; to: 1.0; stepSize: 0.05
                        value: DockSettings.backgroundOpacity
                        onMoved: DockSettings.backgroundOpacity = value
                    }
                }
            }
        }

        // --- PILLAR 3: GEOMETRY ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            QQC2.Label { 
                text: i18n("Geometry")
                color: "#80FFFDD0"
                font.bold: true
                font.letterSpacing: 1.1
                font.pixelSize: 12
                Layout.leftMargin: 8
            }
            
            KremaCard {
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Corner Radius"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: cornerSlider.value + "px"; color: "#80FFFDD0"; font.bold: true }
                    }
                    QQC2.Slider {
                        id: cornerSlider
                        Layout.fillWidth: true
                        from: 0; to: 24; stepSize: 1
                        value: DockSettings.cornerRadius
                        onMoved: DockSettings.cornerRadius = value
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Panel Thickness"); color: "#FFFDD0"; font.bold: true }
                        QQC2.Label { text: panelThicknessSlider.value + "px"; color: "#80FFFDD0"; font.bold: true }
                    }
                    QQC2.Slider {
                        id: panelThicknessSlider
                        Layout.fillWidth: true
                        from: 10; to: DockSettings.iconSize + 24; stepSize: 2
                        value: DockSettings.panelHeight
                        onMoved: {
                            DockSettings.panelHeight = value
                            DockSettings.save()
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A" }

                KremaSwitch {
                    Layout.fillWidth: true
                    text: i18n("Floating Dock")
                    checked: DockSettings.floating
                    onToggled: DockSettings.floating = checked
                }
            }
        }
    }

    // --- CUSTOM COLOR PICKER POPUP ---
    QQC2.Popup {
        id: colorPickerPopup
        parent: bgPage.Window.window ? bgPage.Window.window.contentItem : bgPage
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: Kirigami.Units.gridUnit * 18
        modal: true
        focus: true
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside

        // Krema Theming for the Popup background
        background: Rectangle {
            color: "#1C1A1C"
            radius: 12
            border.color: "#333133"
            border.width: 1
        }

        property real rVal: 0
        property real gVal: 0
        property real bVal: 0
        property color tempColor: Qt.rgba(rVal, gVal, bVal, 1.0)

        onOpened: {
            let c = Qt.color(DockSettings.tintColor);
            rVal = c.r; gVal = c.g; bVal = c.b;
        }

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: i18n("Custom Tint Color")
                font.weight: Font.Bold
                color: "#FFFDD0"
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 4
                radius: 8
                color: colorPickerPopup.tempColor
                border.color: "#333133"
                border.width: 1
            }

            GridLayout {
                columns: 2
                Layout.fillWidth: true
                QQC2.Label { text: "R:"; color: "#80FFFDD0"; font.bold: true }
                QQC2.Slider { Layout.fillWidth: true; from: 0; to: 1; value: colorPickerPopup.rVal; onMoved: colorPickerPopup.rVal = value }
                QQC2.Label { text: "G:"; color: "#80FFFDD0"; font.bold: true }
                QQC2.Slider { Layout.fillWidth: true; from: 0; to: 1; value: colorPickerPopup.gVal; onMoved: colorPickerPopup.gVal = value }
                QQC2.Label { text: "B:"; color: "#80FFFDD0"; font.bold: true }
                QQC2.Slider { Layout.fillWidth: true; from: 0; to: 1; value: colorPickerPopup.bVal; onMoved: colorPickerPopup.bVal = value }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                QQC2.Button { 
                    text: i18n("Cancel")
                    onClicked: colorPickerPopup.close() 
                }
                QQC2.Button {
                    text: i18n("Save")
                    highlighted: true
                    onClicked: {
                        DockSettings.tintColor = colorPickerPopup.tempColor.toString();
                        DockSettings.save();
                        colorPickerPopup.close();
                    }
                }
            }
        }
    }
}
