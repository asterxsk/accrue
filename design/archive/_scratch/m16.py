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

im = m('06-insights')
bg = (np.abs(im - 10).max(axis=2) > 4)
ink = (np.abs(im - 17).max(axis=2) > 8)
print('hero card', bb(bg, 260, 560, 20, 760))
print('86', bb(ink, 300, 420, 60, 500))
print('sub', bb(ink, 430, 485, 60, 500))
print('delta', bb(ink, 320, 380, 560, 740))
print('triangle', bb(ink, 320, 380, 580, 615))
print('daily label', bb(bg, 570, 620, 30, 400))
print('axis 100', bb(bg, 680, 715, 640, 760))
print('axis 50', bb(bg, 790, 825, 640, 760))
print('axis 0', bb(bg, 880, 915, 640, 760))
print('bars', bb(bg, 660, 900, 30, 620))
print('day labels', bb(bg, 910, 950, 30, 620))
print('streaks label', bb(bg, 990, 1030, 30, 400))
print('water row', bb(bg, 1040, 1090, 30, 760))
print('water value', bb(bg, 1040, 1090, 600, 760))
print('morning row', bb(bg, 1130, 1180, 30, 760))
print('deep row', bb(bg, 1220, 1270, 30, 760))
# bar bbox each
for x0, x1 in [(50, 110), (135, 195), (220, 280), (305, 365), (390, 450), (455, 520), (530, 590)]:
    print('bar', x0, bb(bg, 660, 900, x0, x1))
