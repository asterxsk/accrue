import os
import re
import io

SRC = 'C:/Users/p/AppData/Local/Temp/lucide_extract/package/icons'
OUT = 'lib/widgets/icon_library.dart'

icons = {}
for fn in sorted(os.listdir(SRC)):
    if not fn.endswith('.svg'):
        continue
    name = fn[:-4]
    with io.open(os.path.join(SRC, fn), encoding='utf-8') as fh:
        svg = fh.read()
    svg = re.sub(r'<!--.*?-->', '', svg, flags=re.S)
    match = re.search(r'<svg\b[^>]*>(.*)</svg>', svg, flags=re.S)
    if not match:
        continue
    body = re.sub(r'\s+', ' ', match.group(1)).strip()
    body = body.replace('\\', '\\\\').replace('$', '\\$').replace("'", "\\'")
    icons[name] = body

names = sorted(icons)
lines = [
    '// Generated from lucide-static 0.544.0 (ISC licence). Do not edit by hand.',
    '//',
    '// Each value is the inner markup of a 24x24 stroke icon; AppIcon wraps it',
    '// with the shared svg root so the whole set stays one compact map.',
    '',
    '/// Icon bodies keyed by name, sorted by name.',
    'const Map<String, String> lucideIcons = {',
]
for name in names:
    lines.append("  '%s': '%s'," % (name, icons[name]))
lines.append('};')
lines.append('')
lines.append('/// Every icon name in [lucideIcons], in alphabetical order.')
lines.append('const List<String> lucideIconNames = [')
for name in names:
    lines.append("  '%s'," % name)
lines.append('];')
lines.append('')

with io.open(OUT, 'w', encoding='utf-8', newline='\n') as fh:
    fh.write('\n'.join(lines))
print('icons', len(names))
