import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.bhyoo.krema 1.0

FormCard.FormCardPage {
    title: i18n("Behavior")

    // --- Expansion States ---
    property bool visibilityExpanded: true
    property bool monitorExpanded: false
    property bool desktopsExpanded: false

    // --- SECTION 1: VISIBILITY ---
    FormCard.FormHeader {
        title: i18n("Visibility")
        trailing: Kirigami.Icon {
            source: visibilityExpanded ? "arrow-up" : "arrow-down"
            implicitWidth: Kirigami.Units.gridUnit
            implicitHeight: Kirigami.Units.gridUnit
        }
        MouseArea { anchors.fill: parent; onClicked: visibilityExpanded = !visibilityExpanded }
    }

    FormCard.FormCard {
        visible: visibilityExpanded
        FormCard.FormComboBoxDelegate {
            text: i18n("Visibility mode")
            displayMode: FormCard.FormComboBoxDelegate.Dialog
            model: [i18n("Always visible"), i18n("Auto hide"), i18n("Dodge windows")]
            currentIndex: DockSettings.visibilityMode
            onActivated: function(index) { DockSettings.visibilityMode = index }
        }
        FormCard.FormDelegateSeparator { visible: DockSettings.visibilityMode === 0 }
        FormCard.FormSwitchDelegate {
            text: i18n("Reserve screen space")
            checked: DockSettings.reserveSpace
            onCheckedChanged: DockSettings.reserveSpace = checked
            visible: DockSettings.visibilityMode === 0
        }
        FormCard.FormDelegateSeparator { visible: DockSettings.visibilityMode === 2 }
        FormCard.FormSwitchDelegate {
            text: i18n("Only dodge active window")
            checked: DockSettings.dodgeActiveOnly
            onCheckedChanged: DockSettings.dodgeActiveOnly = checked
            visible: DockSettings.visibilityMode === 2
        }
        FormCard.FormDelegateSeparator {}
        FormCard.FormComboBoxDelegate {
            text: i18n("Screen edge")
            displayMode: FormCard.FormComboBoxDelegate.Dialog
            model: [i18n("Top"), i18n("Bottom"), i18n("Left"), i18n("Right")]
            currentIndex: DockSettings.edge
            onActivated: function(index) { DockSettings.edge = index }
        }
    }

    // --- SECTION 2: MULTI-MONITOR ---
    FormCard.FormHeader {
        title: i18n("Multi-Monitor")
        trailing: Kirigami.Icon {
            source: monitorExpanded ? "arrow-up" : "arrow-down"
            implicitWidth: Kirigami.Units.gridUnit
            implicitHeight: Kirigami.Units.gridUnit
        }
        MouseArea { anchors.fill: parent; onClicked: monitorExpanded = !monitorExpanded }
    }

    FormCard.FormCard {
        visible: monitorExpanded
        FormCard.FormComboBoxDelegate {
            text: i18n("Monitor mode")
            model: [i18n("Primary monitor only"), i18n("All monitors"), i18n("Follow active screen")]
            currentIndex: DockSettings.monitorMode
            onActivated: function(index) { DockSettings.monitorMode = index }
        }
    }

    // --- SECTION 3: VIRTUAL DESKTOPS ---
    FormCard.FormHeader {
        title: i18n("Virtual Desktops")
        trailing: Kirigami.Icon {
            source: desktopsExpanded ? "arrow-up" : "arrow-down"
            implicitWidth: Kirigami.Units.gridUnit
            implicitHeight: Kirigami.Units.gridUnit
        }
        MouseArea { anchors.fill: parent; onClicked: desktopsExpanded = !desktopsExpanded }
    }

    FormCard.FormCard {
        visible: desktopsExpanded
        FormCard.FormComboBoxDelegate {
            text: i18n("Display mode")
            model: [i18n("Show all windows"), i18n("Dim other desktops"), i18n("Current desktop only")]
            currentIndex: DockSettings.virtualDesktopMode
            onActivated: function(index) { DockSettings.virtualDesktopMode = index }
        }
    }
}
