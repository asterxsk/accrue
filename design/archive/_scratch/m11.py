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

print('sel radio', bb(blue, 795, 850, 645, 715))
# dark dot inside radio
sub = im[800:845, 660:710]
dark = (sub.max(axis=2) < 40)
print('radio dot', bb(dark, 0, 45, 0, 50))
# daily target card in light
im2 = np.array(Image.open(base + '05-new-habit-light.png').convert('RGB')).astype(int)
prev = None
for y in range(985, 1135):
    c = tuple(im2[y, 390])
    if c != prev:
        print('y', y, c)
        prev = c
# horizontal scan of daily card at y=1055
for y in (1040, 1055):
    row = im2[y]
    xs = np.where(row[:, 0] < 250)[0]
    # runs
    runs = []
    s = xs[0]; p = xs[0]
    for c in xs[1:]:
        if c > p+1:
            runs.append((int(s), int(p))); s = c
        p = c
    runs.append((int(s), int(p)))
    print('row', y, runs)
