import json, sys

p = r'D:\Apps\projects\habit_tracker\design\_scratch\figcraft\document.json'
d = json.load(open(p, encoding='utf-8'))
nodes = d['nodes']
root = nodes['1']

def node(i):
    return nodes[str(i)]

for c in root['children']:
    n = node(c)
    print(c, n.get('type'), repr(n.get('name')), n.get('x'), n.get('y'), n.get('width'), n.get('height'))
