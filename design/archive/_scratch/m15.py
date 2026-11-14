from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '05-new-habit-light.png').convert('RGB')).astype(int)
r, g, b = im[:, :, 0], im[:, :, 1], im[:, :, 2]
disc = (np.abs(im - np.array([244, 244, 245])).max(axis=2) < 3)

def bb(mask, y0, y1, x0, x1):
    s = mask[y0:y1, x0:x1]
    ys, xs = np.where(s)
    if len(xs) == 0:
        return None
    return (int(x0+xs.min()), int(y0+ys.min()), int(x0+xs.max()), int(y0+ys.max()))

# icon discs
for y0, y1 in [(500, 600), (650, 750), (790, 890)]:
    d = bb(disc, y0, y1, 60, 150)
    print('disc', y0, d, 'center', None if not d else ((d[0]+d[2])/2, (d[1]+d[3])/2))
# glyphs inside discs (darker than disc)
glyph = (im.max(axis=2) < 200)
for y0, y1 in [(500, 600), (650, 750), (790, 890)]:
    gl = bb(glyph, y0, y1, 66, 145)
    print('glyph', y0, gl, 'center', None if not gl else ((gl[0]+gl[2])/2, (gl[1]+gl[3])/2))
# titles
for y0, y1 in [(510, 560), (660, 710), (800, 850)]:
    print('title', y0, bb(glyph, y0, y1, 160, 600))
    print('sub', y0, bb(glyph, y0+30, y1+40, 160, 700))
# radio rings
ring = (np.abs(im - np.array([212, 212, 217])).max(axis=2) < 20)
print('radio light rows', bb(ring, 500, 600, 630, 720), bb(ring, 650, 750, 630, 720))
blue = (b > 150) & (r < 130)
print('radio selected', bb(blue, 790, 890, 640, 720))
