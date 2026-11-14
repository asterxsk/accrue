from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '01-today.png').convert('RGB')).astype(int)
ink = (np.abs(im - 10).max(axis=2) > 4)
ys = np.where(ink[1000:1130, 40:300].any(axis=1))[0]
runs = []
a = ys[0]; p = ys[0]
for c in ys[1:]:
    if c > p+1:
        runs.append((int(a+1000), int(p+1000))); a = c
    p = c
runs.append((int(a+1000), int(p+1000)))
print('bands', runs)
for y0, y1 in runs:
    xs = np.where(ink[y0:y1+1, 0:780].any(axis=0))[0]
    print(y0, y1, int(xs.min()), int(xs.max()))
