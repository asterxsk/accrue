from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
for f, bg, card in [('09-you-settings', 10, 17), ('09-you-settings-light', 252, 255)]:
    im = np.array(Image.open(base + f + '.png').convert('RGB')).astype(int)
    d = np.abs(im - card).max(axis=2)
    print('==', f)
    for y in range(330, 1160):
        xs = np.where(d[y, 50:730] > 2)[0]
        if len(xs) > 80:
            print(y, 'count', len(xs), 'x', xs.min()+50, xs.max()+50,
                  'val', im[y, 400])
