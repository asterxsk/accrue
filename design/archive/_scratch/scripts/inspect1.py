import json, sys

p = r'D:\Apps\projects\habit_tracker\design\_scratch\figcraft\document.json'
d = json.load(open(p, encoding='utf-8'))
print('format', d['format'], d['version'])
print('variables', json.dumps(d['variables'])[:4000])
nodes = d['nodes']
print('nodes type', type(nodes), len(nodes))
if isinstance(nodes, dict):
    k = list(nodes)[0]
    print('first key', k)
    print(json.dumps(nodes[k], indent=1)[:3000])
else:
    print(json.dumps(nodes[0], indent=1)[:3000])
print('styles', json.dumps(d['styles'])[:2000])
print('pages', json.dumps(d['pages'])[:800])
