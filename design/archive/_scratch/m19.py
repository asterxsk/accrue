from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'

def m(f):
    return np.array(Image.open(base + f + '.png').convert('RGB')).astype(int)

def runs(mask, y0, y1, x0, x1):
    s = mask[y0:y1, x0:x1]
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

im = m('02-counter-detail')
ink = (np.abs(im - 10).max(axis=2) > 4)
print('cd dots runs', runs(ink, 1310, 1390, 20, 760))
print('cd daylabel runs', runs(ink, 1395, 1445, 20, 760))
print('cd card runs', runs(ink, 1145, 1200, 60, 730))
im = m('04-routine-run')
ink = (np.abs(im - 10).max(axis=2) > 4)
print('rr nextup runs', runs(ink, 825, 860, 20, 760))
print('rr journal runs', runs(ink, 885, 935, 20, 760))
print('rr stretch runs', runs(ink, 980, 1030, 20, 760))
im = m('07-empty')
ink = (np.abs(im - 10).max(axis=2) > 4)
print('em btn runs', runs(ink, 850, 880, 100, 700))
print('em browse runs', runs(ink, 970, 1000, 100, 700))
print('em sub1 runs', runs(ink, 670, 700, 100, 700))
