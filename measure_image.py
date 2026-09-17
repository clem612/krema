from PIL import Image

img = Image.open('/home/clem/.gemini/antigravity/brain/86357bb1-438f-4264-aef3-b2a75747513f/.user_uploaded/media_1789494704175.png').convert('L')
pixels = img.load()
w, h = img.size

import statistics
col_vars = []
for x in range(w):
    col = [pixels[x, y] for y in range(h)]
    mean = sum(col) / h
    var = sum((p - mean)**2 for p in col) / h
    col_vars.append(var)

print("Content ranges:")
start = None
for i, v in enumerate(col_vars):
    if v > 50 and start is None:
        start = i
    elif v <= 50 and start is not None:
        print(f"Content from {start} to {i}")
        start = None
if start is not None:
    print(f"Content from {start} to {w}")
