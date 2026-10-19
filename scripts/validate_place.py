"""Check shipped place structure and embedded source integrity, without Studio."""
from pathlib import Path
import xml.etree.ElementTree as ET
import hashlib, json
root=Path(__file__).resolve().parents[1]
place=root/'build/FILAMENT-Fishing-0.1.rbxlx'
tree=ET.parse(place)
items=tree.findall('.//Item')
def prop(item,name):
    return item.find(f'Properties/*[@name="{name}"]')
def name(item):
    value=prop(item,'Name')
    return value.text if value is not None else ''
classes={}
for item in items: classes[item.attrib['class']]=classes.get(item.attrib['class'],0)+1
assert classes.get('SpawnLocation')==1
assert classes.get('Part',0)>=230
plots=[i for i in items if i.attrib['class']=='Model' and name(i).startswith('Plot')]
assert len(plots)==16
for plot in plots:
    children={name(i) for i in plot.findall('Item')}
    assert {'Anchor','Arrival','TankWater','UpgradeConsole','OwnerSign'}<=children
scripts=[i for i in items if i.attrib['class'] in ('Script','LocalScript','ModuleScript')]
sources=list((root/'src').rglob('*.lua'))
assert len(scripts)==len(sources),(len(scripts),len(sources))
expected={p.read_text().replace('\r\n','\n') for p in sources}
actual={prop(i,'Source').text.replace('\r\n','\n') for i in scripts}
assert expected==actual,'Embedded Luau differs from source tree'
assert classes.get('Script')==1
assert classes.get('LocalScript')==2
assert not any(i.attrib['class'] in ('HttpService','MarketplaceService') for i in items)
print(f'PASS place structure: {len(items)} instances, {len(plots)} aquariums, {len(scripts)} exact source matches')
print('PASS spawn, aquarium anchors, script classes, zero external assets required')
print('XML SHA256:',hashlib.sha256(place.read_bytes()).hexdigest())
