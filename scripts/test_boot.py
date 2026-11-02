"""Execute production bootstrap against minimal injected API doubles, NOT Studio.
Floor transforms come from the built XML, not freshly generated runtime config.
"""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('place', ROOT/'scripts/validate_place.py')
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)
geometry = v.xml_geometry(ET.parse(ROOT/'build/FILAMENT-Fishing-0.2.rbxlx'))
lines = ['local floors={']
for path, entries in sorted(geometry.items()):
    if path.startswith('Workspace/World/Zones/') and path.endswith('/Floor'):
        _, frame, size = entries[0]
        lines.append('['+json.dumps(path.split('/')[-2])+']={position={'+','.join(map(str, frame[:3]))+'},size={'+','.join(map(str, size))+'}},')
lines.append('}')
wrappers = [
    ('loadZoneService', 'src/server/ZoneService.lua', 'game,workspace,Vector3,RaycastParams,Enum,require,print'),
    ('loadWorldService', 'src/server/WorldService.lua', 'game,script,workspace,Instance,require'),
    ('loadMain', 'src/server/Main.server.lua', 'game,script,workspace,Instance,require,task,print'),
]
for name, path, params in wrappers:
    lines.extend(['local function '+name+'('+params+')', (ROOT/path).read_text(), 'end'])
lines.append((ROOT/'tests/boot.spec.luau').read_text())
generated = ROOT/'tests/_boot_generated.luau'
try:
    generated.write_text('\n'.join(lines), encoding='utf-8')
    subprocess.run([os.environ.get('LUAU_BIN', 'luau'), str(generated)], cwd=ROOT, check=True)
finally:
    generated.unlink(missing_ok=True)
