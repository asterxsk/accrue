from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '06-insights.png').convert('RGB')).astype(int)
for y in range(880, 910):
    row = im[y]
    xs = np.where(np.abs(row - 10).max(axis=1) > 4)[0]
    seg = [x for x in xs if 600 < x < 780]
    print(y, (min(seg), max(seg)) if seg else None, [int(x) for x in seg][:20])
print('--- x 731 column color around 890')
for y in range(880, 906):
    print(y, tuple(im[y, 731]), tuple(im[y, 720]))
