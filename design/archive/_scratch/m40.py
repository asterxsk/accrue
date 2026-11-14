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

print('time', bb(450, 570, 220, 560))
print('of', bb(575, 625, 300, 480))
print('goal right text', bb(1210, 1250, 500, 700))
# goal card only (bg diff)
bg = (np.abs(im - np.array([17, 17, 17])).max(axis=2) > 8)
print('goal label', bb(1180, 1200, 70, 450))
