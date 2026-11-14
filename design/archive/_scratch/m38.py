from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
for f in ['01-today', '06-insights']:
    im = np.array(Image.open(base + f + '.png').convert('RGB')).astype(int)
    r, g, b = im[:, :, 0], im[:, :, 1], im[:, :, 2]
    blue = (b > 120) & (r < 110)
    ys, xs = np.where(blue[110:210, 640:745])
    print(f, 'P bbox', xs.min()+640, ys.min()+110, xs.max()+640, ys.max()+110,
          'center', (xs.min()+xs.max())/2+640, (ys.min()+ys.max())/2+110)
    # avatar disc bounds by color? use bg diff ring
    disc = (np.abs(im - np.array([20, 20, 20])).max(axis=2) < 3)
    ys, xs = np.where(disc[100:220, 630:760])
    print('  disc', (xs.min()+630, ys.min()+100, xs.max()+630, ys.max()+100) if len(xs) else None)
