from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
for f, bg in [('04-routine-run-light', 252)]:
    im = np.array(Image.open(base + f + '.png').convert('RGB')).astype(int)
    ink = (np.abs(im - bg).max(axis=2) > 6)
    ys = np.where(ink[900:1100, 140:600].any(axis=1))[0]
    runs = []
    a = ys[0]; p = ys[0]
    for c in ys[1:]:
        if c > p+1:
            runs.append((int(a+900), int(p+900))); a = c
        p = c
    runs.append((int(a+900), int(p+900)))
    print(f, runs)
    for y0, y1 in runs:
        xs = np.where(ink[y0:y1+1, 0:780].any(axis=0))[0]
        print(' band', y0, y1, int(xs.min()), int(xs.max()))
