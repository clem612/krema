#!/bin/bash
export QT_LOGGING_RULES="krema.*=true"
cmake --build build/dev -j10 > /dev/null
./build/dev/bin/krema --debug-all > /tmp/krema_syntax.log 2>&1 &
KREMA_PID=$!
sleep 2
kill -9 $KREMA_PID
grep "QML" /tmp/krema_syntax.log | head -n 20
grep "error" /tmp/krema_syntax.log
