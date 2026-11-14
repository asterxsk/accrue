import json
p = r'D:\Apps\projects\habit_tracker\design\_scratch\figcraft\document.json'
d = json.load(open(p, encoding='utf-8'))
nodes = d['nodes']
for k in ('72', '74', '21', '58', '1519'):
    print('===', k)
    print(json.dumps(nodes[k], indent=1))
