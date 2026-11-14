from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'

def load(f):
    return np.array(Image.open(base + f + '.png').convert('RGB')).astype(int)

def bbox(im, y0, y1, x0, x1, bg=10, tol=8):
    m = (np.abs(im - bg).max(axis=2) > tol)[y0:y1, x0:x1]
    ys, xs = np.where(m)
    if len(xs) == 0:
        return None
    return (int(x0+xs.min()), int(y0+ys.min()), int(x0+xs.max()), int(y0+ys.max()))

im = load('02-counter-detail')
print('counter card bbox', bbox(im, 1030, 1210, 20, 760))
print('counter label', bbox(im, 1075, 1110, 60, 400))
print('counter value', bbox(im, 1130, 1180, 60, 400))
print('counter best', bbox(im, 1150, 1200, 400, 720))
print('counter week label', bbox(im, 1240, 1280, 30, 400))
print('week dots', bbox(im, 1320, 1390, 20, 760))
print('week day labels', bbox(im, 1390, 1440, 20, 760))
print('big number', bbox(im, 520, 680, 250, 450))
print('of 8', bbox(im, 560, 680, 400, 520))
print('title', bbox(im, 390, 450, 250, 530))
print('subtitle', bbox(im, 460, 500, 250, 530))
print('icon disc', bbox(im, 240, 400, 300, 480))
im2 = load('03-timer-running')
print('timer goal card', bbox(im2, 1130, 1280, 20, 760))
print('timer goal label', bbox(im2, 1155, 1190, 60, 400))
print('timer goal value', bbox(im2, 1205, 1250, 60, 400))
print('timer logged', bbox(im2, 1200, 1250, 400, 720))
print('timer addbtn', bbox(im2, 1355, 1490, 20, 760))
print('timer ring', bbox(im2, 250, 760, 100, 700))
print('pause btn', bbox(im2, 850, 1030, 280, 500))
im3 = load('01-today')
print('today card1', bbox(im3, 1080, 1270, 20, 760))
print('today badge', bbox(im3, 1130, 1220, 60, 170))
print('today routine title', bbox(im3, 1140, 1180, 170, 400))
print('today 2of4', bbox(im3, 1140, 1180, 580, 730))
print('today habit title', bbox(im3, 460, 500, 140, 500))
print('today section habits', bbox(im3, 370, 400, 30, 300))
print('today progress label', bbox(im3, 275, 315, 30, 400))
print('today pct', bbox(im3, 275, 315, 600, 740))
