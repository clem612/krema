#!/bin/bash
export QT_LOGGING_RULES="krema.*=true"
export WAYLAND_DEBUG=1
timeout 5 ./build/dev/bin/krema > /tmp/krema_startup3.log 2>&1 || true
grep -E "DockView|QWaylandLayerShell|Visibility|panelRectChanged|wl_surface@|xdg_wm_base|zwlr_layer_surface|setMask" /tmp/krema_startup3.log | head -n 30
