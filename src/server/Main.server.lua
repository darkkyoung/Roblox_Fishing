local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Shared=ReplicatedStorage:WaitForChild("Shared")
local Config=require(Shared.Config)
local Util=require(Shared.Util)
local Domain=require(Shared.Domain).new(Config,require(Shared.Catalog),Util)
local Debug=require(script.Parent.StudioTools)
local Zones=require(script.Parent.ZoneService).new()
local World=require(script.Parent.WorldService).new(Zones)
local Rewards=require(script.Parent.RewardService).new(Domain,Config,Util)
assert(not ReplicatedStorage:FindFirstChild("Remotes"),"Duplicate FILAMENT server bootstrap")
local remotes=Instance.new("Folder");remotes.Name="Remotes"
local function remote(name) local r=Instance.new("RemoteEvent");r.Name=name;r.Parent=remotes;return r end
local Action=remote("Action");local Input=remote("FishingInput");local State=remote("FishingState")
local Snapshot=remote("Snapshot");local Notice=remote("Notice");local SaveStatus=remote("SaveStatus");local OpenPanel=remote("OpenPanel")
remotes.Parent=ReplicatedStorage
local function tell(player,key) if player.Parent then Notice:FireClient(player,key) end end
local Store=require(script.Parent.ProfileStore).new(Domain,function(player,status) if player.Parent then SaveStatus:FireClient(player,status) end end)
local counters={}
local function sync(player)
    local p=Store.profiles[player];if not p or not player.Parent then return end
    local data=Util.clone(p.data)
    for _,item in pairs(data.items) do item.seed=nil;item.ownerUserId=player.UserId end
    data.plotId=World.plots[player];data.saveStatus=p.status;data.serverTime=os.time()
    data.debugEnabled=Debug.enabled(RunService:IsStudio(),Config.StudioDebug);data.sessionStats=counters[player] or {catches=0,debug=0}
    Snapshot:FireClient(player,data);World:sync(player,p.data)
end
local Fishing=require(script.Parent.FishingService).new(Store,Domain,Rewards,Zones,State,function(player)
    if counters[player] then counters[player].catches+=1 end
    sync(player)
end,tell)
local buckets={}
local function allow(player,lane,rate,capacity)
    buckets[player]=buckets[player] or {};local now=os.clock()
    local b=buckets[player][lane] or {tokens=capacity,at=now}
    b.tokens=math.min(capacity,b.tokens+(now-b.at)*rate);b.at=now;buckets[player][lane]=b
    if b.tokens<1 then return false end;b.tokens-=1;return true
