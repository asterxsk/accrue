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

# routine run
im = m('04-routine-run')
ink = (np.abs(im - 10).max(axis=2) > 4)
print('rr title', bb(ink, 220, 290, 30, 500))
print('rr sub', bb(ink, 295, 330, 30, 500))
print('rr segments', bb(ink, 355, 385, 30, 760))
print('rr card', bb(ink, 415, 780, 30, 760))
ink2 = (np.abs(im - 17).max(axis=2) > 8)
print('rr step label', bb(ink2, 455, 490, 70, 500))
print('rr h1', bb(ink2, 510, 560, 70, 500))
print('rr sub2', bb(ink2, 575, 615, 70, 500))
print('rr button', bb(ink2, 660, 770, 70, 720))
print('rr nextup', bb(ink, 820, 855, 30, 400))
print('rr journal', bb(ink, 890, 930, 110, 500))
print('rr 5min', bb(ink, 890, 930, 500, 760))
print('rr stretch', bb(ink, 985, 1025, 110, 500))
print('rr 3min', bb(ink, 985, 1025, 500, 760))
print('rr skip btn', bb(ink, 1470, 1580, 30, 760))
# counter week dots
im = m('02-counter-detail')
ink = (np.abs(im - 10).max(axis=2) > 4)
print('cd weeklabel', bb(ink, 1225, 1265, 30, 400))
print('cd weekdots', bb(ink, 1310, 1390, 30, 760))
print('cd daylabels', bb(ink, 1390, 1450, 30, 760))
print('cd card', bb(ink, 1030, 1230, 30, 760))
print('cd cardlabel', bb(ink, 1070, 1105, 70, 500))
print('cd cardvalue', bb(ink, 1120, 1180, 70, 500))
print('cd best', bb(ink, 1140, 1200, 500, 720))
# empty
im = m('07-empty')
ink = (np.abs(im - 10).max(axis=2) > 4)
print('em kicker', bb(ink, 510, 545, 100, 700))
print('em title', bb(ink, 580, 630, 100, 700))
print('em sub1', bb(ink, 660, 700, 100, 700))
print('em sub2', bb(ink, 700, 735, 100, 700))
print('em btn', bb(ink, 800, 910, 100, 700))
print('em browse', bb(ink, 950, 990, 100, 700))
