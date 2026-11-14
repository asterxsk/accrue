from PIL import Image
import numpy as np, math
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '03-timer-running.png').convert('RGB')).astype(int)
cx, cy = 390.5, 539.5
for deg in [0, 90, 180, 240, 250, 270, 300, 330]:
    vals = []
    for rr in range(215, 250):
        x = int(round(cx + rr*math.sin(math.radians(deg))))
        y = int(round(cy - rr*math.cos(math.radians(deg))))
        c = im[y, x]
        if c.max() > 15:
            vals.append((rr, tuple(int(v) for v in c)))
    print(deg, vals)
