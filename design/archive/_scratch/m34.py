from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '01-today.png').convert('RGB')).astype(int)
prev = None
for y in range(1050, 1290):
    c = tuple(im[y, 390])
    if c != prev:
        print(y, c)
        prev = c
