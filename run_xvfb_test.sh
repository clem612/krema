#!/bin/bash
export QT_LOGGING_RULES="krema.*=true"
Xvfb :99 -screen 0 1920x1080x24 &
XVFB_PID=$!
sleep 1
DISPLAY=:99 ./build/dev/bin/krema --debug-all > /tmp/krema_xvfb.log 2>&1 &
KREMA_PID=$!
sleep 3
kill -9 $KREMA_PID
kill -9 $XVFB_PID
grep "GEOM_DOCK" /tmp/krema_xvfb.log
grep "QML" /tmp/krema_xvfb.log
