from PyQt6.QtQml import QQmlComponent, QQmlEngine
from PyQt6.QtWidgets import QApplication
import sys
app = QApplication(sys.argv)
engine = QQmlEngine()
comp = QQmlComponent(engine, "src/qml/settings/PanelPage.qml")
if comp.isError():
    for err in comp.errors():
        print(err.toString())
