import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.bhyoo.krema 1.0

FormCard.FormCardPage {
    title: i18n("Icons")

    FormCard.FormHeader { title: i18n("Icon Layout") }

    FormCard.FormCard {
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

        FormCard.AbstractFormDelegate {
            contentItem: ColumnLayout {
                RowLayout {
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Zoom factor") }
                    QQC2.Label { text: DockSettings.maxZoomFactor.toFixed(1) + "x"; opacity: 0.6 }
                }
                QQC2.Slider {
                    Layout.fillWidth: true
                    from: 1.0; to: 2.0; stepSize: 0.1
                    value: DockSettings.maxZoomFactor
                    onMoved: DockSettings.maxZoomFactor = value
                }
            }
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormSwitchDelegate {
            text: i18n("Icon size normalization")
            description: i18n("Automatically adjust icons with excess padding to appear visually consistent")
            checked: DockSettings.iconNormalization
            onToggled: DockSettings.iconNormalization = checked
        }

        FormCard.FormDelegateSeparator {}

        FormCard.AbstractFormDelegate {
            contentItem: ColumnLayout {
                RowLayout {
                    QQC2.Label { Layout.fillWidth: true; text: i18n("Icon scale") }
                    QQC2.Label { text: Math.round(DockSettings.iconScale * 100) + "%"; opacity: 0.6 }
                }
                QQC2.Slider {
                    Layout.fillWidth: true
                    from: 0.5; to: 1.0; stepSize: 0.05
                    value: DockSettings.iconScale
                    onMoved: DockSettings.iconScale = value
                }
            }
        }
    }

    FormCard.FormHeader { title: i18n("Behavior & Notifications") }

    FormCard.FormCard {
        FormCard.FormComboBoxDelegate {
            text: i18n("Attention animation")
            description: i18n("Animation when an app demands attention")
            model: [i18n("None"), i18n("Bounce"), i18n("Glow")]
            currentIndex: DockSettings.attentionAnimation
            onActivated: function(index) { DockSettings.attentionAnimation = index }
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormSpinBoxDelegate {
            label: i18n("Attention duration (seconds, 0 = infinite)")
            from: 0; to: 60
            value: DockSettings.attentionAnimationDuration
            onValueChanged: DockSettings.attentionAnimationDuration = value
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormComboBoxDelegate {
            text: i18n("Badge display")
            description: i18n("How notification badges appear on dock icons")
            model: [i18n("None"), i18n("Dot"), i18n("Number")]
            currentIndex: DockSettings.badgeDisplayMode
            onActivated: function(index) { DockSettings.badgeDisplayMode = index }
        }
    }
}
