"""Export the in-app enso mark to docs/brand/accrue-enso.svg.

Run from the repo root: python -I tool/export_brand.py
"""

import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
src = (root / "lib/widgets/brand_mark.dart").read_text(encoding="utf-8")
tail = src.split("const String ensoSvg =", 1)[1]
body = "".join(re.findall(r"'([^']*)'", tail))
body = body.replace('fill="#000"', 'fill="#C96442"')
out = root / "docs/brand/accrue-enso.svg"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(body, encoding="utf-8")
print(f"wrote {out} ({len(body)} bytes)")
