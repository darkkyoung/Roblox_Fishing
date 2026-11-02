"""Validate baked transforms in JSON, XML AND the decoded binary place.
This is serialization/structure validation, not Roblox execution or physics.
Requires Python 3, rbxmk 0.9.1 (RBXMK_BIN may override its executable path).
"""
from collections import Counter, defaultdict
from pathlib import Path
import argparse
import hashlib
import json
import math
import os
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
IDENTITY = [1, 0, 0, 0, 1, 0, 0, 0, 1]
COMPONENTS = ['X', 'Y', 'Z', 'R00', 'R01', 'R02', 'R10', 'R11', 'R12', 'R20', 'R21', 'R22']
BASE_PARTS = {'Part', 'SpawnLocation', 'MeshPart', 'WedgePart', 'CornerWedgePart', 'TrussPart', 'UnionOperation', 'Seat', 'VehicleSeat'}
TOLERANCE = 1e-4  # Binary Vector3/CFrame values are float32.


def prop(item, name):
    return item.find(f'Properties/*[@name="{name}"]')


def name(item):
    value = prop(item, 'Name')
    return value.text if value is not None else ''


def close(actual, expected):
    return len(actual) == len(expected) and all(math.isfinite(a) and abs(a-b) <= TOLERANCE for a, b in zip(actual, expected))


def expected_geometry(config):
    """Independent specification from config, not from the generated model.
    Guard/sign/spawn formulas intentionally repeat the geometry contract so a
    generator regression cannot bless its own output. Duplicate Boundary names
    are compared as a multiset of transforms, not by serialization order.
    """
    result = defaultdict(list)

    def add(path, position, size, kind='Part'):
        result['Workspace/World/' + path].append((kind, [*position, *IDENTITY], size))

    add('Ground', config['ground']['position'], config['ground']['size'])
    zones = {z['id']: z for z in config['zones']}
    plots = config['plots']
    for row, z in enumerate(plots['rows']):
        for col, x in enumerate(plots['columns']):
            zones[f'AquariumPlot{row*4+col+1:02}'] = {'type': 'plot', 'position': [x, plots['y'], z], 'size': plots['size']}
    for zone_id, zone in zones.items():
        x, y, z = zone['position']
        sx, sy, sz = zone['size']
        base = 'Zones/' + zone_id + '/'
        add(base + 'Floor', zone['position'], zone['size'])
        if zone['type'] == 'spawn':
            add(base + 'Spawn', [x, y+sy/2+.1, z], [4, .2, 4], 'SpawnLocation')
        if zone['type'] != 'lake':
            side = zone['type'] in ('dock', 'spawn')
            plot = zone['type'] == 'plot'
            add(base + ('OwnerSign' if plot else 'Sign'), [x+sx/2+8 if side else x, 5, z if side else z-sz/2+1], [22 if plot else 20, 3, .25])
        if zone['type'] in ('plot', 'market', 'workshop'):
            add(base + 'Console', [x, 2.4, z+6] if zone['type'] == 'plot' else [x, y+sy/2+1.5, z], [2, 2, 2])
    for path in config['paths']:
        add('Paths/'+path['id'], path['position'], path['size'])
    lake, dock = zones['FishingLake'], zones['FishingDock']
    lx, _, lz = lake['position']; lw, _, ld = lake['size']
    dx, _, dz = dock['position']; dw, _, dd = dock['size']
    west, east = lx-lw/2, lx+lw/2
    north, south = lz-ld/2, lz+ld/2
    left, right, front = dx-dw/2, dx+dw/2, dz-dd/2
    for i, (x1, x2, z1, z2) in enumerate([(west, left, north, south), (right, east, north, south), (left, right, north, front)], 1):
        add('LakeSafety/LakeGuard'+str(i), [(x1+x2)/2, 8, (z1+z2)/2], [x2-x1, 16, z2-z1])
    for x in [-107, 107]:
        add('Boundary', [x, 8, -24], [1, 18, 244])
    for z in [-145.5, 97.5]:
        add('Boundary', [0, 8, z], [216, 18, 1])
    assert len(zones) == 22 and sum(map(len, result.values())) == 75
    return dict(result)


