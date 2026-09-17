#!/bin/bash
export QT_LOGGING_RULES="krema.*=true"
timeout 5 ./build/dev/bin/krema > /tmp/krema_startup2.log 2>&1 || true
grep -iE "visibility|show|hide|visible|layer|surface" /tmp/krema_startup2.log
