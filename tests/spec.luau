local Config=require("../src/shared/Config")
local Catalog=require("../src/shared/Catalog")
local Util=require("../src/shared/Util")
local Domain=require("../src/shared/Domain").new(Config,Catalog,Util)
local Machine=require("../src/shared/FishingMachine").new(Config.Fishing)
local Lease=require("../src/server/Lease")
local Layout=require("../src/shared/Layout")
local Strings=require("../src/shared/Strings")
local passed=0
local function test(name,callback)
    local ok,err=pcall(callback)
    if not ok then error("FAIL "..name..": "..tostring(err)) end
    passed+=1;print("PASS "..name)
end
local function eq(actual,expected) assert(actual==expected,tostring(actual).." ~= "..tostring(expected)) end
local function fresh() return Domain.default() end
local function fish(data,id,species) assert(Domain.grant(data,species or "silver",id,100,1000)) end
local function egg(data,id,seed) assert(Domain.grant(data,"tideEgg",id,seed or 12345,1000)) end
test("All catch rewards reachable with configured 5% egg probability",function()
    local counts={}
    for i=0,9999 do local id=Util.roll(Config.CatchTable,(i+.5)/10000);counts[id]=(counts[id] or 0)+1 end
    eq(counts.silver,5500);eq(counts.sunny,2800);eq(counts.azure,1200);eq(counts.tideEgg,500)
end)
test("Unique item award cannot be replayed",function()
    local d=fresh();fish(d,"a");assert(not Domain.grant(d,"azure","a",1,1000));eq(Util.count(d.items),1);eq(d.items.a.species,"silver")
end)
test("Inventory bound prevents overflows",function()
    local d=fresh();for i=1,Config.InventoryLimit do fish(d,tostring(i)) end
    assert(not Domain.grant(d,"silver","overflow",1,1000));eq(Util.count(d.items),Config.InventoryLimit)
end)
test("Sell is exactly once and credits correct coins",function()
    local d=fresh();fish(d,"a","azure");assert(Domain.apply(d,"sell","a",nil,1000));eq(d.coins,180)
    assert(not Domain.apply(d,"sell","a",nil,1000));eq(d.coins,180);eq(d.items.a,nil)
end)
test("Placed fish cannot be sold or consumed until retrieved",function()
    local d=fresh();fish(d,"a");assert(Domain.apply(d,"place","a",nil,1000))
    assert(not Domain.apply(d,"sell","a",nil,1000));assert(not Domain.apply(d,"craft","a","basic",1000))
    assert(Domain.apply(d,"retrieve","a",nil,1000));assert(Domain.apply(d,"craft","a","basic",1000));eq(d.feed.basic,1)
    assert(not Domain.apply(d,"sell","a",nil,1000));eq(d.coins,100)
end)
test("Premium feed recipe consumes exactly one eligible fish",function()
    local d=fresh();fish(d,"a");assert(not Domain.apply(d,"craft","a","premium",1000));assert(d.items.a)
    fish(d,"b","azure");assert(Domain.apply(d,"craft","b","premium",1000));eq(d.feed.premium,2);eq(d.items.b,nil)
end)
test("Two profiles cannot operate each other's identifiers",function()
    local a,b=fresh(),fresh();fish(a,"ownerA")
    for _,action in ipairs({"place","retrieve","sell","craft","equip"}) do assert(not Domain.apply(b,action,"ownerA","basic",1000)) end
    eq(a.items.ownerA.location,"bag");eq(b.coins,100)
end)
test("Tank capacity and upgrades enforce costs and limits",function()
    local d=fresh();for i=1,5 do fish(d,tostring(i)) end
    for i=1,4 do assert(Domain.apply(d,"place",tostring(i),nil,1000)) end
    assert(not Domain.apply(d,"place","5",nil,1000));assert(Domain.apply(d,"upgrade",nil,nil,1000));eq(d.coins,0)
    assert(Domain.apply(d,"place","5",nil,1000));assert(not Domain.apply(d,"upgrade",nil,nil,1000))
    d.coins=250;assert(Domain.apply(d,"upgrade",nil,nil,1000));assert(not Domain.apply(d,"upgrade",nil,nil,1000));eq(d.aquariumLevel,3)
end)
test("Egg placement validates feed before consuming or starting",function()
    local d=fresh();egg(d,"e");assert(not Domain.apply(d,"place","e","premium",1000));eq(d.items.e.location,"bag")
    assert(not Domain.apply(d,"place","e","hacked",1000));d.feed.premium=1
    assert(Domain.apply(d,"place","e","premium",1000));eq(d.feed.premium,0);eq(d.items.e.readyAt,1040)
    assert(not Domain.apply(d,"place","e","premium",1001));assert(not Domain.apply(d,"retrieve","e",nil,1001))
end)
test("Unfed egg uses 60 seconds and hatch frees tank capacity",function()
    local d=fresh();egg(d,"e");assert(Domain.apply(d,"place","e","none",1000));eq(d.items.e.readyAt,1060)
    eq(#Domain.hatch(d,1059),0);eq(#Domain.hatch(d,1060),1);eq(Domain.occupied(d),0);eq(d.items.e.kind,"pet")
end)
test("Offline elapsed time hatches once without reroll on reconnect",function()
    local d=fresh();egg(d,"e");assert(Domain.apply(d,"place","e","none",1000))
    local saved=Util.clone(d);local retry=Util.clone(d)
    local result=Domain.hatch(saved,5000);eq(#result,1);eq(#Domain.hatch(saved,9000),0)
    eq(Domain.hatch(retry,9000)[1],result[1]);eq(saved.items.e.id,"e");eq(Util.count(saved.items),1)
end)
test("Higher feed and level improve both upper-rarity probabilities",function()
    local function chance(level,quality,index)
        local weights=Domain.weights(level,quality,Config.Feed[quality].duration);local sum=0
        for _,w in ipairs(weights) do sum+=w.weight end
        return weights[index].weight/sum
    end
    for _,index in ipairs({2,3}) do
        assert(chance(1,"none",index)<chance(1,"basic",index));assert(chance(1,"basic",index)<chance(1,"premium",index))
        assert(chance(1,"premium",index)<chance(2,"premium",index));assert(chance(2,"premium",index)<chance(3,"premium",index))
    end
    assert(chance(1,"basic",3)>0);assert(chance(1,"none",3)>0)
end)
test("Incubation time influences odds and placement snapshots level",function()
    assert(Domain.weights(1,"none",60)[3].weight>Domain.weights(1,"none",0)[3].weight)
    local d=fresh();egg(d,"e");Domain.apply(d,"place","e","none",1000);Domain.apply(d,"upgrade",nil,nil,1001)
    eq(d.items.e.incubationLevel,1);eq(d.aquariumLevel,2)
end)
test("All three pets reachable including legendary at level one",function()
    local observed={}
    for i=1,10000 do observed[Util.roll(Domain.weights(1,"none",60),i/10001)]=true end
    assert(observed.otter and observed.fox and observed.dragon)
end)
test("Only pets equip; one slot; buff reaches actual fishing simulation",function()
    local d=fresh();fish(d,"f");assert(not Domain.apply(d,"equip","f",nil,1000))
    assert(Domain.grant(d,"dragon","p",1,1000));assert(Domain.apply(d,"equip","p",nil,1000))
    local bite,reel=Domain.buffs(d);eq(bite,.65);eq(reel,1.25)
    local normal=Machine.begin(0,6,1);local boosted=Machine.begin(0,6*bite,reel)
    normal.phase="Reel";boosted.phase="Reel";normal.heldUntil=1;boosted.heldUntil=1
    Machine.step(normal,.1,.1);Machine.step(boosted,.1,.1)
    assert(boosted.progress>normal.progress);assert(boosted.waitSeconds<normal.waitSeconds)
    Domain.apply(d,"unequip",nil,nil,1000);eq(Domain.buffs(d),1)
end)
test("Server charge duration bounds power and waits for flight then bite",function()
    local s=Machine.begin(10,3,1);assert(Machine.input(s,"release",10.9));assert(math.abs(s.power-.5)<.0001)
    Machine.step(s,11.5,.1);eq(s.phase,"Flight");Machine.step(s,11.7,.1);eq(s.phase,"Waiting")
    Machine.step(s,14.6,.1);eq(s.phase,"Waiting");Machine.step(s,14.8,.1);eq(s.phase,"Reel")
end)
test("One resistance gate and valid taps allow full catch",function()
    local s=Machine.begin(0,0,1);s.phase="Reel"
    local now=0
    while s.phase=="Reel" do now+=.1;Machine.input(s,"hold",now);Machine.step(s,now,.1) end
    eq(s.phase,"Resist");eq(s.progress,Config.Fishing.ResistanceAt)
    for _=1,Config.Fishing.ResistanceTaps do now+=.1;Machine.input(s,"tap",now) end
    eq(s.phase,"Reel");assert(s.resisted)
    while s.phase=="Reel" do now+=.1;Machine.input(s,"hold",now);Machine.step(s,now,.1) end
    eq(s.phase,"Success");Machine.step(s,1000,1000);eq(s.phase,"Success")
end)
test("Late or spammed resistance taps cannot win",function()
    local s=Machine.begin(0,0,1);s.phase="Resist";s.deadline=4
    for _=1,100 do Machine.input(s,"tap",1) end;eq(s.taps,1)
    Machine.input(s,"tap",4);eq(s.taps,1);Machine.step(s,4,.1);eq(s.phase,"Failed")
end)
test("Hold expires, stalls cannot jump progress, stale sessions expire",function()
    local s=Machine.begin(0,0,1);s.phase="Reel";Machine.input(s,"hold",0)
    Machine.step(s,1,100);eq(s.progress,0)
    Machine.input(s,"hold",1);Machine.step(s,1.1,100);assert(s.progress<.03)
    Machine.step(s,46,.1);eq(s.phase,"Failed")
    local charge=Machine.begin(0,0,1);Machine.step(charge,9,.1);eq(charge.phase,"Failed")
end)
test("Lease prevents simultaneous owners and expired writers",function()
    local d=fresh();local record=Lease.acquire(nil,"A",100,180,d)
    eq(Lease.acquire(record,"B",110,180,d),nil)
    eq(Lease.write(record,"B",110,180,d,false),nil)
    eq(Lease.write(record,"A",281,180,d,false),nil)
    record=Lease.acquire(record,"B",281,180,d);eq(record.lock.token,"B")
    eq(Lease.write(record,"A",282,180,d,false),nil)
end)
test("Lease supports same-revision retries and rejects old revisions",function()
    local d=fresh();d.revision=2;local record=Lease.acquire(nil,"A",100,180,d)
    assert(Lease.write(record,"A",101,180,Util.clone(d),false));local stale=fresh()
    eq(Lease.write(record,"A",102,180,stale,false),nil)
    local released=Lease.write(record,"A",103,180,d,true);eq(released.lock,nil)
    assert(Lease.acquire(released,"B",104,180,d))
end)
test("Schema validation refuses future or malformed data",function()
    local d=fresh();assert(Domain.valid(d));d.schema=999;assert(not Domain.valid(d))
    d=fresh();d.coins=0/0;assert(not Domain.valid(d));d=fresh();d.equippedPet="missing";assert(not Domain.valid(d))
end)
test("Responsive containers fit portrait, landscape and desktop safe areas",function()
    for _,size in ipairs({{320,520},{375,730},{390,760},{768,320},{844,350},{1280,680},{1920,1000}}) do
        local m=Layout.metrics(size[1],size[2]);assert(m.panelWidth<=size[1]-24);assert(m.panelHeight<=size[2]-20)
        assert(m.fishWidth<=size[1]-24);assert(m.fishY+194<=size[2]);assert(m.cardWidth>250)
    end
end)
test("Korean and English catalogs have matching translation keys",function()
    for key in pairs(Strings.ko) do assert(Strings.en[key],key) end
    for key in pairs(Strings.en) do assert(Strings.ko[key],key) end
    for _,def in pairs(Catalog) do assert(Strings.ko[def.nameKey]) end
end)

-- Exercise the unmodified production ProfileStore with deterministic mocked APIs.
local function adapter(memory)
    local config=Util.clone(Config);config.StudioPersistence=not memory
    local backend={records={},calls=0,failBefore=0,failAfter=0}
    function backend:UpdateAsync(key,callback)
        self.calls+=1
        if self.failBefore>0 then self.failBefore-=1;error("simulated outage") end
        local result=callback(Util.clone(self.records[key]))
        if result==nil then return nil end
        self.records[key]=Util.clone(result)
        if self.failAfter>0 then self.failAfter-=1;error("simulated response lost after commit") end
        return Util.clone(result)
    end
    local ref={Config="Config",Util="Util"}
    local fakeGame={}
    function fakeGame:GetService(name)
        if name=="DataStoreService" then return {GetDataStore=function() return backend end}
        elseif name=="RunService" then return {IsStudio=function() return true end}
        elseif name=="HttpService" then return {GenerateGUID=function() return "session-A" end}
        else return {WaitForChild=function() return ref end} end
    end
    local deferred={}
    local fakeTask={wait=function() end,delay=function(_,fn) table.insert(deferred,fn) end}
    local module=loadProfileStore(fakeGame,{Parent={Lease="Lease"}},fakeTask,function() end,function(name)
        return ({Config=config,Util=Util,Lease=Lease})[name]
    end)
    local notifications={}
    local store=module.new(Domain,function(_,status) table.insert(notifications,status) end)
    local player={UserId=42,Parent=true,Kick=function(self,message) self.kicked=message end}
    return store,player,backend,notifications,deferred
end
test("Persistent profile commits before exposing data; reload restores inventory",function()
    local store,p,backend=adapter(false);assert(store:load(p))
    assert(store:transaction(p,function(d) fish(d,"persist");return true,"ok" end))
    eq(backend.records.player_42.data.items.persist.kind,"fish");eq(store.profiles[p].data.revision,1)
    store:release(p);eq(backend.records.player_42.lock,nil);assert(store:load(p));assert(store.profiles[p].data.items.persist)
end)
test("Transient failure retries; ambiguous commit does not duplicate reward",function()
    local store,p,backend=adapter(false);store:load(p);backend.failBefore=1;backend.failAfter=1
    assert(store:transaction(p,function(d) fish(d,"unique");return true,"ok" end))
    eq(Util.count(backend.records.player_42.data.items),1);eq(backend.records.player_42.data.revision,1);eq(backend.calls,4)
end)
test("Persistent failure freezes session without exposing unsaved candidate",function()
    local store,p,backend,notifications,deferred=adapter(false);store:load(p);backend.failBefore=10
    assert(not store:transaction(p,function(d) d.coins+=999;return true,"ok" end))
    eq(store.profiles[p].data.coins,100);assert(store.profiles[p].closed);eq(notifications[#notifications],"error")
    eq(backend.records.player_42.data.coins,100);deferred[1]();assert(p.kicked)
end)
test("Busy transactions reject concurrent item consumption",function()
    local store,p=adapter(true);store:load(p);store.profiles[p].busy=true
    local ok,reason=store:transaction(p,function() error("must not run") end)
    eq(ok,false);eq(reason,"busy")
end)
test("Studio temporary mode never accesses a cloud key",function()
    local store,p,backend=adapter(true);store:load(p)
    assert(store:transaction(p,function(d) fish(d,"a");return true,"ok" end))
    eq(backend.calls,0);eq(store.profiles[p].status,"memory")
end)
test("Offline hatch persists once across durable reconnects",function()
    local store,p,backend=adapter(false);store:load(p)
    assert(store:transaction(p,function(d) egg(d,"e");return Domain.apply(d,"place","e","none",1000) end))
    store:release(p);store:load(p)
    assert(store:transaction(p,function(d) local r=Domain.hatch(d,5000);return #r>0,r end))
    local species=backend.records.player_42.data.items.e.species
    store:release(p);store:load(p)
    eq(#Domain.hatch(store.profiles[p].data,9000),0);eq(store.profiles[p].data.items.e.species,species)
end)
print(string.format("\n%d tests passed. Luau logic + mocked storage; NOT Studio execution.",passed))
