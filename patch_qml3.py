import os

with open('src/qml/settings/BackgroundPage.qml', 'r') as f:
    lines = f.readlines()

new_ui = """                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: DockSettings.backgroundStyle === 2 || DockSettings.backgroundStyle === 3
                    
                    QQC2.Label { text: i18n("Tint Color Source"); color: theme.text; font.bold: true }
                    
                    QQC2.ComboBox {
                        id: colorSourceCombo
                        Layout.fillWidth: true
                        model: [
                            i18n("Custom Solid Color"),
                            i18n("System Accent Color"),
                            i18n("Wallpaper Color (Matugen/Pywal)")
                        ]
                        currentIndex: DockSettings.useWallpaperColor ? 2 : (DockSettings.useSystemColor ? 1 : 0)
                        onActivated: {
                            if (currentIndex === 0) {
                                DockSettings.useWallpaperColor = false;
                                DockSettings.useSystemColor = false;
                            } else if (currentIndex === 1) {
                                DockSettings.useWallpaperColor = false;
                                DockSettings.useSystemColor = true;
                            } else if (currentIndex === 2) {
                                DockSettings.useWallpaperColor = true;
                                DockSettings.useSystemColor = false;
                            }
                            DockSettings.save();
                        }
                    }
                }

                Rectangle { 
                    Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A"
                    visible: DockSettings.backgroundStyle === 2 || DockSettings.backgroundStyle === 3
                }
"""

# Replace lines 209 to 221
# Python lines are 0-indexed, so 208 to 221
del lines[208:221]
lines.insert(208, new_ui)

with open('src/qml/settings/BackgroundPage.qml', 'w') as f:
    f.writelines(lines)

with open('src/qml/settings/BackgroundPage.qml', 'r') as f:
    content = f.read()
    
# Now fix the RowLayout visible condition
old_visible = 'visible: !DockSettings.useSystemColor && (DockSettings.backgroundStyle === 2 || DockSettings.backgroundStyle === 3)'
new_visible = 'visible: colorSourceCombo.currentIndex === 0 && (DockSettings.backgroundStyle === 2 || DockSettings.backgroundStyle === 3)'
content = content.replace(old_visible, new_visible)

with open('src/qml/settings/BackgroundPage.qml', 'w') as f:
    f.write(content)
