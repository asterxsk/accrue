from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '04-routine-run.png').convert('RGB')).astype(int)
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

print('nextup label', colruns(825, 865, 0, 400))
print('row1', colruns(880, 940, 0, 780))
print('row2', colruns(975, 1035, 0, 780))
print('skip', colruns(1500, 1590, 0, 780))
print('segments', colruns(360, 385, 0, 780))
print('progress seg y', colruns(395, 420, 0, 780))
