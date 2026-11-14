from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '05-new-habit-light.png').convert('RGB')).astype(int)
r, g, b = im[:, :, 0], im[:, :, 1], im[:, :, 2]
blue = (b > 150) & (r < 130)
grayish = (r < 235) & (r > 150) & (np.abs(r - b) < 12)

def bb(mask, y0, y1, x0, x1):
    s = mask[y0:y1, x0:x1]
    ys, xs = np.where(s)
    if len(xs) == 0:
        return None
    return (int(x0+xs.min()), int(y0+ys.min()), int(x0+xs.max()), int(y0+ys.max()))

print('plus circle', bb(blue, 1025, 1115, 560, 730))
print('minus circle', bb(grayish, 1025, 1115, 55, 220))
print('eight', bb(im.max(axis=2) < 120, 1030, 1100, 160, 230))
print('glasses text', bb(grayish, 1060, 1110, 200, 500))
# card bounds
prev = None
for y in range(1080, 1130):
    c = tuple(im[y, 390])
    if c != prev:
        print('y', y, c); prev = c
# reminder row
print('everyday', bb(im.max(axis=2) < 200, 1230, 1280, 400, 730))
print('800am', bb(im.max(axis=2) < 120, 1225, 1280, 60, 400))
# minus glyph
print('minus glyph', bb(im.max(axis=2) < 200, 1050, 1085, 90, 140))
# selected radio
print('radio selected', bb(blue, 800, 880, 640, 730))
