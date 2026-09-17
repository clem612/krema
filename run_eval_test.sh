#!/bin/bash
export QT_LOGGING_RULES="krema.*=true"
sed -i 's/void DockVisibilityController::evaluateVisibility()/void DockVisibilityController::evaluateVisibility()\n{\n    qDebug() << "[VIS] evaluateVisibility called! m_hovered=" << m_hovered;\n/' src/shell/dockvisibilitycontroller.cpp
cmake --build build/dev -j10
timeout 6 ./build/dev/bin/krema --debug-all > /tmp/krema_eval.log 2>&1 || true
grep "VIS" /tmp/krema_eval.log
