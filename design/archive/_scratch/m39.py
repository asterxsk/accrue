from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '03-timer-running.png').convert('RGB')).astype(int)
ink = (np.abs(im - 10).max(axis=2) > 4)

def bb(y0, y1, x0, x1):
    s = ink[y0:y1, x0:x1]
    ys, xs = np.where(s)
    if len(xs) == 0:
        return None
    return (int(x0+xs.min()), int(y0+ys.min()), int(x0+xs.max()), int(y0+ys.max()))

print('time', bb(440, 580, 150, 640))
print('of', bb(580, 630, 150, 640))
print('kicker', bb(230, 280, 200, 600))
print('goalcard', bb(1140, 1300, 30, 760))
print('goal label', bb(1160, 1200, 60, 500))
print('goal value', bb(1205, 1255, 60, 500))
print('goal right', bb(1205, 1260, 430, 730))
print('addbtn', bb(1340, 1500, 30, 760))
print('addtext', bb(1380, 1460, 200, 600))
