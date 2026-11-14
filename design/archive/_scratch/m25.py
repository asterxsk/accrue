from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '03-timer-running.png').convert('RGB')).astype(int)
for y in range(250, 300):
    print(y, tuple(im[y, 390]), tuple(im[y, 200]))
print('--- bottom')
for y in range(730, 780):
    print(y, tuple(im[y, 390]), tuple(im[y, 200]))
print('--- left/right at ring mid')
for x in [150, 160, 170, 610, 620, 630]:
    print(x, tuple(im[500, x]))
