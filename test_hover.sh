#!/bin/bash
QT_LOGGING_RULES="*=true" timeout 5 ./build/dev/bin/krema > /tmp/krema_hover.log 2>&1 || true
grep -E "setHovered|Visibility|showTimer|hideTimer|evaluateVisibility" /tmp/krema_hover.log
