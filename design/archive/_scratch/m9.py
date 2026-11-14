from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '05-new-habit.png').convert('RGB')).astype(int)
r, g, b = im[:, :, 0], im[:, :, 1], im[:, :, 2]
blue = (b > 150) & (r < 130)
def bb(mask, y0, y1, x0, x1):
    s = mask[y0:y1, x0:x1]
    ys, xs = np.where(s)
    if len(xs) == 0:
        return None
    return (int(x0+xs.min()), int(y0+ys.min()), int(x0+xs.max()), int(y0+ys.max()))
print('selected border', bb(blue, 740, 900, 20, 760))
# horizontal scan at card mid y=815
for y in (760, 762, 764, 766, 770, 815, 869, 871, 875):
    xs = np.where(blue[y])[0]
    print('y', y, (xs.min(), xs.max()) if len(xs) else None, len(xs))
# radio selected
print('radio full', bb(blue, 790, 850, 640, 725))
# option card bounds: card bg 17 on page bg 10
card = (np.abs(im - np.array([17, 17, 17])).max(axis=2) <= 1)
for y in (550, 680, 815):
    xs = np.where(card[y, 20:760])[0]
    print('card row', y, xs.min()+20, xs.max()+20)
# vertical scan x=390 for card bands
col = card[:, 390]
ys = np.where(col)[0]
runs = []
s = ys[0]; p = ys[0]
for c in ys[1:]:
    if c > p+1:
        runs.append((s, p)); s = c
    p = c
runs.append((s, p))
print('card bands x=390', runs)
# selected card: scan for dark fill inside border
notblue = ~blue
