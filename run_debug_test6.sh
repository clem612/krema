#!/bin/bash
export QT_LOGGING_RULES="krema.*=true"
export WAYLAND_DEBUG=1
timeout 2 ./build/dev/bin/krema > /tmp/krema_startup6.log 2>&1 || true
grep -A 2 -B 2 -iE "QQuickView|visible" /tmp/krema_startup6.log
