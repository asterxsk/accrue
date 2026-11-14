from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '05-new-habit-light.png').convert('RGB')).astype(int)
r, g, b = im[:, :, 0], im[:, :, 1], im[:, :, 2]
yy, xx = np.mgrid[0:im.shape[0], 0:im.shape[1]]
white = (im.min(axis=2) > 200)
circ = ((xx - 667.5)**2 + (yy - 1083.5)**2) < 38**2
ys, xs = np.where(white & circ)
print('plus glyph', xs.min(), ys.min(), xs.max(), ys.max(), 'center', (xs.min()+xs.max())/2, (ys.min()+ys.max())/2)
# minus glyph inside minus circle center 111.5,1083.5
circ2 = ((xx - 111.5)**2 + (yy - 1083.5)**2) < 38**2
dark = (im.max(axis=2) < 160)
ys, xs = np.where(dark & circ2)
print('minus glyph', xs.min(), ys.min(), xs.max(), ys.max(), 'center', (xs.min()+xs.max())/2, (ys.min()+ys.max())/2)
# 8 text vs minus circle center
blk = (im.max(axis=2) < 120)
ys, xs = np.where(blk[1050:1100, 170:230])
print('eight bbox', xs.min()+170, ys.min()+1050, xs.max()+170, ys.max()+1050)
# card outer bounds
grayborder = (np.abs(im.max(axis=2) - 228) < 4) & (np.abs(r - b) < 8)
ys, xs = np.where(grayborder[1000:1150, 40:740])
print('daily border bbox', xs.min()+40, ys.min()+1000, xs.max()+40, ys.max()+1000)
