from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '01-today.png').convert('RGB')).astype(int)
for y in [1160, 1183, 1200, 1215, 1230]:
    row = im[y]
    xs = [x for x in range(48, 220) if tuple(row[x]) == (20, 20, 20)]
    print('y', y, (min(xs), max(xs)) if xs else None, len(xs))
for x in [100, 120, 140]:
    col = im[:, x]
    ys = [y for y in range(1090, 1265) if tuple(col[y]) == (20, 20, 20)]
    print('x', x, (min(ys), max(ys)) if ys else None, len(ys))
