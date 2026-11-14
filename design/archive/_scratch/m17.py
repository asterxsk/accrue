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

for f in ['01-today', '06-insights', '08-routines', '07-empty']:
    im = m(f)
    ink = (np.abs(im - 10).max(axis=2) > 4)
    print('==', f)
    print(' kicker', bb(ink, 110, 155, 40, 400))
    print(' title', bb(ink, 155, 230, 40, 500))
    print(' avatar/action', bb(ink, 110, 210, 630, 760))
    # section labels (italic)
    for y0 in range(240, 1400, 10):
        pass
# explicit
im = m('08-routines')
ink = (np.abs(im - 10).max(axis=2) > 4)
print('routines kicker', bb(ink, 120, 160, 40, 400))
print('routines title', bb(ink, 155, 230, 40, 500))
print('your routines label', bb(ink, 270, 310, 30, 400))
print('plus action', bb(ink, 100, 220, 630, 760))
print('routines card top', [int(y) for y in np.where((np.abs(im[:, 390] - np.array([17, 17, 17])).max(axis=1) <= 1))[0] if 300 < y < 340])
im = m('06-insights')
ink = (np.abs(im - 10).max(axis=2) > 4)
print('insights kicker', bb(ink, 110, 155, 40, 400))
print('insights streaks label', bb(ink, 990, 1040, 30, 400))
print('insights water', bb(ink, 1040, 1100, 30, 400))
print('insights water val', bb((im[:, :, 2] > 120) & (im[:, :, 0] < 130), 1040, 1100, 500, 760))
print('insights mw', bb(ink, 1130, 1190, 30, 400), 'val', bb((im[:, :, 2] > 120) & (im[:, :, 0] < 130), 1130, 1190, 500, 760))
print('insights dw', bb(ink, 1220, 1280, 30, 400), 'val', bb((im[:, :, 2] > 120) & (im[:, :, 0] < 130), 1220, 1280, 500, 760))
