from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '02-counter-detail.png').convert('RGB')).astype(int)
ink = (np.abs(im - 10).max(axis=2) > 4)

def colruns(y0, y1, x0=0, x1=780):
    s = ink[y0:y1, x0:x1]
    cols = np.where(s.any(axis=0))[0]
    out = []
    if len(cols) == 0:
        return out
    a = cols[0]; p = cols[0]
    for c in cols[1:]:
        if c > p+1:
            out.append((int(a+x0), int(p+x0))); a = c
        p = c
    out.append((int(a+x0), int(p+x0)))
    return out

print('label', colruns(1290, 1330, 0, 400))
print('dots', colruns(1345, 1420, 0, 780))
print('daylabels', colruns(1425, 1475, 0, 780))
# vertical extents
for x0, x1 in [(48, 96), (138, 186), (228, 276), (318, 366), (408, 456), (498, 546), (588, 636)]:
    ys = np.where(ink[1330:1430, x0:x1].any(axis=1))[0]
    print('dot', x0, (ys.min()+1330, ys.max()+1330) if len(ys) else None)
# glasses dots
print('glasses dots', colruns(730, 800, 0, 780))
for x0, x1 in [(70, 122), (154, 206), (490, 542), (574, 626), (658, 710)]:
    ys = np.where(ink[720:820, x0:x1].any(axis=1))[0]
    print('glass', x0, (ys.min()+720, ys.max()+720) if len(ys) else None)
