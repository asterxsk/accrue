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

im = m('09-you-settings')
card = np.array([17, 17, 17])
ink = (np.abs(im - card).max(axis=2) > 8)
print('appearance row: icon', bb(ink, 360, 410, 60, 140), 'label', bb(ink, 360, 410, 140, 500),
      'value', bb(ink, 360, 410, 560, 676), 'chev', bb(ink, 360, 410, 670, 730))
print('reminders label', bb(ink, 460, 515, 140, 500))
print('reminder time value', bb(ink, 565, 615, 520, 676), 'chev', bb(ink, 565, 615, 670, 730))
print('start week value', bb(ink, 670, 720, 520, 676), 'chev', bb(ink, 670, 720, 670, 730))
print('data export label', bb(ink, 870, 915, 60, 500), 'chev', bb(ink, 870, 915, 670, 730))
print('about label', bb(ink, 975, 1010, 60, 500), 'val', bb(ink, 975, 1010, 560, 676))
print('signout', bb(ink, 1075, 1120, 60, 500))
# row heights: card top/bottom
cardmask = (np.abs(im - np.array([10, 10, 10])).max(axis=2) > 3)
print('pref card bbox', bb(cardmask, 320, 800, 40, 740))
print('acc card bbox', bb(cardmask, 820, 1170, 40, 740))
# icon centers
for y0, y1 in [(355, 410), (460, 515), (565, 620), (670, 725), (870, 925), (975, 1030), (1075, 1130)]:
    print('icon', y0, bb(ink, y0, y1, 70, 130))

sf = m('09-you-settings-light')
ink3 = (np.abs(sf - np.array([255, 255, 255])).max(axis=2) > 8)
print('LIGHT dividers')
d = np.abs(sf - 255).max(axis=2)
for y in range(420, 800):
    xs = np.where(d[y, 50:730] > 2)[0]
    if len(xs) > 400:
        print(' ', y, len(xs), xs.min()+50, xs.max()+50, sf[y, 400])
