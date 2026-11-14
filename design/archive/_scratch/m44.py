from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '06-insights-light.png').convert('RGB')).astype(int)
for y in range(895, 915):
    row = im[y]
    xs = np.where(np.abs(row - 252).max(axis=1) > 3)[0]
    seg = [int(x) for x in xs if x > 40]
    print(y, (seg[0], seg[-1]) if seg else None, len(seg))
