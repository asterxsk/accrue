import json
p = r'D:\Apps\projects\habit_tracker\design\_scratch\figcraft\document.json'
d = json.load(open(p, encoding='utf-8'))
cols = {c['id']: c for c in d['variables']['collections']}
for v in d['variables']['variables']:
    modes = cols[v['collection']]['modes']
    out = []
    for m in modes:
        val = v['values'].get(m['id'], {})
        val = val.get('value') if isinstance(val, dict) else val
        if isinstance(val, dict) and 'r' in val:
            r, g, b = val['r'], val['g'], val['b']
            a = val.get('a', 1)
            out.append(f"{m['name']}=#{round(r*255):02x}{round(g*255):02x}{round(b*255):02x}" + ('' if a == 1 else f'@{a}'))
        else:
            out.append(f"{m['name']}={val}")
    print(f"{v['name']:16s} " + '  '.join(out))
