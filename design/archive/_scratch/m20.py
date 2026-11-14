from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '02-counter-detail.png').convert('RGB')).astype(int)
ink = (np.abs(im - 10).max(axis=2) > 4)

def rowruns(y):
    xs = np.where(ink[y])[0]
    out = []
    a = xs[0]; p = xs[0]
    for c in xs[1:]:
        if c > p+1:
            out.append((int(a), int(p))); a = c
        p = c
    out.append((int(a), int(p)))
    return out

for y in [1320, 1330, 1345, 1360, 1372]:
    print(y, rowruns(y))
# vertical extents per dot
for x0, x1 in [(48, 96), (138, 186), (228, 276), (318, 366), (408, 456), (498, 546), (588, 636)]:
    ys = np.where(ink[1300:1400, x0:x1].any(axis=1))[0]
    print(x0, ys.min()+1300, ys.max()+1300)
# glasses dots vertical extents
for x0, x1 in [(70, 122), (154, 206), (490, 542), (574, 626), (658, 710)]:
    ys = np.where(ink[720:820, x0:x1].any(axis=1))[0]
    print('glass', x0, ys.min()+720, ys.max()+720)
