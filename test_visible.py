import subprocess
import time
import os

os.environ["XDG_RUNTIME_DIR"] = "/tmp/krema_xdg"
os.system("mkdir -p /tmp/krema_xdg")
os.environ["WAYLAND_DISPLAY"] = "wayland-0"

print("Starting kwin_wayland...")
kwin = subprocess.Popen(["kwin_wayland", "--virtual", "--width", "1920", "--height", "1080"])
time.sleep(3)

print("Starting krema...")
krema = subprocess.Popen(["./build/dev/bin/krema", "--debug-all"], stdout=open("/tmp/krema_visible.log", "w"), stderr=subprocess.STDOUT)
time.sleep(3)

print("Taking screenshot...")
os.system("grim /home/clem/.gemini/antigravity/brain/86357bb1-438f-4264-aef3-b2a75747513f/dock_always_visible.png")

print("Cleaning up...")
krema.terminate()
kwin.terminate()
print("Done!")
