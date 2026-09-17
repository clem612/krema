#!/bin/bash
timeout 2 ./build/dev/bin/krema > /tmp/krema_vis.log 2>&1 || true
grep "DEBUG_VIS" /tmp/krema_vis.log | head -n 10
