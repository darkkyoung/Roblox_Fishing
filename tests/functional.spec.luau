local Config=require("../src/shared/Config")
local ZC=require("../src/shared/ZoneConfig")
local Zones=require("../src/shared/Zones").new(ZC)
local P=require("../src/shared/Presentation")
local L=require("../src/shared/Layout")
local Catalog=require("../src/shared/Catalog")
local Util=require("../src/shared/Util")
local D=require("../src/shared/Domain").new(Config,Catalog,Util)
local M=require("../src/shared/FishingMachine").new(Config.Fishing)
local R=require("../src/server/RewardService").new(D,Config,Util)
local Debug=require("../src/server/StudioTools")
local Registry=require("../src/server/PlotRegistry")
local n=0
local function test(name,fn) local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));n+=1;print("PASS "..name) end
local function at(id) return ZC.zones[id].arrival end
local function count(t) return Util.count(t) end
local function apply(data,action,id,option,p,plot,now)
    local ok,reason=Zones.authorize(action,p,plot)
    if not ok then return false,reason end
    return D.apply(data,action,id,option,now or 1000)
end
local function catch(unit,id,success)
    local s=M.begin(0,3,1);local now=1
    assert(M.input(s,"release",now));assert(Zones.castTarget(at("FishingDock"),s.power,Config.Fishing))
    now+=.71;M.step(s,now,.1);assert(s.phase=="Waiting")
    now+=3.1;M.step(s,now,.1);assert(s.phase=="Reel")
    while s.phase=="Reel" do now+=.1;M.input(s,"hold",now);M.step(s,now,.1) end
    assert(s.phase=="Resist")
    if not success then M.step(s,s.deadline,.1);assert(s.phase=="Failed");return nil end
    for _=1,9 do now+=.1;M.input(s,"tap",now) end
    while s.phase=="Reel" do now+=.1;M.input(s,"hold",now);M.step(s,now,.1) end
    assert(s.phase=="Success")
    return R.prepare(unit,id,164350,1000)
