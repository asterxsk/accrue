from PIL import Image
import numpy as np
for f, bg in [('01-today',10),('01-today-light',252),('06-insights',10),('08-routines',10),('07-empty',10)]:
    im = np.array(Image.open('D:/Apps/projects/habit_tracker/design/renders/'+f+'.png').convert('RGB')).astype(int)
    ink = (np.abs(im-bg).max(axis=2) > 4)
    ys, xs = np.where(ink[1450:1670, :])
    print(f, 'bbox', xs.min(), ys.min()+1450, xs.max(), ys.max()+1450)
    for a, b, lbl in [(1525,1580,'icons'), (1582,1625,'labels')]:
        row = ink[a:b, :]
        cols = np.where(row.any(axis=0))[0]
        if len(cols) == 0:
            continue
        runs = []
        s = cols[0]; p = cols[0]
        for c in cols[1:]:
            if c > p+1:
                runs.append((s, p)); s = c
            p = c
        runs.append((s, p))
        print('  ', lbl, [(int(x[0]), int(x[1]), int((x[0]+x[1])/2)) for x in runs if x[1]-x[0] > 3])
