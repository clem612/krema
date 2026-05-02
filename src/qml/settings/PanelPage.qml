import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.bhyoo.krema 1.0

FormCard.FormCardPage {
    title: i18n("Panel Settings")

    // --- Expansion States ---
    property bool iconsExpanded: true
    property bool separatorExpanded: false
    property bool panelExpanded: false

    // ==========================================
    // SECTION 1: ICONS
    // ==========================================
    FormCard.FormHeader {
        title: i18n("Icons")
        trailing: Kirigami.Icon {
            source: iconsExpanded ? "arrow-up" : "arrow-down"
            implicitWidth: Kirigami.Units.gridUnit
            implicitHeight: Kirigami.Units.gridUnit
        }
        MouseArea { anchors.fill: parent; onClicked: iconsExpanded = !iconsExpanded }
    }

    FormCard.FormCard {
        visible: iconsExpanded
        FormCard.FormSpinBoxDelegate {
            label: i18n("Icon size")
            from: 24; to: 96; stepSize: 4
            value: DockSettings.iconSize
            onValueChanged: DockSettings.iconSize = value
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormSpinBoxDelegate {
            label: i18n("Icon spacing")
            from: 0; to: 16
            value: DockSettings.iconSpacing
            onValueChanged: DockSettings.iconSpacing = value
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormSwitchDelegate {
            text: i18n("Icon size normalization")
            checked: DockSettings.iconNormalization
            onToggled: DockSettings.iconNormalization = checked
        }
    }

    // ==========================================
    // SECTION 2: SEPARATOR
    // ==========================================
    FormCard.FormHeader {
        title: i18n("Separator")
        trailing: Kirigami.Icon {
            source: separatorExpanded ? "arrow-up" : "arrow-down"
            implicitWidth: Kirigami.Units.gridUnit
            implicitHeight: Kirigami.Units.gridUnit
        }
        MouseArea { anchors.fill: parent; onClicked: separatorExpanded = !separatorExpanded }
    }

    FormCard.FormCard {
        visible: separatorExpanded
        FormCard.FormComboBoxDelegate {
            text: i18n("Style")
            model: [i18n("Classic Line"), i18n("Blueprint Dots")]
            currentIndex: DockSettings.separatorStyle
            onActivated: function(index) { DockSettings.separatorStyle = index }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.AbstractFormDelegate {
            contentItem: ColumnLayout {
                RowLayout {
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Opacity") }
                    QQC2.Label { text: Math.round(sepOpacitySlider.value * 100) + "%" }
                }
                QQC2.Slider {
                    id: sepOpacitySlider; Layout.fillWidth: true
                    from: 0.0; to: 1.0; value: DockSettings.separatorOpacity
                    onMoved: DockSettings.separatorOpacity = value
                }
            }
        }
    }

    // ==========================================
    // SECTION 3: PANEL
    // ==========================================
    FormCard.FormHeader {
        title: i18n("Panel")
        trailing: Kirigami.Icon {
            source: panelExpanded ? "arrow-up" : "arrow-down"
            implicitWidth: Kirigami.Units.gridUnit
            implicitHeight: Kirigami.Units.gridUnit
        }
        MouseArea { anchors.fill: parent; onClicked: panelExpanded = !panelExpanded }
    }

    FormCard.FormCard {
        visible: panelExpanded
        FormCard.FormSpinBoxDelegate {
            label: i18n("Panel thickness")
	    from: 10; to: DockSettings.iconSize + 24; stepSize: 2
            value: DockSettings.panelHeight
            onValueChanged: {
                DockSettings.panelHeight = value
                DockSettings.save()
            }
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormSpinBoxDelegate {
            label: i18n("Corner radius")
            from: 0; to: 24
            value: DockSettings.cornerRadius
            onValueChanged: DockSettings.cornerRadius = value
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormSwitchDelegate {
            text: i18n("Floating")
            checked: DockSettings.floating
            onToggled: DockSettings.floating = checked
        }
    }
}
