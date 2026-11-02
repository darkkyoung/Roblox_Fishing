"""FILAMENT 0.1.1: an original, deterministic lakeside village built from primitives.
Geometry is embedded by Rojo; no marketplace dependencies or runtime downloads.
"""
import json, math, random
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
rng=random.Random(1101)
C={'grass':(111,152,100),'sand':(208,189,145),'path':(224,206,165),'wood':(135,94,64),'trim':(83,64,47),'teal':(48,111,112),'orange':(220,134,65),'cream':(242,225,185),'rock':(128,145,137)}
def part(name,pos,size,color,**props):
 p={'Anchored':True,'Position':pos,'Size':size,'Color':[v/255 for v in color],'TopSurface':'Smooth','BottomSurface':'Smooth'}
 p.update(props)
 return {'ClassName':'Part','Name':name,'Properties':p}
def model(name,children,cls='Model'):return {'ClassName':cls,'Name':name,'Children':children}
def sign(name,text,pos,size=(12,3.5,.35),color=None):
 p=part(name,pos,list(size),color or C['teal'],CanCollide=False,Material='Wood')
 p['Children']=[{'ClassName':'SurfaceGui','Name':'Label','Properties':{'Face':'Back','PixelsPerStud':36},'Children':[{'ClassName':'TextLabel','Name':'Text','Properties':{'Size':{'UDim2':[[1,0],[1,0]]},'BackgroundTransparency':1,'Text':text,'TextScaled':True,'TextColor3':[.97,.94,.81],'Font':'GothamBold','TextWrapped':True}}]}]
 return p
def cylinder(name,pos,size,color,**props):return part(name,pos,size,color,Shape='Cylinder',Orientation=[0,0,90],**props)
def lamp(x,z,y=0):
 p=part('Lantern',[x,y+6,z],[.8,1.2,.8],(255,218,142),Material='Neon',CanCollide=False)
 p['Children']=[{'ClassName':'PointLight','Properties':{'Color':[1,.78,.48],'Brightness':.55,'Range':14,'Shadows':False}}]
 return model('Lamp',[part('Post',[x,y+3,z],[.3,6,.3],C['trim'],Material='Wood'),p,part('Cap',[x,y+6.8,z],[1.3,.2,1.3],C['teal'])])
def planter(x,z,scale=1):
 return model('Planter',[part('Terracotta',[x,.6*scale,z],[2*scale,1.2*scale,2*scale],(177,108,72),Material='Brick'),part('Leaves',[x,1.6*scale,z],[2.2*scale,1.7*scale,2.2*scale],(74,129,87),Shape='Ball',CanCollide=False)])
def tree(x,z,s=1):
 leaves=[]
 for k,(dx,dy,dz,size) in enumerate([(-2,8,0,6),(1.8,9,1,6),(0,12,0,6),(-.6,10,-2.5,5)]):
  leaves.append(part('Crown',[x+dx*s,dy*s,z+dz*s],[size*s,size*s*.82,size*s],[(71,122,77),(88,139,84),(111,155,91)][k%3],Orientation=[0,k*29,0],CanCollide=False,Material='Grass'))
 return model('Tree',[part('Trunk',[x,4*s,z],[1.15*s,8*s,1.15*s],C['wood'],Material='Wood'),*leaves])
def rock(x,z,s=1,y=0):return part('ShoreRock',[x,y+1.1*s,z],[3.4*s,2.5*s,2.7*s],C['rock'],Orientation=[rng.randrange(-15,16),rng.randrange(180),rng.randrange(-12,13)],Material='Slate')
def fence(x,z,length,axis='x'):
 pieces=[]
 for delta in [-length/2,length/2]:pieces.append(part('Post',[x+(delta if axis=='x' else 0),1.6,z+(delta if axis=='z' else 0)],[.5,3.2,.5],C['wood'],Material='Wood'))
 for y in [1.1,2.3]:pieces.append(part('Rail',[x,y,z],[length,.25,.25] if axis=='x' else [.25,.25,length],C['wood'],Material='Wood'))
 return model('Fence',pieces)
