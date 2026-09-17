#!/bin/bash
export QT_LOGGING_RULES="krema.*=true"
cmake --build build/dev -j10 > /dev/null
./build/dev/bin/krema --debug-all > /tmp/krema_hover.log 2>&1 &
KREMA_PID=$!
sleep 2

# Wait for it to start, then we can see if it prints the hover logs.
# Actually we can't easily simulate a hover event from bash if we have no xdotool/wayland injector.
kill -9 $KREMA_PID
