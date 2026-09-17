#!/bin/bash
export QT_LOGGING_RULES="krema.*=true"
timeout 5 ./build/dev/bin/krema --debug-geom > /tmp/krema_geom.log 2>&1 || true
grep -E "GEOM_DOCK|GEOM_ROW" /tmp/krema_geom.log | head -n 30
