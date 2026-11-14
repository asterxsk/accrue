from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '05-new-habit-light.png').convert('RGB')).astype(int)
# vertical scan at x=390 : list colors transitions
prev = None
for y in range(470, 920):
    c = tuple(im[y, 390])
    if c != prev:
        print(y, c)
        prev = c
