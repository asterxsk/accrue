from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
for f, disc in [('01-today', 20), ('08-routines', 20)]:
    im = np.array(Image.open(base + f + '.png').convert('RGB')).astype(int)
    m = (np.abs(im - disc).max(axis=2) <= 2)
    for y0, y1 in [(1120, 1240), (350, 460)]:
        s = m[y0:y1, 60:180]
        yy, xx = np.where(s)
        if len(xx):
            print(f, y0, 'bbox', xx.min()+60, yy.min()+y0, xx.max()+60, yy.max()+y0,
                  'w', xx.max()-xx.min()+1, 'h', yy.max()-yy.min()+1)
