import json, sys

p = r'D:\Apps\projects\habit_tracker\design\_scratch\figcraft\document.json'
d = json.load(open(p, encoding='utf-8'))
nodes = d['nodes']

def col(c):
    if not isinstance(c, dict):
        return str(c)
    r, g, b = c.get('r', 0), c.get('g', 0), c.get('b', 0)
    a = c.get('a', 1)
    return '#%02x%02x%02x' % (round(r * 255), round(g * 255), round(b * 255)) + ('' if a == 1 else f'@{a:.2f}')

def fills(n):
    out = []
    for f in n.get('fills', []) or []:
        if f.get('type') == 'solid':
            out.append(col(f.get('color') or {}))
        else:
            out.append(str(f.get('type')))
    return ','.join(out)

def strokes(n):
    st = n.get('strokes') or []
    if not st:
        return ''
    s = ','.join(col(x.get('color') or {}) if x.get('type') == 'solid' else str(x.get('type')) for x in st)
    w = n.get('stroke_weight') or n.get('strokeWeight')
    return f"stroke={s} sw={w}"

def dump(i, px, py, depth, f, fixed):
    n = nodes[str(i)]
    t = n.get('type')
    tr = n.get('transform') or [1, 0, 0, 1, 0, 0]
    x = px + tr[4]
    y = py + tr[5]
    parts = [f"{'  ' * depth}{i} {t} {n.get('name')!r} x={x:g} y={y:g} w={n.get('width'):g} h={n.get('height'):g}"]
    fl = fills(n) or (fixed if t == 'text' else '')
    if fl:
        parts.append(f"fill={fl}")
    st = strokes(n)
    if st:
        parts.append(st)
    c = n.get('corners')
    if c:
        parts.append(f"r={c.get('radii')}")
    if n.get('dash'):
        parts.append(f"dash={n.get('dash')}")
    if t == 'text':
        s = n.get('style') or {}
        parts.append(f"chars={n.get('characters')!r}")
        parts.append(f"font={s.get('font_family')} {s.get('font_style')} {s.get('font_size')} lh={s.get('line_height')} ls={s.get('letter_spacing')} align={n.get('text_align') or s.get('text_align')}")
    if n.get('opacity') not in (None, 1):
        parts.append(f"opacity={n.get('opacity')}")
    if n.get('visible') is False:
        parts.append("HIDDEN")
    f.write(' '.join(parts) + '\n')
    for ch in n.get('children', []) or []:
        dump(ch, x, y, depth + 1, f, fl)

frame = sys.argv[1]
outp = sys.argv[2]
with open(outp, 'w', encoding='utf-8') as f:
    dump(frame, 0, 0, 0, f, '')
print('wrote', outp)