end
test("Geography: south spawn, southwest market, northwest workshop, north garden",function()
    local z=ZC.zones
    assert(z.SpawnPlaza.position[3]>z.FishingDock.position[3] and z.FishingDock.position[3]>z.FishingLake.position[3])
    assert(z.FishMarket.position[1]<0 and z.FishMarket.position[3]>0)
    assert(z.FeedWorkshop.position[1]<0 and z.FeedWorkshop.position[3]<0)
    assert(z.AquariumGarden.position[3]<-45)
end)
test("All 16 plot slots lie inside the separate garden",function()
    local plots=0
    for id,z in pairs(ZC.zones) do if z.type=="plot" then
        plots+=1
        for _,x in ipairs({-1,1}) do for _,zz in ipairs({-1,1}) do
            assert(Zones.contains("AquariumGarden",{z.position[1]+x*z.size[1]/2,z.position[2],z.position[3]+zz*z.size[3]/2}))
        end end
        assert(Zones.isPlot(id))
    end end
    assert(plots==16)
end)
test("Only dock permits casting, including height and malformed-position rejection",function()
    assert(Zones.canFish(at("FishingDock")))
    for id in pairs(ZC.zones) do if id~="FishingDock" then assert(not Zones.canFish(at(id)),id) end end
    for _,p in ipairs({{0,-30,39},{0,100,39},{8,4.5,39},{0,4.5,56},{0/0,4.5,39},{math.huge,4.5,39}}) do assert(not Zones.canFish(p)) end
    assert(not Zones.canFish(nil))
end)
test("All dock corners and casting powers land on exposed lake, never under dock",function()
    for _,x in ipairs({-7,0,7}) do for _,z in ipairs({23,39,55}) do for _,power in ipairs({-1,0,.5,1,2}) do
        local target=Zones.castTarget({x,4.5,z},power,Config.Fishing)
        assert(target and Zones.waterTarget(target));assert(not Zones.contains("FishingDock",target))
    end end end
    assert(Zones.castTarget(at("SpawnPlaza"),1,Config.Fishing)==nil)
    assert(Zones.castTarget(at("FishingDock"),0/0,Config.Fishing)==nil)
end)
test("Water check rejects dry ground, wrong elevation and dock overlap",function()
    for _,p in ipairs({{60,.85,0},{0,.85,39},{10,4,0},{10,-4,0},{10,.85,46}}) do assert(not Zones.waterTarget(p)) end
    assert(Zones.waterTarget({10,.85,0}))
end)
test("Station actions require correct zone bounds AND prompt distance",function()
    assert(Zones.authorize("sell",at("FishMarket"),"AquariumPlot01"))
    assert(Zones.authorize("craft",at("FeedWorkshop"),"AquariumPlot01"))
    assert(not Zones.authorize("sell",at("FeedWorkshop"),"AquariumPlot01"))
    assert(not Zones.authorize("craft",at("FishMarket"),"AquariumPlot01"))
    assert(not Zones.interact("FishMarket",{-74,100,43}))
    assert(not Zones.interact("FishMarket",{-59,4,43}))
    assert(not Zones.interact("FishMarket",{-87,4,53}))
end)
test("Player cannot place/retrieve/upgrade while standing on another plot",function()
    for _,action in ipairs({"place","retrieve","upgrade"}) do
        assert(Zones.authorize(action,at("AquariumPlot01"),"AquariumPlot01"))
        assert(not Zones.authorize(action,at("AquariumPlot02"),"AquariumPlot01"))
        assert(not Zones.authorize(action,at("AquariumPlot01"),nil))
    end
    assert(Zones.context(at("AquariumPlot02"),"AquariumPlot01")=="bag")
end)
test("16 distinct session allocations; 17th refused; leaving releases only own plot",function()
    local registry=Registry.new(ZC);local seen={}
    for i=1,16 do local id=registry:assign(i);assert(id and not seen[id]);seen[id]=true;assert(registry:assign(i)==id) end
    assert(registry:assign(17)==nil)
    local released=registry.plots[2];registry:release(2)
    assert(registry.plots[1]=="AquariumPlot01" and registry.owners[released]==nil)
    assert(registry:assign(17)==released and registry.owners[released]==17)
end)
test("Display slots are unique, bounded and independent between two owners",function()
    local seen={}
    for i=1,10 do local p=Zones.slot("AquariumPlot01",i);local key=table.concat(p,",")
        assert(not seen[key]);seen[key]=true;assert(Zones.contains("AquariumPlot01",p,2))
        assert(not Zones.contains("AquariumPlot02",p))
    end
end)
test("Integrated normal catch reaches each fish and egg reward without debug",function()
    local d=D.default()
    for i,entry in ipairs({{.1,"silver"},{.6,"sunny"},{.9,"azure"},{.99,"tideEgg"}}) do
        local reward=catch(entry[1],"normal"..i,true)
        assert(R.grant(d,reward));assert(d.items[reward.id].species==entry[2] and d.items[reward.id].source=="fishing")
    end
    assert(count(d.items)==4)
end)
test("Failed resistance produces no reward proposal",function() assert(catch(.99,"failed",false)==nil) end)
test("Same prepared reward cannot be granted twice",function()
    local d=D.default();local r=catch(.99,"once",true);assert(R.grant(d,r));assert(not R.grant(d,r));assert(count(d.items)==1)
end)
test("Integrated fish: capture, place, retrieve, sell; wrong zone and duplicate refused",function()
    local d=D.default();R.grant(d,catch(.1,"f",true))
    assert(not apply(d,"place","f",nil,at("SpawnPlaza"),"AquariumPlot01"))
    assert(apply(d,"place","f",nil,at("AquariumPlot01"),"AquariumPlot01"))
    assert(not apply(d,"sell","f",nil,at("FishMarket"),"AquariumPlot01"))
    assert(apply(d,"retrieve","f",nil,at("AquariumPlot01"),"AquariumPlot01"))
    assert(apply(d,"sell","f",nil,at("FishMarket"),"AquariumPlot01"));assert(d.coins==120 and not d.items.f)
    assert(not apply(d,"sell","f",nil,at("FishMarket"),"AquariumPlot01"))
end)
test("Integrated craft consumes exactly one fish at workshop",function()
    local d=D.default();R.grant(d,catch(.9,"f",true))
    assert(not apply(d,"craft","f","premium",at("FishMarket"),"AquariumPlot01"))
    assert(apply(d,"craft","f","premium",at("FeedWorkshop"),"AquariumPlot01"))
    assert(d.feed.premium==2 and not d.items.f)
    assert(not apply(d,"craft","f","premium",at("FeedWorkshop"),"AquariumPlot01"))
end)
test("Integrated egg, crafted feed, timed hatch, pet equip and actual fishing multipliers",function()
    local d=D.default();R.grant(d,catch(.9,"fish",true));R.grant(d,catch(.99,"egg",true))
    assert(apply(d,"craft","fish","premium",at("FeedWorkshop"),"AquariumPlot01"))
    assert(apply(d,"place","egg","premium",at("AquariumPlot01"),"AquariumPlot01",2000))
    assert(d.feed.premium==1 and d.items.egg.readyAt==2040 and #R.hatch(d,2039)==0)
    assert(#R.hatch(d,2040)==1 and d.items.egg.kind=="pet" and d.items.egg.source=="fishing")
    assert(#R.hatch(d,9999)==0 and count(d.items)==1)
    assert(apply(d,"equip","egg",nil,at("SpawnPlaza"),"AquariumPlot01"))
    local bite,reel=D.buffs(d);local s=M.begin(0,6*bite,reel)
    assert(s.waitSeconds<6 and s.reelMultiplier>1)
    assert(apply(d,"unequip",nil,nil,at("SpawnPlaza"),"AquariumPlot01"));assert(D.buffs(d)==1)
end)
test("Two profile inventories remain isolated even at permitted station",function()
    local a,b=D.default(),D.default();R.grant(a,catch(.1,"a-fish",true))
    assert(not apply(b,"sell","a-fish",nil,at("FishMarket"),"AquariumPlot02"))
    assert(not apply(b,"place","a-fish",nil,at("AquariumPlot02"),"AquariumPlot02"))
    assert(a.items['a-fish'].location=="bag" and b.coins==100)
end)
test("Upgrade uses own zone and unchanged cost/capacity",function()
    local d=D.default();assert(not apply(d,"upgrade",nil,nil,at("AquariumPlot02"),"AquariumPlot01"))
    assert(apply(d,"upgrade",nil,nil,at("AquariumPlot01"),"AquariumPlot01"));assert(d.coins==0 and Config.Aquarium[d.aquariumLevel].capacity==7)
end)
local serial=0
local function newid() serial+=1;return "debug-"..serial end
local function debug(d,action,option,studio,enabled) return Debug.apply(d,action,option,1000,D,newid,function() return 123 end,studio,enabled,Config.Aquarium) end
test("Every debug mutation is refused on live and with StudioDebug false",function()
    for _,action in ipairs({"debugFish","debugEgg","debugFeed","debugCoins","debugLevel","debugHatch"}) do
        local d=D.default();assert(not debug(d,action,"3",false,true));assert(not debug(d,action,"3",true,false))
        assert(d.coins==100 and count(d.items)==0 and d.aquariumLevel==1)
    end
    assert(not Debug.enabled(false,true) and Debug.enabled(true,true))
end)
test("Separate debug fish/egg/feed/coin controls have bounded exact grants",function()
    local d=D.default();assert(debug(d,"debugFish",nil,true,true));assert(count(d.items)==3)
    assert(debug(d,"debugEgg",nil,true,true));assert(count(d.items)==4)
    assert(debug(d,"debugFeed",nil,true,true));assert(d.feed.basic==3 and d.feed.premium==3)
    assert(debug(d,"debugCoins",nil,true,true));assert(d.coins==600)
    for _,item in pairs(d.items) do assert(item.source=="studioDebug") end
end)
test("Debug level rejects overflow, invalid input, and lowering below current occupancy",function()
    local d=D.default();assert(debug(d,"debugLevel","3",true,true))
    for i=1,5 do D.grant(d,"silver",tostring(i),1,1000);D.apply(d,"place",tostring(i),nil,1000) end
    assert(not debug(d,"debugLevel","1",true,true));assert(d.aquariumLevel==3)
    for _,v in ipairs({"0","4","1.5","nan","inf","abc"}) do assert(not debug(d,"debugLevel",v,true,true)) end
end)
test("Debug instant hatch preserves incubation weights and labels result as DEBUG",function()
    local d=D.default();R.grant(d,R.prepare(.99,"e",123,900));D.apply(d,"place","e","none",950)
    local duration=d.items.e.readyAt-d.items.e.startedAt
    assert(debug(d,"debugHatch",nil,true,true));assert(d.items.e.readyAt-d.items.e.startedAt==duration)
    assert(#R.hatch(d,1000)==1 and d.items.e.source=="studioDebug" and #R.hatch(d,2000)==0)
end)
test("Idle, waiting and finished states do not expose a fishing meter",function()
    for _,phase in ipairs({"Idle","Waiting","Flight","Saving","Success","Failed"}) do assert(not P.view(phase,true,true,false).meter) end
    for _,phase in ipairs({"Charge","Reel","Resist"}) do assert(P.view(phase,true,true,false).meter) end
end)
test("Bag/native menu excludes all fishing controls; absent rod has no idle action",function()
    for _,phase in ipairs({"Idle","Charge","Flight","Waiting","Reel","Resist","Success","Failed"}) do
        for _,value in pairs(P.view(phase,true,true,true)) do assert(not value) end
    end
    assert(not P.view("Idle",false,true,false).action and not P.view("Idle",true,false,false).action)
end)
test("Input intent cannot advance waiting or convert hold into repeated resistance taps",function()
    assert(P.intent("Idle",false)=="start" and P.intent("Reel",false)=="hold" and P.intent("Resist",false)=="tap")
    assert(P.intent("Resist",true)==nil and P.intent("Waiting",false)==nil and P.intent("Saving",false)==nil)
end)
test("UI exposes only zone-relevant actions and valid fish recipes",function()
    local f={id="f",kind="fish",species="silver",location="bag"}
    assert(#P.actions(f,"bag",false,Catalog)==0)
    assert(P.actions(f,"shop",false,Catalog)[1]=="sell")
    assert(#P.actions(f,"craft",false,Catalog)==1)
    f.species="sunny";assert(#P.actions(f,"craft",false,Catalog)==2)
    f.location="aquarium";assert(#P.actions(f,"shop",false,Catalog)==0 and P.actions(f,"aquarium",false,Catalog)[1]=="retrieve")
end)
test("Incubating eggs have no retrieve action and pet slot has equip/unequip only",function()
    assert(#P.actions({kind="egg",location="aquarium"},"aquarium",false,Catalog)==0)
    assert(P.actions({id="p",kind="pet"},"bag","p",Catalog)[1]=="unequip")
    assert(P.actions({id="q",kind="pet"},"bag","p",Catalog)[1]=="equip")
end)
test("Touch meter, action, cancel targets stay separated in portrait and landscape",function()
    local function overlaps(a,b) return a[1]<b[1]+b[3] and b[1]<a[1]+a[3] and a[2]<b[2]+b[4] and b[2]<a[2]+a[4] end
    for _,size in ipairs({{320,520},{390,760},{568,280},{768,320},{844,350},{1280,680}}) do
        local m=L.metrics(size[1],size[2],true)
        local gauge={(size[1]-m.meterWidth)/2,m.meterY,m.meterWidth,m.meterHeight}
        local action={m.actionX,m.actionY,m.actionW,m.actionH};local cancel={m.cancelX,m.actionY,44,44}
        assert(not overlaps(gauge,action) and not overlaps(gauge,cancel) and not overlaps(action,cancel))
        assert(m.actionW>=44 and m.actionH>=44 and m.meterY>=0)
    end
end)
test("Compact HUD stays within native topbar free space with an accessible bag",function()
    for _,width in ipairs({100,130,150,220,400,900}) do
        local h=L.hud(width)
        assert(h.bagX>=0 and h.bagX+h.bagWidth<=width and h.bagWidth>=44)
        if h.showCoins then assert(h.coinX>=0 and h.coinX+h.coinWidth<h.bagX) end
    end
end)
print(n.." functional integration / zone / presentation tests passed; NOT Studio execution.")
