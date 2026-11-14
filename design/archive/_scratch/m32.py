from PIL import Image
import numpy as np
base = 'D:/Apps/projects/habit_tracker/design/renders/'
im = np.array(Image.open(base + '01-today-light.png').convert('RGB')).astype(int)
m = (np.abs(im - np.array([244, 244, 245])).max(axis=2) <= 2)
s = m[1120:1240, 60:180]
yy, xx = np.where(s)
print('today light badge', xx.min()+60, yy.min()+1120, xx.max()+60, yy.max()+1120)
# column/row through center
cy = (yy.min()+yy.max())//2
row = np.where(m[cy, 60:180])[0]
print('row at cy', cy+1120, row.min()+60, row.max()+60)
im2 = np.array(Image.open(base + '08-routines-light.png').convert('RGB')).astype(int)
m2 = (np.abs(im2 - np.array([244, 244, 245])).max(axis=2) <= 2)
yy, xx = np.where(m2[350:460, 60:180])
print('routines badge', xx.min()+60, yy.min()+350, xx.max()+60, yy.max()+350)
yy, xx = np.where(m2[470:540, 70:150])
print('step pill tint region?', (xx.min()+70, yy.min()+470, xx.max()+70, yy.max()+470) if len(xx) else None)