world=[]
# Layered island body; grass banks and shoreline overlap the edges of the lake rectangle.
world += [part('LakeBed',[0,-5.5,-1],[114,4,88],C['sand'],Material='Sand'),part('VillageGround',[0,-2,102],[142,4,138],C['grass'],Material='Grass'),part('WestBank',[-68,-2,-2],[30,4,92],C['grass'],Material='Grass'),part('EastBank',[68,-2,-2],[30,4,92],C['grass'],Material='Grass'),part('NorthBank',[0,-2,-53],[142,4,26],C['grass'],Material='Grass')]
world.append(part('WaterPreview',[0,0,-1],[104,.25,80],(59,159,169),Transparency=.35,CanCollide=False,Material='Glass'))
shore=[]
for x,z,sx,sz in [(-47,-32,25,22),(45,-33,30,20),(-52,-8,14,32),(51,10,13,25),(-41,34,32,13),(38,34,32,12),(-15,-41,32,13),(22,-41,40,13)]:
 shore.extend([part('SandShelf',[x,-.6,z],[sx,2.4,sz],C['sand'],Shape='Ball',Material='Sand'),part('GrassShelf',[x+(-2 if x<0 else 2),-.2,z],[sx*.78,2.4,sz*.8],C['grass'],Shape='Ball',Material='Grass')])
for x,z in [(-45,-28),(46,-25),(-51,7),(49,22),(-33,36),(32,36),(-27,-39),(14,-40)]:shore.append(rock(x,z,rng.uniform(.8,1.4)))
world.append(model('SculptedShore',shore))
# Clear sightline: spawn -> paving -> timber pier, with no billboard across the view.
paths=[part('CentralWalk',[0,.08,53],[12,.25,30],C['path'],Material='Sandstone'),part('MarketWalk',[-24,.09,61],[42,.26,8],C['path'],Material='Sandstone'),part('WorkshopWalk',[24,.09,61],[42,.26,8],C['path'],Material='Sandstone'),part('GalleryWalk',[0,.09,116],[10,.26,100],C['path'],Material='Sandstone')]
for z in range(41,69,5):
 paths.extend([part('EdgeStone',[-6.3,.28,z],[.55,.6,3],C['rock'],Material='Cobblestone'),part('EdgeStone',[6.3,.28,z],[.55,.6,3],C['rock'],Material='Cobblestone')])
world.append(model('Paths',paths))
pier=[]
for z in range(5,42,2):pier.append(part('DeckPlank',[0,1.15,z],[10.6,.6,1.92],(143+(z%3)*5,107,75),Material='WoodPlanks'))
for x in [-4.5,4.5]:pier.append(part('Underbeam',[x,.3,23],[.6,1.1,38],C['trim'],Material='Wood'))
for z in [7,15,23,31,39]:
 for x in [-5.2,5.2]:
  pier.extend([cylinder('PierPost',[x,.6,z],[5,.65,.65],C['wood'],Material='Wood'),cylinder('RopeWrap',[x,2.4,z],[.18,.82,.82],(206,183,133))])
