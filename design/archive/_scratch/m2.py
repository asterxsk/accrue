from PIL import Image
import numpy as np

def runs1d(mask):
    idx = np.where(mask)[0]
    if len(idx) == 0:
        return []
    out = []
    s = idx[0]; p = idx[0]
    for c in idx[1:]:
        if c > p+1:
            out.append((int(s), int(p))); s = c
        p = c
    out.append((int(s), int(p)))
    return out

base = 'D:/Apps/projects/habit_tracker/design/renders/'
for f in ['01-today', '06-insights', '08-routines', '07-empty']:
    im = np.array(Image.open(base + f + '.png').convert('RGB')).astype(int)
    print(f, 'pill bg sample', im[1520, 390], im[1640, 100], im[1600, 390])
    pillbg = im[1520, 390]
    ink = (np.abs(im - pillbg).max(axis=2) > 10)
    # pill vertical extent at x=390 column
    col = ink[:, 390]
    print('  rows at x=390:', runs1d(col[1450:1670]))
    # tab bands: restrict to inside pill x 60..720
    sub = ink[1500:1660, 60:720]
    ys, xs = np.where(sub)
    print('  content bbox y', ys.min()+1500, ys.max()+1500)
    cols = np.where(sub.any(axis=0))[0]
    print('  col runs', [(a+60, b+60) for a, b in runs1d(sub.any(axis=0)) if b-a > 3])
    for c0, c1 in [(100, 220), (340, 460), (580, 700)]:
        band = ink[1500:1660, c0:c1]
        yy = np.where(band.any(axis=1))[0]
        if len(yy):
            print('   tab', c0, 'y', yy.min()+1500, yy.max()+1500)
