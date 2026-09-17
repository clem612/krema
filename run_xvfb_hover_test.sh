#!/bin/bash
export QT_LOGGING_RULES="krema.*=true"
sed -i 's/let triggerDepth = DockVisibility.hovered ? 64 : 2/let triggerDepth = DockVisibility.hovered ? 64 : 2; console.log("[TEST] DockVisibility.hovered is: " + typeof DockVisibility.hovered + " value: " + DockVisibility.hovered);/' src/qml/main.qml
cmake --build build/dev -j10 > /dev/null
Xvfb :99 -screen 0 1920x1080x24 &
XVFB_PID=$!
sleep 1
DISPLAY=:99 ./build/dev/bin/krema > /tmp/krema_xvfb_hover.log 2>&1 &
KREMA_PID=$!
sleep 3
# simulate mouse move to bottom edge using xdotool
DISPLAY=:99 xdotool mousemove 960 1079
sleep 2
kill -9 $KREMA_PID
kill -9 $XVFB_PID
sed -i 's/; console.log("\[TEST\] DockVisibility.hovered is: " + typeof DockVisibility.hovered + " value: " + DockVisibility.hovered);//' src/qml/main.qml
grep "\[TEST\]" /tmp/krema_xvfb_hover.log | head -n 10
