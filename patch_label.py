import re

with open('src/qml/settings/PanelPage.qml', 'r') as f:
    c = f.read()

# The last RowLayout for Corner Radius is for the panel's Corner Radius.
# It should bind to radiusSlider, not islandRadiusSlider.

c = c.replace(
    'QQC2.Label { Layout.fillWidth: true; text: i18n("Corner Radius"); color: theme.text; font.bold: true }\n                        QQC2.Label { text: islandRadiusSlider.value + "px"; color: theme.textDim; font.bold: true }',
    'QQC2.Label { Layout.fillWidth: true; text: i18n("Corner Radius"); color: theme.text; font.bold: true }\n                        QQC2.Label { text: radiusSlider.value + "px"; color: theme.textDim; font.bold: true }'
)

with open('src/qml/settings/PanelPage.qml', 'w') as f:
    f.write(c)
