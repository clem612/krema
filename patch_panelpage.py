import re

with open('src/qml/settings/PanelPage.qml', 'r') as f:
    c = f.read()

island_ui = """
                // ISLAND CORNER RADIUS
                ColumnLayout {
                    Layout.fillWidth: true
                    
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Glass Pill Corner Radius"); color: theme.text; font.bold: true }
                        QQC2.Label { text: islandRadiusSlider.value === 0 ? "Pill" : islandRadiusSlider.value + "px"; color: theme.textDim; font.bold: true }
                    }
                    QQC2.Slider {
                        id: islandRadiusSlider; Layout.fillWidth: true; from: 0; to: 32; stepSize: 1
                        value: DockSettings.islandCornerRadius
                        onMoved: { DockSettings.islandCornerRadius = value }
                        onPressedChanged: if (!pressed) DockSettings.save()
                    }
                    QQC2.Label { text: i18n("Sets the roundness of the background pill behind the icons (0 = fully rounded pill)."); color: theme.textDim; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.leftMargin: 4 }
                }

                // ISLAND MARGIN
                ColumnLayout {
                    Layout.fillWidth: true
                    
                    RowLayout {
                        QQC2.Label { Layout.fillWidth: true; text: i18n("Glass Pill Horizontal Margin"); color: theme.text; font.bold: true }
                        QQC2.Label { text: islandMarginSlider.value + "px"; color: theme.textDim; font.bold: true }
                    }
                    QQC2.Slider {
                        id: islandMarginSlider; Layout.fillWidth: true; from: 0; to: 64; stepSize: 1
                        value: DockSettings.islandMargin
                        onMoved: { DockSettings.islandMargin = value }
                        onPressedChanged: if (!pressed) DockSettings.save()
                    }
                    QQC2.Label { text: i18n("Horizontal padding extending outward from the first and last icons in an island."); color: theme.textDim; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.leftMargin: 4 }
                }
"""

replacement = """
                                    }
                                }
                            }
                        }
                    }
                }

""" + island_ui

c = re.sub(
    r'                                    \}\n                                \}\n                            \}\n                        \}\n                    \}\n                \}',
    replacement,
    c
)

with open('src/qml/settings/PanelPage.qml', 'w') as f:
    f.write(c)
