import re

with open('tests/IconSandbox.qml', 'r') as f:
    c = f.read()

# Replace main content with settings page
c = re.sub(
    r'Rectangle \{\s*id: dockBg.*\}',
    r'Loader { anchors.fill: parent; source: "qrc:/qml/settings/PanelPage.qml" }',
    c, flags=re.DOTALL
)

with open('tests/IconSandbox.qml', 'w') as f:
    f.write(c)
