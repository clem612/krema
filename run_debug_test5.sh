#!/bin/bash
export QT_LOGGING_RULES="krema.*=true"
timeout 5 ./build/dev/bin/krema > /tmp/krema_startup5.log 2>&1 || true
grep -A 2 -B 2 -iE "visual|visible|opacity|color" /tmp/krema_startup5.log
