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

for f, bg, card in [('05-new-habit', 10, 17), ('05-new-habit-light', 252, 255)]:
    im = m(f)
    cardmask = (np.abs(im - np.array([bg, bg, bg])).max(axis=2) > 3)
    print('==', f)
    for y0, y1 in [(480, 610), (615, 745), (750, 880)]:
        print(' card', y0, bb(cardmask, y0, y1, 20, 760))
    ink = (np.abs(im - np.array([card, card, card])).max(axis=2) > 8)
    for y0, y1 in [(490, 600), (625, 735), (760, 870)]:
        print('  icon', bb(ink, y0, y1, 60, 140), 'label', bb(ink, y0, y1, 150, 560),
              'radio', bb(ink, y0, y1, 640, 720))
    print(' name label', bb(ink, 240, 270, 30, 300))
    print(' name field', bb(cardmask, 285, 400, 20, 760))
    print(' name text', bb(ink, 320, 370, 60, 500))
    print(' daily card', bb(cardmask, 1000, 1120, 20, 760))
    print(' minus', bb(ink, 1000, 1110, 60, 200))
    print(' plus', bb(ink, 1000, 1110, 600, 730))
    print(' eight', bb(ink, 1010, 1080, 160, 230))
    print(' glasses', bb(ink, 1010, 1080, 225, 400))
    print(' reminder card', bb(cardmask, 1195, 1285, 20, 760))
    print(' time text', bb(ink, 1220, 1270, 60, 400))
    print(' every day', bb(ink, 1220, 1270, 450, 730))
    print(' create btn', bb(cardmask, 1450, 1600, 20, 760))
    print(' track label', bb(ink, 440, 470, 30, 300))
