from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'

def m(f):
    return np.array(Image.open(base + f + '.png').convert('RGB')).astype(int)

def bb(mask, y0, y1, x0, x1):
    s = mask[y0:y1, x0:x1]
    ys, xs = np.where(s)
    if len(xs) == 0:
        return None
    return (int(x0+xs.min()), int(y0+ys.min()), int(x0+xs.max()), int(y0+ys.max()))

for f in ['02-counter-detail', '03-timer-running', '04-routine-run', '09-you-settings', '05-new-habit']:
    im = m(f)
    ink = (np.abs(im - 10).max(axis=2) > 4)
    print(f, 'topright', bb(ink, 120, 200, 620, 760), 'back', bb(ink, 100, 210, 30, 135))
    if f == '05-new-habit':
        print('  title', bb(ink, 120, 200, 250, 550), 'cancel', bb(ink, 120, 200, 30, 200))
# insights delta zoom
im = m('06-insights')
ink = (np.abs(im - 10).max(axis=2) > 4)
print('delta bbox', bb(ink, 320, 375, 560, 740))
print('triangle only', bb((im[:, :, 2] > 130) & (im[:, :, 0] < 110), 330, 370, 560, 620))
print('plus12 text', bb(ink, 330, 370, 610, 740))