def model_geometry(world):
    result = defaultdict(list)

    def walk(item, path):
        if item['ClassName'] in BASE_PARTS:
            p = item['Properties']
            assert 'Position' not in p, f'{path}: forbidden serialized Position; use CFrame'
            assert isinstance(p.get('CFrame'), list) and len(p['CFrame']) == 12, f'{path}: missing 12-component CFrame'
            result[path].append((item['ClassName'], p['CFrame'], p['Size']))
        for child in item.get('Children', []):
            walk(child, path+'/'+child['Name'])

    walk(world, 'Workspace/World')
    return dict(result)


def xml_geometry(tree):
    result = defaultdict(list)

    def walk(item, path):
        if item.get('class') in BASE_PARTS:
            assert not any(p.get('name', '').lower() == 'position' for p in item.find('Properties')), f'{path}: forbidden serialized Position; use CFrame'
            frames = item.findall('Properties/CoordinateFrame[@name="CFrame"]')
            assert len(frames) == 1, f'{path}: expected exactly one CoordinateFrame/CFrame'
            frame = frames[0]
            assert Counter(c.tag for c in frame) == Counter(COMPONENTS), f'{path}: incomplete/duplicate CFrame components'
            values = [float(frame.find(k).text) for k in COMPONENTS]
            size = prop(item, 'Size')
            # rbxmk preserves the binary property spelling (size); Rojo XML uses Size.
            if size is None:
                size = prop(item, 'size')
            assert size is not None, f'{path}: missing Size'
            result[path].append((item.get('class'), values, [float(size.find(k).text) for k in ['X', 'Y', 'Z']]))
        for child in item.findall('Item'):
            walk(child, path+'/'+name(child))

    for item in tree.findall('./Item'):
        walk(item, name(item))
    return dict(result)


def compare_geometry(actual, expected, label):
    assert actual.keys() == expected.keys(), f'{label}: object paths differ: {actual.keys() ^ expected.keys()}'
    for path, expected_parts in expected.items():
        remaining = actual[path].copy()
        for kind, frame, size in expected_parts:
            index = next((i for i, value in enumerate(remaining) if value[0] == kind and close(value[1], frame) and close(value[2], size)), None)
            assert index is not None, f'{label}: {path}: expected {kind} CFrame={frame}, Size={size}; actual={remaining}'
            remaining.pop(index)
        assert not remaining, f'{label}: extra parts at {path}'


def validate_structure(tree, world, binary_sources=None):
    items = tree.findall('.//Item')
    classes = Counter(i.get('class') for i in items)
    assert classes['Part'] == 74 and classes['SpawnLocation'] == 1
    assert classes['Script'] == 1 and classes['LocalScript'] == 2, 'Duplicate/legacy bootstrap'
    assert not any(classes[c] for c in ['MeshPart', 'SpecialMesh', 'ViewportFrame', 'Atmosphere', 'ParticleEmitter', 'BloomEffect'])
    zones = next(i for i in items if i.get('class') == 'Folder' and name(i) == 'Zones').findall('Item')
    assert len(zones) == 22
    plots = [i for i in zones if name(i).startswith('AquariumPlot')]
    assert len(plots) == 16
    for plot in plots:
        assert {'Floor', 'OwnerSign', 'Console'} <= {name(c) for c in plot.findall('Item')}
    assert classes['ProximityPrompt'] == 18
    lake = next(i for i in zones if name(i) == 'FishingLake')
    floor = next(c for c in lake.findall('Item') if name(c) == 'Floor')
    collision = prop(floor, 'CanCollide')
    assert collision is None or collision.text == 'true'
    sources = list((ROOT/'src').rglob('*.lua'))
    scripts = [i for i in items if i.get('class') in ('Script', 'LocalScript', 'ModuleScript')]
    assert len(sources) == len(scripts)
    actual_sources = binary_sources if binary_sources is not None else [prop(i, 'Source').text for i in scripts]
    assert Counter(p.read_text(encoding='utf-8') for p in sources) == Counter(actual_sources), 'Embedded script sources differ'
    assert not any('Terrain:Fill' in p.read_text(encoding='utf-8') or 'ViewportFrame' in p.read_text(encoding='utf-8') for p in sources)
    safety = next(c for c in world['Children'] if c['Name'] == 'LakeSafety')['Children']
    assert len(safety) == 3
    for p in safety:
        assert p['Properties']['CanCollide'] and p['Properties']['Transparency'] == 1

    def inside(obj, x, z):
        p = obj['Properties']
        return abs(x-p['CFrame'][0]) < p['Size'][0]/2 and abs(z-p['CFrame'][2]) < p['Size'][2]/2

    for x in range(-47, 48, 2):
        for z in range(-44, 45, 2):
            if (abs(x) < 7 and z > 23) or abs(x) == 7:
                continue  # Collider seams require real physics QA.
            assert any(inside(b, x, z) for b in safety), (x, z)
    for z in [25, 35, 45, 53]:
        assert not any(inside(b, 0, z) for b in safety)
    return len(items), len(scripts)


