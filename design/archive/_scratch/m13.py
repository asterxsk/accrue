from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '05-new-habit-light.png').convert('RGB')).astype(int)
r, g, b = im[:, :, 0], im[:, :, 1], im[:, :, 2]
blue = (b > 150) & (r < 130)
ring = (r < 240) & (r > 140) & (np.abs(r.astype(int) - b.astype(int)) < 15) & (np.abs(r - g) < 15)

def bb(mask, y0, y1, x0, x1):
    s = mask[y0:y1, x0:x1]
    ys, xs = np.where(s)
    if len(xs) == 0:
        return None
    return (int(x0+xs.min()), int(y0+ys.min()), int(x0+xs.max()), int(y0+ys.max()))

print('plus circle', bb(blue, 1030, 1150, 580, 725))
print('minus circle', bb(ring, 1030, 1150, 62, 200))
# card bounds: scan at x=400 for border color 228
col = im[:, 400]
ys = np.where((np.abs(col - 228).max(axis=1) < 3))[0]
print('border ys near daily', [int(y) for y in ys if 990 < y < 1160])
# horizontal extent of card at y=1100
row = im[1100]
xs = np.where((np.abs(row - 228).max(axis=1) < 3))[0]
print('row1100 border xs', [int(x) for x in xs if x < 60 or x > 720])
# minus glyph
blackish = (im.max(axis=2) < 180)
print('minus glyph', bb(blackish, 1050, 1100, 90, 160))
print('plus glyph', bb(im.min(axis=2) > 200, 1050, 1100, 640, 700))
# eight and glasses
print('eight', bb(blackish, 1030, 1105, 170, 225))
print('glasses', bb((im.max(axis=2) < 200), 1055, 1105, 225, 400))
