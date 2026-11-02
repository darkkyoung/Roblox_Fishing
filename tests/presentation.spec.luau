local P=require("../src/shared/Presentation")
local L=require("../src/shared/Layout")
local V=require("../src/shared/VisualConfig")
local Config=require("../src/shared/Config")
local count=0
local function test(name,fn)
    fn();count+=1;print("PASS "..name)
end
test("Idle has no meter, result or waiting panel",function()
    local v=P.view("Idle",true,true,false,false)
    assert(v.hint and not v.gauge and not v.result and not v.waiting)
    assert(not P.view("Idle",false,true,false,false).hint)
end)
test("Flight and waiting preserve the center of the world",function()
    for _,phase in ipairs({"Flight","Waiting","Saving"}) do
        local v=P.view(phase,true,true,false,false)
        assert(not v.gauge and not v.action and v.waiting)
    end
end)
test("Charge, reel and resistance have context-specific meters",function()
    for _,phase in ipairs({"Charge","Reel","Resist"}) do assert(P.view(phase,true,true,false,false).gauge) end
end)
test("Completion clears gauge and enables only small result",function()
    for _,phase in ipairs({"Success","Failed"}) do
        local v=P.view(phase,true,true,false,false)
        assert(v.result and not v.gauge and not v.hint and not v.waiting and not v.action and not v.cancel)
    end
end)
test("Bag and native menu exclude all fishing overlays",function()
    for _,phase in ipairs({"Idle","Charge","Flight","Waiting","Reel","Resist","Success","Failed"}) do
        for _,flags in ipairs({{true,false},{false,true}}) do
            for _,visible in pairs(P.view(phase,true,true,flags[1],flags[2])) do assert(not visible) end
        end
    end
end)
test("Press intent cannot invent rewards or bypass resistance",function()
    assert(P.press("Idle",false)=="start");assert(P.press("Reel",false)=="hold");assert(P.press("Resist",false)=="tap")
    assert(P.press("Resist",true)==nil and P.press("Waiting",false)==nil and P.press("Saving",false)==nil)
end)
test("Debug travel requires BOTH Studio and explicit configuration",function()
    assert(P.canDebug(true,true))
    assert(not P.canDebug(false,true));assert(not P.canDebug(true,false));assert(not P.canDebug(false,false))
end)
test("Fish actions are contextual; placed fish cannot sell or craft",function()
    local fish={id="f",kind="fish",location="bag"}
    assert(#P.actions(fish,"bag",false)==0)
    assert(P.actions(fish,"shop",false)[1]=="sell")
    assert(#P.actions(fish,"craft",false)==2)
    assert(P.actions(fish,"aquarium",false)[1]=="place")
    fish.location="aquarium"
    assert(#P.actions(fish,"shop",false)==0 and #P.actions(fish,"craft",false)==0)
    assert(P.actions(fish,"aquarium",false)[1]=="retrieve")
end)
test("Incubating eggs have no consume/retrieve actions; pet slot stays exclusive",function()
    assert(#P.actions({kind="egg",id="e",location="aquarium"},"aquarium",false)==0)
    assert(P.actions({kind="pet",id="p",location="bag"},"bag","p")[1]=="unequip")
    assert(P.actions({kind="pet",id="q",location="bag"},"bag","p")[1]=="equip")
end)
test("Portrait navigation replaces the split pane instead of shrinking it",function()
    local portrait=L.metrics(375,730,true);local landscape=L.metrics(812,320,true)
    assert(not portrait.split and portrait.portrait)
    assert(landscape.split and landscape.compact)
    assert(portrait.detailWidth>landscape.detailWidth)
    assert(landscape.previewHeight<portrait.previewHeight)
end)
test("Touch action and central meter do not overlap",function()
    for _,size in ipairs({{320,520},{375,730},{390,760},{768,320},{844,350},{620,430}}) do
        local m=L.metrics(size[1],size[2],true)
        local gx=(size[1]-m.gaugeWidth)/2
        local overlap=gx<m.actionX+m.actionSize and gx+m.gaugeWidth>m.actionX and m.gaugeY<m.actionY+m.actionSize and m.gaugeY+m.gaugeHeight>m.actionY
        assert(not overlap)
    end
end)
test("Narrow topbar hides optional information and retains the bag",function()
    assert(L.hud(130).bagWidth==48 and not L.hud(130).coins and not L.hud(130).title)
    assert(L.hud(240).coins and not L.hud(240).title)
    assert(L.hud(700).title)
end)
test("Ten egg display slots are unique and contained in redesigned tanks",function()
    local slots={}
    for i=1,10 do
        local x=((i-1)%5-2)*2.8;local z=i>5 and -2 or 2
        local key=tostring(x)..":"..z;assert(not slots[key]);slots[key]=true
        assert(math.abs(x)+.8<8.3 and math.abs(z)+.8<4.25)
    end
    assert(V.World.SwimRadius[1]+1.2<8.3 and V.World.SwimRadius[3]+1.2<4.25)
end)
test("Revision keeps the established challenge and content balance",function()
    assert(Config.Fishing.ResistanceSeconds==4 and Config.Fishing.ResistanceTaps==9)
    assert(Config.CatchTable[4].weight==5 and Config.HatchSeconds==60)
    assert(#Config.Aquarium==3 and Config.Aquarium[3].capacity==10)
end)
print(string.format("%d presentation tests passed (not Studio rendering).",count))
