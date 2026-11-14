from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '01-today.png').convert('RGB')).astype(int)
card = (np.abs(im - np.array([17, 17, 17])).max(axis=2) <= 1)
ys = np.where(card[:, 390])[0]
runs = []
a = ys[0]; p = ys[0]
for c in ys[1:]:
    if c > p+1:
        runs.append((int(a), int(p))); a = c
    p = c
runs.append((int(a), int(p)))
print('card bands', runs)
# routines section label bbox
ink = (np.abs(im - 10).max(axis=2) > 4)
s = ink[1040:1080, 30:300]
yy, xx = np.where(s)
print('routines label', (xx.min()+30, yy.min()+1040, xx.max()+30, yy.max()+1040) if len(xx) else None)
