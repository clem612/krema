import subprocess
import time
import os

os.environ["XDG_RUNTIME_DIR"] = "/tmp/krema_xdg"
os.system("mkdir -p /tmp/krema_xdg")
os.environ["WAYLAND_DISPLAY"] = "wayland-99"

print("Starting kwin_wayland...")
kwin = subprocess.Popen(["kwin_wayland", "--virtual", "--wayland-display", "wayland-99", "--width", "1920", "--height", "1080"])
time.sleep(3)

print("Starting krema...")
krema = subprocess.Popen(["./build/dev/bin/krema", "--debug-all"], stdout=open("/tmp/krema_test2.log", "w"), stderr=subprocess.STDOUT)
time.sleep(2)

print("Triggering setHovered via DBus? No we don't have DBus for it.")
# Instead, since we want to know if it renders, let's just see if krema logs anything when we change VisibilityMode to 0 (AlwaysVisible).
# Wait, we want to know why AutoHide hover doesn't show.
print("Cleaning up...")
krema.terminate()
kwin.terminate()
