from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '08-routines-light.png').convert('RGB')).astype(int)
r, g, b = im[:, :, 0], im[:, :, 1], im[:, :, 2]
blue = (b > 140) & (r < 120)
sub = blue[1200:1300, 40:740]
ys, xs = np.where(sub)
print('newroutine blue bbox', xs.min()+40, ys.min()+1200, xs.max()+40, ys.max()+1200)
# split runs
cols = np.where(sub.any(axis=0))[0]
runs = []
a = cols[0]; p = cols[0]
for c in cols[1:]:
    if c > p+1:
        runs.append((int(a+40), int(p+40))); a = c
    p = c
runs.append((int(a+40), int(p+40)))
print('runs', runs)
# dashed border bbox
border = (np.abs(im - np.array([212, 212, 217])).max(axis=2) < 40)
ys, xs = np.where(border[1180:1320, 20:760])
print('dash bbox', xs.min()+20, ys.min()+1180, xs.max()+20, ys.max()+1180)
