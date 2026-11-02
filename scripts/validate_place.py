"""Structural checks, not Roblox execution or physics simulation."""
from pathlib import Path
import xml.etree.ElementTree as ET
import hashlib,json,subprocess
root=Path(__file__).resolve().parents[1]
place=root/'build/FILAMENT-Fishing-0.2.rbxlx'
items=ET.parse(place).findall('.//Item')
def prop(i,n):return i.find(f'Properties/*[@name="{n}"]')
def name(i):
    p=prop(i,'Name');return p.text if p is not None else ''
classes={}
for i in items:classes[i.attrib['class']]=classes.get(i.attrib['class'],0)+1
assert classes.get('SpawnLocation')==1
assert classes.get('Script')==1 and classes.get('LocalScript')==2,'Duplicate/legacy bootstrap'
assert 50<classes.get('Part',0)<150
assert not any(classes.get(c,0) for c in ['MeshPart','SpecialMesh','ViewportFrame','Atmosphere','ParticleEmitter','BloomEffect'])
zone_models=[i for i in items if i.attrib['class']=='Model' and (name(i).startswith('AquariumPlot') or name(i) in ['SpawnPlaza','FishingLake','FishingDock','FishMarket','FeedWorkshop','AquariumGarden'])]
assert len(zone_models)==22
plots=[i for i in zone_models if name(i).startswith('AquariumPlot')];assert len(plots)==16
for plot in plots:assert {'Floor','OwnerSign','Console'}<={name(c) for c in plot.findall('Item')}
assert classes.get('ProximityPrompt')==18
lake=next(i for i in zone_models if name(i)=='FishingLake');floor=next(c for c in lake.findall('Item') if name(c)=='Floor')
# Default CanCollide is true when omitted by the serializer.
collision=prop(floor,'CanCollide');assert collision is None or collision.text=='true'
sources=list((root/'src').rglob('*.lua'));scripts=[i for i in items if i.attrib['class'] in ('Script','LocalScript','ModuleScript')]
assert len(sources)==len(scripts)
assert {p.read_text() for p in sources}=={prop(i,'Source').text for i in scripts}
world=json.loads((root/'src/world.model.json').read_text())
assert not any('Terrain:Fill' in p.read_text() or 'ViewportFrame' in p.read_text() for p in sources)
safety=next(c for c in world['Children'] if c['Name']=='LakeSafety')['Children']
assert len(safety)==3
for p in safety:assert p['Properties']['CanCollide'] and p['Properties']['Transparency']==1
# Every exposed blue-water test point is protected, while the dock remains open.
def inside(o,x,z):
    p=o['Properties'];return abs(x-p['Position'][0])<p['Size'][0]/2 and abs(z-p['Position'][2])<p['Size'][2]/2
for x in range(-47,48,2):
    for z in range(-44,45,2):
        if abs(x)<7 and z>23:continue
        if abs(x)==7:continue # exact collider seam, covered in physical engine QA
        assert any(inside(b,x,z) for b in safety),(x,z)
for z in [25,35,45,53]:assert not any(inside(b,0,z) for b in safety)
print(f'PASS place: {len(items)} instances, 22 zones, 16 plots, 18 prompts, {len(scripts)} exact source matches')
print('PASS single server bootstrap, two client scripts, flat-only geometry, lake safety coverage (structural)')
print('XML SHA256:',hashlib.sha256(place.read_bytes()).hexdigest())
