"""Generate asset-free, editable Rojo map. All geometry is included in the place."""
import json,pathlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
def part(name,pos,size,color,**extra):
 props=dict(Anchored=True,Position=pos,Size=size,Color=[c/255 for c in color],TopSurface='Smooth',BottomSurface='Smooth')
 props.update(extra)
 return {'ClassName':'Part','Name':name,'Properties':props}
def sign(name,text,pos,color=(24,55,64)):
 p=part(name,pos,[12,4,.4],color,CanCollide=False)
 p['Children']=[{'ClassName':'SurfaceGui','Name':'Label','Properties':{'Face':'Back','PixelsPerStud':45},'Children':[{'ClassName':'TextLabel','Name':'Text','Properties':{'Size':{'UDim2':[[1,0],[1,0]]},'BackgroundTransparency':1,'Text':text,'TextScaled':True,'TextColor3':[1,.96,.85],'Font':'GothamBold','TextWrapped':True}}]}]
 return p
children=[]
children += [part('LakeBed',[0,-6,0],[110,4,84],(194,174,130)),part('Plaza',[0,-2,116],[160,4,164],(99,154,112)),part('WestBank',[-68,-2,0],[28,4,84],(99,154,112)),part('EastBank',[68,-2,0],[28,4,84],(99,154,112)),part('NorthBank',[0,-2,-53],[160,4,22],(99,154,112))]
children += [part('WaterPreview',[0,0,0],[108,.3,82],(70,181,197),Transparency=.45,CanCollide=False,Material='Glass'),part('Promenade',[0,.1,45],[150,.3,14],(219,199,161)),part('Pier',[0,1.2,23],[10,1,38],(144,103,73),Material='WoodPlanks')]
for z in range(6,43,6):
 for x in [-5,5]:children.append(part('PierPost',[x,0,z],[.6,5,.6],(100,75,56),Material='Wood'))
spawn=part('Spawn',[0,.5,46],[6,1,6],(255,178,80),Transparency=.45)
spawn['ClassName']='SpawnLocation';spawn['Properties'].update(Neutral=True,Duration=0)
children.append(spawn)
children += [sign('Welcome','FILAMENT\nFISHING · PRIVATE PoC',[0,7,57]),sign('FishingSign','FISHING\n부두에서 낚시',[-12,4,35]),sign('AquariumSign','YOUR AQUARIUM\n개인 수족관',[0,7,65])]
for name,x,text,col in [('Shop',-28,'FISH MARKET\n물고기 판매',(255,166,98)),('Craft',28,'FEED WORKSHOP\n사료 제작',(167,155,227))]:
 st=part(name,[x,2,44],[10,4,7],col,Material='WoodPlanks')
 st['Children']=[{'ClassName':'ProximityPrompt','Name':'Prompt','Properties':{'ActionText':'열기 / Open','ObjectText':text.split('\n')[0],'HoldDuration':0,'MaxActivationDistance':14,'RequiresLineOfSight':False}}]
 children.extend([st,part(name+'Roof',[x,5,44],[13,1,10],(35,78,83)),sign(name+'Sign',text,[x,7.7,48])])
plots=[]
for i in range(16):
 x=-54+(i%4)*36;z=83+(i//4)*32
 pieces=[part('Platform',[x,.25,z],[30,.5,27],(220,210,180)),part('Base',[x,1,z],[22,1,12],(33,69,75)),part('TankWater',[x,4.1,z],[20,5,10],(81,191,200),Transparency=.68,CanCollide=False,Material='Glass')]
 for suffix,pos,size in [('Front',[x,4,z+6],[22,6,.25]),('Back',[x,4,z-6],[22,6,.25]),('Left',[x-11,4,z],[.25,6,12]),('Right',[x+11,4,z],[.25,6,12])]:
  pieces.append(part(suffix,pos,size,(174,231,234),Transparency=.8,Material='Glass'))
 pieces += [part('Anchor',[x,4,z],[1,1,1],(255,255,255),Transparency=1,CanCollide=False),part('Arrival',[x,2,z+11],[1,1,1],(255,255,255),Transparency=1,CanCollide=False),sign('OwnerSign','VACANT',[x,8,z-6]),part('UpgradeConsole',[x+13,2,z+6],[2,3,3],(255,178,80))]
 plots.append({'ClassName':'Model','Name':f'Plot{i+1:02}','Children':pieces})
children.append({'ClassName':'Folder','Name':'Aquariums','Children':plots})
for i,(x,z) in enumerate([(-60,-45),(-37,-51),(-10,-50),(20,-51),(50,-45),(-73,35),(73,32),(-75,105),(75,138),(-75,170),(75,175)]):
 children.append(part('Trunk'+str(i),[x,4,z],[2,8,2],(118,88,63),Material='Wood'))
 children.append(part('Canopy'+str(i),[x,10,z],[10,10,10],(55+(i%3)*10,119+(i%2)*15,88),Shape='Ball',Material='Grass'))
for i in range(7):children.append(part('Lily'+str(i),[-32+i*9,.4,-22-(i%2)*6],[3,.15,3],(105,153,92),Shape='Cylinder',Orientation=[0,0,90],CanCollide=False))
(ROOT/'src/world.model.json').write_text(json.dumps({'ClassName':'Model','Children':children},ensure_ascii=False,indent=2))
print('World generated:',len(children),'top-level objects, 16 aquarium plots')
