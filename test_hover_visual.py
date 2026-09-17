import subprocess
import time
import os

os.environ["XDG_RUNTIME_DIR"] = "/tmp/krema_xdg"
os.system("mkdir -p /tmp/krema_xdg")
os.environ["WAYLAND_DISPLAY"] = "wayland-99"

print("Starting kwin_wayland...")
kwin = subprocess.Popen(["kwin_wayland", "--virtual", "--wayland-display", "wayland-99", "--width", "1920", "--height", "1080"])
time.sleep(3)

print("Patching main.qml for testing...")
patch = """
--- src/qml/main.qml
+++ src/qml/main.qml
@@ -107,6 +107,14 @@
         readonly property bool _debugConfig: KremaDebug.configEnabled
         readonly property bool _debugGeom: KremaDebug.geomEnabled
 
+        Timer {
+            running: true
+            interval: 3000
+            onTriggered: {
+                console.log("[TEST] Timer triggered! Calling setHovered(true)")
+                if (DockVisibility) DockVisibility.setHovered(true)
+            }
+        }
+
         // ----------------------------------------------------
         // Wayland Input Geometry / Hit-Testing (Bug #40)
         // ----------------------------------------------------
"""
with open("/tmp/sim.patch", "w") as f:
    f.write(patch)
os.system("patch -p0 < /tmp/sim.patch")

print("Rebuilding krema...")
os.system("cmake --build build/dev -j10 > /dev/null")

print("Starting krema...")
krema = subprocess.Popen(["./build/dev/bin/krema", "--debug-all"], stdout=open("/tmp/krema_test2.log", "w"), stderr=subprocess.STDOUT)

# Wait 2 seconds, take first screenshot (Hidden)
time.sleep(2)
print("Taking screenshot 1 (Hidden)...")
os.system("grim /home/clem/.gemini/antigravity/brain/86357bb1-438f-4264-aef3-b2a75747513f/dock_hidden.png")

# Wait 3 more seconds for timer to fire and animation to finish
time.sleep(3)
print("Taking screenshot 2 (Visible)...")
os.system("grim /home/clem/.gemini/antigravity/brain/86357bb1-438f-4264-aef3-b2a75747513f/dock_visible.png")

print("Cleaning up...")
krema.terminate()
kwin.terminate()
os.system("patch -p0 -R < /tmp/sim.patch")

print("Done!")
