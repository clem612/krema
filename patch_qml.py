import os

with open('src/qml/settings/BackgroundPage.qml', 'r') as f:
    content = f.read()

insert = """
                KremaSwitch {
                    Layout.fillWidth: true
                    text: i18n("Use Wallpaper Color (Pywal/Matugen)")
                    checked: DockSettings.useWallpaperColor
                    visible: DockSettings.backgroundStyle === 2 || DockSettings.backgroundStyle === 3
                    onToggled: { DockSettings.useWallpaperColor = checked; DockSettings.save(); }
                }

                Rectangle { 
                    Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2A282A"
                    visible: DockSettings.backgroundStyle === 2 || DockSettings.backgroundStyle === 3
                }
"""

if "Use Wallpaper Color" not in content:
    idx = content.find('KremaSwitch {\n                    Layout.fillWidth: true\n                    text: i18n("Use System Accent Color")')
    if idx != -1:
        content = content[:idx] + insert + content[idx:]

# Update the visible property for Custom Tint Color
if "visible: !DockSettings.useSystemColor && (DockSettings.backgroundStyle" in content:
    content = content.replace("visible: !DockSettings.useSystemColor && (DockSettings.backgroundStyle", "visible: !DockSettings.useSystemColor && !DockSettings.useWallpaperColor && (DockSettings.backgroundStyle")

with open('src/qml/settings/BackgroundPage.qml', 'w') as f:
    f.write(content)