# Rail behind the angler only: the cast area stays visually and physically open.
pier.extend([fence(-5.3,35,7,'z'),fence(5.3,35,7,'z'),lamp(-5.5,40),lamp(5.5,40)])
world.append(model('Pier',pier))
for i in range(3):world.append(part('PierStep',[0,.2+i*.3,43-i*.9],[10.8,.4,1.2],C['wood'],Material='Wood'))
spawn=part('Spawn',[0,.12,49],[5,.2,5],C['path'],Transparency=1,CanCollide=False)
spawn['ClassName']='SpawnLocation';spawn['Properties'].update(Neutral=True,Duration=0,Enabled=True)
world.append(spawn)
world.extend([sign('Welcome','FILAMENT\n물결 마을',[15,5,59],(12,3.4,.3)),sign('PierSign','낚시터  /  PIER',[-12,3.5,39],(11,2.6,.3)),sign('GallerySign','AQUARIUM GARDENS\n수족관 산책로',[0,9,70],(17,3,.4))])
for x in [-9,9]:world.append(part('GardenArchPost',[x,4.5,70],[.55,9,.55],C['wood'],Material='Wood'))
world.append(part('GardenArchBeam',[0,10.8,70],[21,.6,1.4],C['teal'],Material='Wood'))
# Recognizable shops with pitched roofs, awnings, counters and original prop silhouettes.
for name,x,title,accent in [('Shop',-29,'물고기 상점\nFISH MARKET',C['teal']),('Craft',29,'사료 공방\nFEED WORKSHOP',C['orange'])]:
 p=part(name,[x,2.5,53],[12,4.5,1],accent,Transparency=1,CanCollide=False)
 p['Children']=[{'ClassName':'ProximityPrompt','Name':'Prompt','Properties':{'ActionText':'열기 / Open','ObjectText':title.split('\n')[0],'HoldDuration':0,'MaxActivationDistance':11,'RequiresLineOfSight':False}}]
 world.append(p)
 house=[part('Foundation',[x,.35,44],[23,.7,20],(165,151,124),Material='Cobblestone'),part('Floor',[x,.8,44],[21,.5,18],C['wood'],Material='WoodPlanks'),part('BackWall',[x,5.4,36],[21,9,.6],C['cream'],Material='WoodPlanks')]
 for side in [-1,1]:
  house += [part('SideWall',[x+side*10.5,5.4,44],[.6,9,16],C['cream'],Material='WoodPlanks'),part('CornerTimber',[x+side*10,5.4,52],[.6,9,.6],C['trim'],Material='Wood'),part('Roof',[x+side*5.7,12,44],[12.7,.8,21],accent,Orientation=[0,0,-side*23],Material='WoodPlanks'),part('RoofEdge',[x+side*5.7,12.6,54.5],[12.7,.4,.45],C['trim'],Orientation=[0,0,-side*23],Material='Wood')]
 house += [part('Ridge',[x,14.5,44],[.6,.5,22],C['trim'],Material='Wood'),part('Counter',[x,2.5,51],[16,3.5,2.6],C['wood'],Material='WoodPlanks'),part('CounterTop',[x,4.3,51],[17,.35,3.4],C['cream']),part('Awning',[x,8.7,54],[20,.5,6],accent,Orientation=[-12,0,0],Material='Fabric'),sign('ShopSign',title,[x,7,52.8],(14,3,.3),accent)]
 for dx in [-6,6]:house.append(part('BackWindow',[x+dx,6,36.4],[4,3,.2],(223,197,122),Material='Neon',CanCollide=False))
 for dx in [-8,-4,0,4,8]:house.append(part('AwningStripe',[x+dx,8.94,54],[1.8,.1,6],C['cream'],Orientation=[-12,0,0],Material='Fabric',CanCollide=False))
 house += [planter(x-12,53),planter(x+12,53),lamp(x-11,57)]
 for k in range(3):
  px=x-5+k*4
  # Each prop is authored here; no remote asset IDs.
  if name=='Shop':
   house.append(part('FishTray',[px,4.7,51],[3.2,.5,2],(100,131,133),Material='Wood'))
   house.append(part('DisplayFish',[px,5.1,51],[.65,.55,2],(133+20*k,178,185),Shape='Ball',CanCollide=False))
  else:
   house.append(part('FeedSack',[px,5.2,51],[2,2,1.6],(191,164,104),Shape='Ball',Material='Fabric'))
   house.append(part('SackBand',[px,5.2,51],[2.05,.4,1.65],accent,CanCollide=False))
 world.append(model(name+'Cottage',house))
