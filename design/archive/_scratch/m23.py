from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '04-routine-run.png').convert('RGB')).astype(int)
ink = (np.abs(im - 10).max(axis=2) > 4)
ys = np.where(ink[800:1600, 140:600].any(axis=1))[0]
runs = []
a = ys[0]; p = ys[0]
for c in ys[1:]:
    if c > p+1:
        runs.append((int(a+800), int(p+800))); a = c
    p = c
runs.append((int(a+800), int(p+800)))
print('text bands', runs)
for y0, y1 in runs:
    s = ink[y0:y1+1, 0:780]
    cols = np.where(s.any(axis=0))[0]
    print('band', y0, y1, 'x', int(cols.min()), int(cols.max()))
