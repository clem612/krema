from PIL import Image
img = Image.open('/home/clem/.gemini/antigravity/brain/86357bb1-438f-4264-aef3-b2a75747513f/.user_uploaded/media_1789494704175.png')
img = img.convert('RGBA')
w, h = img.size
for y in range(0, h, 4):
    for x in range(0, w, 4):
        p = img.getpixel((x, y))
        if p[3] > 0 and (p[0] > 20 or p[1] > 20 or p[2] > 20):
            print('#', end='')
        else:
            print('.', end='')
    print()
