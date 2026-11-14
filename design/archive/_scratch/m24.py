from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '03-timer-running.png').convert('RGB')).astype(int)
r, g, b = im[:, :, 0], im[:, :, 1], im[:, :, 2]
blue = (b > 150) & (r < 130)
ys, xs = np.where(blue[200:800, 100:700])
print('blue bbox', xs.min()+100, ys.min()+200, xs.max()+100, ys.max()+200)
# ring track (dark gray)
trk = (np.abs(im - np.array([42, 42, 42])).max(axis=2) < 8)
ys, xs = np.where(trk[200:800, 100:700])
print('track bbox', xs.min()+100, ys.min()+200, xs.max()+100, ys.max()+200)
# angles: for blue pixels compute angle around center
cx, cy = (xs.min()+xs.max())/2 + 100, 0
# recompute using track
ys, xs = np.where(trk[200:800, 100:700])
cx = (xs.min()+xs.max())/2 + 100
cy = (ys.min()+ys.max())/2 + 200
print('center', cx, cy)
ys, xs = np.where(blue)
ang = (np.degrees(np.arctan2(xs-cx, -(ys-cy))) + 360) % 360
print('blue angle range', ang.min(), ang.max(), 'count', len(ang))
import collections
hist = collections.Counter((ang//10).astype(int))
print(sorted(hist.items()))
# pause button
white = (im.min(axis=2) > 200)
ys, xs = np.where(white[850:1030, 300:500])
print('pause glyph', xs.min()+300, ys.min()+850, xs.max()+300, ys.max()+850)
ys, xs = np.where(blue[850:1030, 300:500])
print('pause circle', xs.min()+300, ys.min()+850, xs.max()+300, ys.max()+850)
