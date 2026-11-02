-- Minimal test doubles verify boot wiring/logging; they DO NOT emulate Roblox.
local Config=require("../src/shared/Config")
local ZoneConfig=require("../src/shared/ZoneConfig")
local ZoneRules=require("../src/shared/Zones")
local Util=require("../src/shared/Util")
local Domain=require("../src/shared/Domain")
local Catalog=require("../src/shared/Catalog")
local StudioTools=require("../src/server/StudioTools")
local Registry=require("../src/server/PlotRegistry")
local passed=0
local function test(name,callback)
    callback();passed+=1;print("PASS "..name)
end
local function vector(x,y,z)
    return setmetatable({X=x,Y=y,Z=z},{__sub=function(a,b)
        return {Magnitude=math.sqrt((a.X-b.X)^2+(a.Y-b.Y)^2+(a.Z-b.Z)^2)}
    end,__tostring=function(a) return string.format("%g, %g, %g",a.X,a.Y,a.Z) end})
end
local function event()
    return {connections={},Connect=function(self,callback) table.insert(self.connections,callback) end}
end
local function runBoot(mutate)
    local objects={}
    local function object(class,name,parent)
        local o={ClassName=class,Name=name,Parent=parent,attributes={}}
        function o:FindFirstChild(child)
            for _,candidate in ipairs(objects) do if candidate.Parent==self and candidate.Name==child then return candidate end end
        end
        function o:WaitForChild(child) return self:FindFirstChild(child) end
        function o:GetFullName() return self.Parent and self.Parent:GetFullName().."."..self.Name or self.Name end
        function o:SetAttribute(key,value) self.attributes[key]=value end
        function o:GetAttribute(key) return self.attributes[key] end
        function o:IsA(kind) return kind==self.ClassName or (kind=="BasePart" and class=="Part") end
        if class=="RemoteEvent" then o.OnServerEvent=event() end
        table.insert(objects,o)
        if parent then parent[name]=o end
        return o
    end
    local workspace=object("Workspace","Workspace")
    local world=object("Model","World",workspace)
    local zones=object("Folder","Zones",world)
    for id,floor in pairs(floors) do
        local node=object("Model",id,zones)
        local part=object("Part","Floor",node)
        part.Position=vector(unpack(floor.position));part.Size=vector(unpack(floor.size))
        local zone=ZoneConfig.zones[id]
        if zone.type=="market" or zone.type=="workshop" or zone.type=="plot" then
            local console=object("Part","Console",node)
            local prompt=object("ProximityPrompt","Prompt",console);prompt.Triggered=event()
        end
    end
    if mutate then mutate(zones) end
    local replicated=object("ReplicatedStorage","ReplicatedStorage")
    local shared=object("Folder","Shared",replicated)
    local server=object("Folder","Server");local main=object("Script","Main",server)
    local modules={Config=Config,ZoneConfig=ZoneConfig,Zones=ZoneRules,Util=Util,Domain=Domain,Catalog=Catalog,StudioTools=StudioTools,PlotRegistry=Registry,Models={}}
    for key in pairs(modules) do shared[key]=key;server[key]=key end
    for _,key in ipairs({"ZoneService","WorldService","RewardService","ProfileStore","FishingService"}) do server[key]=key end
    local players={PlayerAdded=event(),PlayerRemoving=event(),GetPlayers=function() return {} end}
    local game={services={ReplicatedStorage=replicated,Players=players,RunService={},HttpService={}}}
    function game:GetService(key) return self.services[key] end
    function game:BindToClose(callback) self.close=callback end
    local instance={new=function(class) return object(class,class) end}
    local messages={}
    local function log(message) table.insert(messages,message) end
    local function import(key)
        if modules[key] then return modules[key] end
        if key=="ZoneService" then
            return loadZoneService(game,workspace,{new=vector},{new=function() return {} end},{RaycastFilterType={Include="Include"}},import,log)
        elseif key=="WorldService" then
            return loadWorldService(game,{Parent=server},workspace,instance,import)
        elseif key=="RewardService" or key=="FishingService" then return {new=function() return {} end}
        elseif key=="ProfileStore" then return {new=function() return {profiles={},memory=true} end}
        end
        error("Unexpected require: "..tostring(key))
    end
    -- Do not run spawned loops: scheduling/players/network/storage remain engine QA.
    local task={spawn=function() end}
    local ok,reason=pcall(loadMain,game,main,workspace,instance,import,task,log)
    return ok,tostring(reason),replicated,workspace,players,messages
end

test("Production boot accepts all 22 XML-loaded floor transforms and creates dependencies (API doubles)",function()
    local ok,reason,rs,world,players=runBoot()
    assert(ok,reason)
    assert(rs:GetAttribute("FilamentBootStatus")=="Ready")
    local remotes=rs:FindFirstChild("Remotes");assert(remotes)
    for _,key in ipairs({"Action","FishingInput","FishingState","Snapshot","Notice","SaveStatus","OpenPanel"}) do assert(remotes:FindFirstChild(key)) end
    assert(world:FindFirstChild("CollectionVisuals"))
    assert(#players.PlayerAdded.connections==1 and #players.PlayerRemoving.connections==1)
end)
test("Production boot reports AquariumPlot12 expected and actual transforms before exposing dependencies",function()
    local ok,reason,rs,world=runBoot(function(zones) zones.AquariumPlot12.Floor.Position=vector(0,0,0) end)
    assert(not ok and string.find(reason,"AquariumPlot12.Floor",1,true))
    assert(string.find(reason,"76, 1.2, -113",1,true) and string.find(reason,"loaded Position=(0, 0, 0)",1,true))
    assert(rs:GetAttribute("FilamentBootStatus")=="Failed" and rs:GetAttribute("FilamentBootStage")=="ZoneService")
    assert(not rs:FindFirstChild("Remotes") and not world:FindFirstChild("CollectionVisuals"))
end)
test("Missing baked floor fails immediately with full object path instead of waiting forever",function()
    local ok,reason,rs=runBoot(function(zones) zones.AquariumPlot12.Floor.Name="Missing" end)
    assert(not ok and string.find(reason,"Missing baked object: Workspace.World.Zones.AquariumPlot12.Floor",1,true))
    assert(rs:GetAttribute("FilamentBootStatus")=="Failed")
end)
print(passed.." boot wiring/diagnostic tests passed using API doubles; NOT Roblox Studio runtime.")
