from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '01-today.png').convert('RGB')).astype(int)
bg = 10
ink = (np.abs(im - bg).max(axis=2) > 6)
blue = (im[:, :, 2] > 150) & (im[:, :, 0] < 120)

def bb(mask, y0, y1, x0, x1):
    m = mask[y0:y1, x0:x1]
    ys, xs = np.where(m)
    if len(xs) == 0:
        return None
    return (int(x0+xs.min()), int(y0+ys.min()), int(x0+xs.max()), int(y0+ys.max()))

rows = [(460, 540), (610, 690), (760, 850), (910, 1000)]
for i, (y0, y1) in enumerate(rows):
    ic = bb(ink, y0, y1, 60, 155)
    tx = bb(ink, y0, y1, 150, 500)
    print('row', i, 'icon', ic, 'cy', (ic[1]+ic[3])/2 if ic else None,
          'text', tx, 'cy', (tx[1]+tx[3])/2 if tx else None)
# row4 chevron
print('chevron4', bb(ink, 930, 1000, 620, 740))
# water controls
print('minus', bb(ink, 760, 850, 480, 590))
print('six', bb(ink, 760, 850, 580, 620))
print('plus', bb(ink, 760, 850, 620, 740))
# routine card badge
print('badge', bb(ink, 1120, 1240, 60, 180))
print('routine title', bb(ink, 1130, 1180, 170, 500))
print('2of4', bb(ink, 1130, 1180, 580, 740))
# card
print('card y', np.where((np.abs(im[:, 390] - np.array([17, 17, 17])).max(axis=1) <= 2))[0][:10])
