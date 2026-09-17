#!/bin/bash
export QT_LOGGING_RULES="krema.*=true"
timeout 5 ./build/dev/bin/krema --debug-geom > /tmp/krema_edge.log 2>&1 || true
grep -A 5 -B 5 "GEOM" /tmp/krema_edge.log