end
local function hatch(player)
    local p=Store.profiles[player];if not p or p.closed or p.busy then return end
    local ready=false
    for _,item in pairs(p.data.items) do if item.kind=="egg" and item.location=="aquarium" and item.readyAt<=os.time() then ready=true;break end end
    if not ready then return end
    local ok=Store:transaction(player,function(data) local results=Rewards.hatch(data,os.time());return #results>0,results end)
    if ok then sync(player);tell(player,"hatched") end
end
Input.OnServerEvent:Connect(function(player,action)
    if type(action)~="string" or #action>20 or not allow(player,"input",22,30) then return end
    if action=="start" or action=="release" or action=="hold" or action=="stopHold" or action=="tap" or action=="cancel" then Fishing:input(player,action) end
end)
Action.OnServerEvent:Connect(function(player,action,id,option)
    if type(action)~="string" or #action>24 or (id~=nil and (type(id)~="string" or #id>64)) or (option~=nil and (type(option)~="string" or #option>20)) then return end
    if not allow(player,"action",2,5) then return end
    local profile=Store.profiles[player];if not profile or profile.closed then tell(player,"notReady");return end
    if action=="sync" then sync(player);return end
    local position,root=Zones:position(player);if not root then tell(player,"notReady");return end
    if action=="rod" then
        local rod=player.Backpack:FindFirstChild(Zones.config.rodName)
        if rod then player.Character:FindFirstChildOfClass("Humanoid"):EquipTool(rod) end
        return
    end
    if action=="travel" then
        if not Debug.enabled(RunService:IsStudio(),Config.StudioDebug) or not allow(player,"travel",.5,1) then return end
        local destination=id=="aquarium" and World.plots[player] or id
        local permitted={SpawnPlaza=true,FishingDock=true,FishMarket=true,FeedWorkshop=true,AquariumGarden=true}
        if id~="aquarium" and not permitted[id] then return end
        local zone=Zones.config.zones[destination];if not zone then return end
        Fishing:cancel(player,true);State:FireClient(player,{phase="Idle"})
        local v=Vector3.new(unpack(zone.arrival));player.Character:PivotTo(CFrame.lookAt(v,v+Vector3.new(0,0,-1)))
        return
    end
    if string.sub(action,1,5)=="debug" then
        if not Debug.enabled(RunService:IsStudio(),Config.StudioDebug) then return end
        if Fishing:busy(player) then tell(player,"finishFishing");return end
        local ok,reason=Store:transaction(player,function(data)
            return Debug.apply(data,action,option,os.time(),Domain,function() return HttpService:GenerateGUID(false) end,
                function() return Random.new():NextInteger(1,2147483646) end,RunService:IsStudio(),Config.StudioDebug,Config.Aquarium)
        end)
        if ok then counters[player].debug+=1;sync(player);hatch(player) end
        tell(player,reason);return
    end
    if Fishing:busy(player) then tell(player,"finishFishing");return end
    local allowed,reason=Zones.rules.authorize(action,position,World.plots[player])
    if not allowed then tell(player,reason);return end
    local ok,result=Store:transaction(player,function(data) return Domain.apply(data,action,id,option,os.time()) end)
    if ok then sync(player) end;tell(player,result)
end)
for id,zone in pairs(Zones.config.zones) do
    if zone.type=="market" or zone.type=="workshop" or zone.type=="plot" then
        Zones.world[id].Console.Prompt.Triggered:Connect(function(player)
            if not Store.profiles[player] or not allow(player,"prompt",2,3) then return end
            if zone.type=="plot" and World.plots[player]~=id then return end
            if not Zones.rules.interact(id,Zones:position(player)) then return end
            OpenPanel:FireClient(player,zone.type=="plot" and "tank" or "fish")
        end)
    end
end
local function joined(player)
    if counters[player] then return end
    counters[player]={catches=0,debug=0}
    if not World:assign(player) then player:Kick("FILAMENT: 16 plots are occupied.");return end
    local function characterAdded()
        Fishing:cancel(player,true);State:FireClient(player,{phase="Idle"})
        task.wait(.4);World:rod(player);sync(player)
    end
    player.CharacterAdded:Connect(characterAdded);if player.Character then task.spawn(characterAdded) end
    local profile=Store:load(player)
    if profile then
        if not player.Parent then Store:release(player);World:release(player);return end
        hatch(player);sync(player)
    end
end
Players.PlayerAdded:Connect(joined);for _,p in ipairs(Players:GetPlayers()) do task.spawn(joined,p) end
Players.PlayerRemoving:Connect(function(player)
    Fishing:cancel(player,true);Fishing.cooldowns[player]=nil;Fishing.pending[player]=nil
    buckets[player]=nil;counters[player]=nil;World:release(player);Store:release(player)
end)
task.spawn(function()
    while not Store.closing do
        task.wait(1)
        for player in pairs(Store.profiles) do task.spawn(function() hatch(player);Store:renew(player) end) end
    end
end)
game:BindToClose(function()
    Store.closing=true;local count=0
    for player in pairs(Store.profiles) do count+=1;task.spawn(function() Store:release(player);count-=1 end) end
    local deadline=os.clock()+25;while count>0 and os.clock()<deadline do task.wait(.1) end
end)
print("[FILAMENT] Functional Blockout "..Config.Version.." / "..(Store.memory and "STUDIO MEMORY" or "DATASTORE"))
