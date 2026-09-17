import urllib.request
req = urllib.request.Request('https://raw.githubusercontent.com/hyprwm/Hyprland/main/src/desktop/Window.cpp', headers={'User-Agent': 'Mozilla/5.0'})
print(urllib.request.urlopen(req).read().decode('utf-8')[:3000])