# Four compact garden courts, 16 independent tanks. Central promenade remains open.
plots=[]
for i in range(16):
 x=[-46,-18,18,46][i%4];z=82+(i//4)*22
 pieces=[part('Platform',[x,.25,z],[24,.5,20],(213,204,172),Material='Sandstone'),part('Base',[x,1.05,z],[18,1.3,10],C['teal'],Material='WoodPlanks'),part('TankWater',[x,3.9,z],[16.6,4.3,8.5],(78,179,178),Transparency=.78,CanCollide=False,Material='Glass'),part('Sand',[x,1.78,z],[16.4,.3,8.2],C['sand'],Material='Sand')]
 for name,pos,size in [('Front',[x,4,z+5],[18,4.7,.15]),('Back',[x,4,z-5],[18,4.7,.15]),('Left',[x-9,4,z],[.15,4.7,10]),('Right',[x+9,4,z],[.15,4.7,10])]:
  pieces.append(part(name,pos,size,(189,226,216),Transparency=.88,Material='Glass',CastShadow=False))
 for dx in [-9,9]:
  pieces += [part('CornerFrame',[x+dx,4,z-5],[.25,5,.25],C['wood']),part('CornerFrame',[x+dx,4,z+5],[.25,5,.25],C['wood']),part('SideRim',[x+dx,6.4,z],[.3,.3,10.3],C['wood'])]
 for dz in [-5,5]:pieces.append(part('Rim',[x,6.4,z+dz],[18.3,.3,.3],C['wood']))
 pieces += [part('Anchor',[x,4,z],[1,1,1],C['cream'],Transparency=1,CanCollide=False),part('Arrival',[x,2,z+8],[1,1,1],C['cream'],Transparency=1,CanCollide=False),sign('OwnerSign',f'{i+1:02}  ·  VACANT',[x,7.7,z-5],(17,2.1,.25)),part('UpgradeConsole',[x+10.5,2.2,z+5],[1.6,3,1.8],C['orange'],Material='Wood'),planter(x-10.5,z+6,.65)]
 for j in range(2):
  pieces += [rock(x-6+j*11,z-2,.35,1.5),part('AquaticPlant',[x-5+j*10,2.3,z-3],[.4,1.3,.5],(92,151,100),Orientation=[0,0,j*12],CanCollide=False)]
 plots.append(model(f'Plot{i+1:02}',pieces))
world.append(model('Aquariums',plots,'Folder'))
for row in range(4):
 z=92+row*22
 world.append(part('CourtWalk',[0,.12,z],[124,.25,2.5],C['path'],Material='Sandstone'))
 world.extend([lamp(-6,z),lamp(6,z)])
for x in [-65,65]:
 for z in [73,104,135,164]:world.append(tree(x,z,.7));world.append(fence(x,z+11,14,'z'))
world.extend([fence(0,165,124),planter(-10,67,1.2),planter(10,67,1.2)])
# Depth, plants, lilies, reeds and soft hills form the lake's backdrop.
decor=[]
for x,z,s in [(-62,-31,1.2),(-65,-9,1),(-64,19,.9),(65,-26,1.3),(66,3,1),(63,27,.8),(-36,-51,1.2),(-12,-56,1.4),(17,-54,1.2),(42,-50,1.3),(-58,60,.8),(58,60,.8)]:decor.append(tree(x,z,s))
for x,z,sx,sy,sz in [(-74,-60,55,32,40),(-32,-76,70,43,55),(25,-79,65,35,48),(69,-60,45,28,38)]:
 decor.append(part('Hill',[x,sy*.2-4,z],[sx,sy,sz],(91,136,103),Shape='Ball',Material='Grass'))
for i in range(32):
 angle=2*math.pi*i/32;x=math.cos(angle)*53;z=math.sin(angle)*39-2
 if z>30 and abs(x)<38:continue
 decor.append(rock(x,z,rng.uniform(.35,.75)))
 for j in range(2):decor.append(part('Reed',[x+j*.5,.9,z+1],[.14,2.2,.14],(150,157,89),Orientation=[0,0,-9+j*16],Material='Grass',CanCollide=False))
for i in range(10):
 x=-38+i*7.5;z=-22-(i%3)*4
 decor.append(cylinder('LilyPad',[x,.15,z],[.12,2.2,2.2],(115,163,106),CanCollide=False))
 if i%3==0:decor.append(part('LilyFlower',[x,.5,z],[.6,.6,.6],(239,196,174),Shape='Ball',CanCollide=False))
for side in [-1,1]:
 for z in [59,64,69]:
  for k in range(3):
   x=side*(8+k*2)
   decor.append(part('FlowerStem',[x,.7,z],[.12,1.2,.12],(72,124,82),CanCollide=False))
   decor.append(part('Flower',[x,1.35,z],[.65,.5,.65],C['orange'] if k%2 else (241,222,160),Shape='Ball',CanCollide=False))
world.append(model('Nature',decor))
# Physical bounds below eye level; no accidental empty-map walk beyond the village.
for x in [-74,74]:world.append(part('Boundary',[x,2,95],[2,6,152],C['grass'],Transparency=1))
(ROOT/'src/world.model.json').write_text(json.dumps({'ClassName':'Model','Children':world},ensure_ascii=False,indent=2)+'\n')
def count(o):return 1+sum(count(c) for c in o.get('Children',[]))
print('Generated lakeside village:',sum(count(o) for o in world),'instances, 16 private tanks')
