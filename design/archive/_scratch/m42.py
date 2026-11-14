from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '06-insights.png').convert('RGB')).astype(int)
ink = (np.abs(im - 10).max(axis=2) > 4)

def bb(y0, y1, x0, x1):
    s = ink[y0:y1, x0:x1]
    ys, xs = np.where(s)
    if len(xs) == 0:
        return None
    return (int(x0+xs.min()), int(y0+ys.min()), int(x0+xs.max()), int(y0+ys.max()))

print('100%', bb(670, 720, 660, 760))
print('50%', bb(780, 830, 660, 760))
print('0', bb(870, 915, 690, 760))
print('bars top', bb(660, 900, 40, 620))
# per-bar tops
for x0, x1 in [(45, 105), (130, 190), (215, 275), (300, 360), (385, 445), (450, 515), (525, 595)]:
    b = bb(660, 905, x0, x1)
    print('bar', x0, b)
