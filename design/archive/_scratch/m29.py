from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '01-today.png').convert('RGB')).astype(int)
r, g, b = im[:, :, 0], im[:, :, 1], im[:, :, 2]
# badge bg is ~ (18,18,18)? sample
print('colors', tuple(im[1180, 100]), tuple(im[1180, 300]), tuple(im[1120, 390]))
# find badge disc: differs from card bg 17 by small amount; sample along row y=1180
row = im[1180]
for x in range(48, 200):
    c = tuple(row[x])
    if c != (17, 17, 17) and x < 190:
        pass
prev = None
for x in range(48, 200):
    c = tuple(row[x])
    if c != prev:
        print(x, c)
        prev = c
