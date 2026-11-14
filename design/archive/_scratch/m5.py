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

im = m('01-today')
ink = (np.abs(im - np.array([17, 17, 17])).max(axis=2) > 6)  # content on card bg
print('today card badge', bb(ink, 1130, 1230, 60, 180))
print('today card title', bb(ink, 1140, 1180, 178, 500))
print('today card sub', bb(ink, 1185, 1225, 178, 500))
print('today card value', bb(ink, 1140, 1180, 570, 725))
# card edges via row sample
row = im[1180, :]
nonbg = np.where(np.abs(row - np.array([10, 10, 10])).max(axis=1) > 3)[0]
print('card row extent', nonbg.min(), nonbg.max())

sf = m('09-you-settings')
ink2 = (np.abs(sf - np.array([17, 17, 17])).max(axis=2) > 3)
for y in [435, 436, 539, 643, 747, 1043]:
    print('divider y', y, bb(ink2, y, y+1, 49, 730))
print('settings label x', bb(ink2, 360, 400, 49, 400))
print('chevrons', bb(ink2, 365, 400, 650, 720), bb(ink2, 570, 610, 650, 720))
print('toggle', bb(ink2, 455, 515, 600, 720))
print('account chevrons', bb(ink2, 870, 910, 650, 720))
print('about val', bb(ink2, 975, 1010, 620, 720))
# settings card bbox
print('pref card', bb(ink2, 320, 790, 20, 760), 'acc card', bb(ink2, 820, 1160, 20, 760))
im3 = m('09-you-settings-light')
ink3 = (np.abs(im3 - np.array([255, 255, 255])).max(axis=2) > 3)
for y in [435, 539, 643, 747, 1043]:
    print('light divider y', y, bb(ink3, y, y+1, 49, 730))
im4 = m('08-routines')
ink4 = (np.abs(im4 - np.array([17, 17, 17])).max(axis=2) > 6)
print('newroutine border', bb(np.abs(im4 - np.array([10, 10, 10])).max(axis=2) > 3, 1180, 1310, 20, 760))
print('plus newroutine', bb(ink4, 1210, 1290, 200, 400))
print('label newroutine', bb(ink4, 1210, 1290, 320, 600))