def validate(xml_path, binary_path, rbxmk):
    config = json.loads((ROOT/'config/zones.json').read_text(encoding='utf-8'))
    world = json.loads((ROOT/'src/world.model.json').read_text(encoding='utf-8'))
    expected = expected_geometry(config)
    compare_geometry(model_geometry(world), expected, 'generated JSON')
    tree = ET.parse(xml_path)
    xml = xml_geometry(tree)
    compare_geometry(xml, expected, 'XML build')
    count, scripts = validate_structure(tree, world)
    # A separate implementation (rbxmk/rbxfile) reads the actual rbxl bytes.
    # Never substitute the original XML or regenerate a place to stand in for it.
    with tempfile.TemporaryDirectory(prefix='.place-validation-', dir=ROOT/'build') as temp:
        decoded = Path(temp)/'binary-decoded.rbxlx'
        subprocess.run([rbxmk, 'run', str(ROOT/'scripts/decode_place.lua'), str(binary_path.resolve()), str(decoded)], cwd=ROOT, check=True)
        binary_tree = ET.parse(decoded)
        binary = xml_geometry(binary_tree)
        compare_geometry(binary, expected, 'decoded RBXL')
        compare_geometry(binary, xml, 'RBXL vs RBXLX')
        validate_structure(binary_tree, world, json.loads(Path(str(decoded)+'.sources.json').read_text(encoding='utf-8')))
    print('PASS serialization: all 75 BaseParts have finite, identity-rotation CFrames; zero Position properties (JSON / RBXLX / decoded RBXL)')
    print('PASS original coordinates: 22 floors, 1 Spawn, 5 paths, 3 lake guards, 4 boundaries, 18 consoles, 21 signs, 1 ground')
    print('PASS AquariumPlot12.Floor serialized position = (76, 1.2, -113), tolerance 0.0001 studs')
    print(f'PASS structure: {count} instances, 22 zones, 16 plots, 18 prompts, {scripts} exact script sources in both builds')
    print('PASS single server bootstrap, two client scripts, flat-only geometry, lake safety coverage (structural)')
    for path in [binary_path, xml_path]:
        print(path.name+' SHA256: '+hashlib.sha256(path.read_bytes()).hexdigest())
    print('NOT RUN: Roblox Studio loading, server runtime, physics, HUD/input and multiplayer.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--xml', type=Path, default=ROOT/'build/FILAMENT-Fishing-0.2.rbxlx')
    parser.add_argument('--binary', type=Path, default=ROOT/'build/FILAMENT-Fishing-0.2.rbxl')
    parser.add_argument('--rbxmk', default=os.environ.get('RBXMK_BIN', 'rbxmk'))
    args = parser.parse_args()
    validate(args.xml, args.binary, args.rbxmk)
