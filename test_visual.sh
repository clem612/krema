#!/bin/bash
export XDG_RUNTIME_DIR=/tmp/krema_xdg
mkdir -p $XDG_RUNTIME_DIR

# Start virtual kwin_wayland
kwin_wayland --wayland-display wayland-99 --virtuals 1 --width 1920 --height 1080 &
KWIN_PID=$!
sleep 2

export WAYLAND_DISPLAY=wayland-99

# Start krema in AutoHide mode but we will force it to show via DBus or Timer?
# Let's just create a temporary patch to main.qml that forces the mouse hover
cat << 'PATCH_EOF' > /tmp/sim_hover.patch
--- src/qml/main.qml
+++ src/qml/main.qml
@@ -100,6 +100,18 @@
         readonly property bool _debugConfig: KremaDebug.configEnabled
         readonly property bool _debugGeom: KremaDebug.geomEnabled
 
+        Timer {
+            running: true
+            interval: 2000
+            onTriggered: {
+                console.log("[TEST] Simulating hover to show dock!")
+                // simulate hover inside the 64px region
+                DockVisibility.setHovered(true)
+                // We also need dockMouseArea.containsMouse = true so it doesn't instantly hide on mouseExit?
+                // No, mouseExit only triggers on actual Wayland events.
+            }
+        }
+
         // ----------------------------------------------------
         // Wayland Input Geometry / Hit-Testing (Bug #40)
         // ----------------------------------------------------
PATCH_EOF
patch -p0 < /tmp/sim_hover.patch

cmake --build build/dev -j10 > /dev/null
./build/dev/bin/krema --debug-all > /tmp/krema_visual.log 2>&1 &
KREMA_PID=$!
sleep 4

# Take a screenshot
grim /home/clem/.gemini/antigravity/brain/86357bb1-438f-4264-aef3-b2a75747513f/dock_visible.png

kill -9 $KREMA_PID
kill -9 $KWIN_PID
patch -p0 -R < /tmp/sim_hover.patch
