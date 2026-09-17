import os

with open('src/qml/settings/BehaviorPage.qml', 'r') as f:
    content = f.read()

widget_section = """
       // --- SECTION 2: WIDGETS ---
       ColumnLayout {
           Layout.fillWidth: true
           spacing: 8
           
           QQC2.Label { 
               text: i18n("Widgets & Integrations")
               color: theme.textDim
               font.bold: true; font.letterSpacing: 1.1; font.pixelSize: 12
               Layout.leftMargin: 8
           }
           
           KremaCard {
               ColumnLayout {
                   Layout.fillWidth: true
                   spacing: 12

                   KremaSwitch {
                       Layout.fillWidth: true
                       text: i18n("Enable Media Chip")
                       checked: DockSettings.showMediaChip
                       onToggled: {
                           DockSettings.showMediaChip = checked;
                           DockSettings.save();
                       }
                   }
                   
                   QQC2.Label { 
                       text: i18n("Embeds an MPRIS-compatible widget directly into the dock to display and control active media players (Spotify, Firefox, VLC). Works across all shells natively.")
                       color: theme.textDim
                       font.pixelSize: 11
                       wrapMode: Text.WordWrap
                       Layout.fillWidth: true
                   }
               }
           }
       }
"""

idx = content.rfind('   }\n}')
content = content[:idx] + widget_section + content[idx:]

with open('src/qml/settings/BehaviorPage.qml', 'w') as f:
    f.write(content)
