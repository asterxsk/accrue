from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '03-timer-running.png').convert('RGB')).astype(int)
import math
cx, cy, R = 390, 539, 233
for deg in range(0, 360, 15):
    x = int(round(cx + R*math.sin(math.radians(deg))))
    y = int(round(cy - R*math.cos(math.radians(deg))))
    print(deg, (x, y), tuple(im[y, x]))
print('radius scan at top-left 315deg')
for rr in range(220, 245):
    x = int(round(cx + rr*math.sin(math.radians(255))))
    y = int(round(cy - rr*math.cos(math.radians(255))))
    print(rr, (x,y), tuple(im[y,x]))
