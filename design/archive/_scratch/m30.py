from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '01-today.png').convert('RGB')).astype(int)
col = im[:, 120]
ys = [y for y in range(1080, 1270) if tuple(col[y]) != (17, 17, 17)]
print('badge col ys', ys[0], ys[-1], len(ys))
row_ys = []
# determine disc extents by mask of color ~20
m = (np.abs(im - 20).max(axis=2) < 2)
sub = m[1080:1270, 50:190]
yy, xx = np.where(sub)
print('badge disc bbox', xx.min()+50, yy.min()+1080, xx.max()+50, yy.max()+1080)
# blue '2' glyph
r, g, b = im[:, :, 0], im[:, :, 1], im[:, :, 2]
blue = (b > 120) & (r < 110)
yy, xx = np.where(blue[1080:1270, 50:190])
print('blue 2 bbox', xx.min()+50, yy.min()+1080, xx.max()+50, yy.max()+1080)
# title Morning
ink = (np.abs(im - 17).max(axis=2) > 8)
yy, xx = np.where(ink[1120:1200, 150:500])
print('title bbox', xx.min()+150, yy.min()+1120, xx.max()+150, yy.max()+1120)
yy, xx = np.where(ink[1200:1240, 150:500])
print('sub bbox', xx.min()+150, yy.min()+1200, xx.max()+150, yy.max()+1200)
yy, xx = np.where(blue[1130:1200, 560:740])
print('2of4 bbox', xx.min()+560, yy.min()+1130, xx.max()+560, yy.max()+1130)
# card vertical bounds at x=390
ys = [y for y in range(1050, 1300) if tuple(im[y, 390]) == (17, 17, 17)]
print('card fill ys', ys[0], ys[-1])
