local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Util = require(Shared.Util)
local Domain = require(Shared.Domain).new(Config,Catalog,Util)
local World = require(script.Parent.WorldService).new()

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function remote(name)
    local r = Instance.new("RemoteEvent");r.Name = name;r.Parent = remotes;return r
end
local Action = remote("Action")
local Input = remote("FishingInput")
local FishingState = remote("FishingState")
local Snapshot = remote("Snapshot")
local Notice = remote("Notice")
local SaveStatus = remote("SaveStatus")
local OpenPanel = remote("OpenPanel")
remotes.Parent = ReplicatedStorage

local function tell(player,key) if player.Parent then Notice:FireClient(player,key) end end
local Store = require(script.Parent.ProfileStore).new(Domain,function(player,status)
    if player.Parent then SaveStatus:FireClient(player,status) end
end)
local function sync(player)
    local profile = Store.profiles[player]
    if not profile or not player.Parent then return end
    local data = Util.clone(profile.data)
    for _,item in pairs(data.items) do item.seed = nil end -- persisted server-only roll
    data.saveStatus = profile.status
    data.debugEnabled = RunService:IsStudio() and Config.StudioDebug
    data.serverTime = os.time()
    data.plotName = World.plots[player] and World.plots[player].Name
    Snapshot:FireClient(player,data)
    World:sync(player,profile.data)
end
local Fishing = require(script.Parent.FishingService).new(Store,Domain,FishingState,sync,tell)

local buckets = {}
local function allow(player,lane,rate,capacity)
    buckets[player] = buckets[player] or {}
    local now = os.clock()
    local b = buckets[player][lane] or {tokens=capacity,at=now}
    b.tokens = math.min(capacity,b.tokens+(now-b.at)*rate);b.at = now
    buckets[player][lane] = b
    if b.tokens < 1 then return false end
    b.tokens -= 1;return true
end
local function root(player)
    local character = player.Character
    local human = character and character:FindFirstChildOfClass("Humanoid")
    return human and human.Health>0 and character:FindFirstChild("HumanoidRootPart") or nil
end
local function near(player,position)
    local r = root(player)
    return r and (r.Position-position).Magnitude <= Config.StationRadius
end
local aquariumActions = {place=true,retrieve=true,upgrade=true}
local allowedActions = {place=true,retrieve=true,upgrade=true,sell=true,craft=true,equip=true,unequip=true}
local function hatch(player)
    local p = Store.profiles[player]
    if not p or p.closed or p.busy then return end
    local ready = false
    for _,item in pairs(p.data.items) do
        if item.kind=="egg" and item.location=="aquarium" and item.readyAt <= os.time() then ready=true;break end
    end
    if not ready then return end
    local ok = Store:transaction(player,function(data)
        local results = Domain.hatch(data,os.time())
        return #results>0,results
    end)
    if ok then sync(player);tell(player,"hatched") end
end

Input.OnServerEvent:Connect(function(player,action)
    if type(action) ~= "string" or #action > 20 or not allow(player,"input",22,30) then return end
    if action=="start" or action=="release" or action=="hold" or action=="stopHold" or action=="tap" or action=="cancel" then
        Fishing:input(player,action)
    end
end)
Action.OnServerEvent:Connect(function(player,action,id,option)
    if type(action)~="string" or #action>24 then return end
    if id~=nil and (type(id)~="string" or #id>64) then return end
    if option~=nil and (type(option)~="string" or #option>20) then return end
    if not allow(player,"action",2,5) then return end
    local p = Store.profiles[player]
    if not p or p.closed then tell(player,"notReady");return end
    if action=="sync" then sync(player);return end
    if action=="rod" then
        local r = root(player)
        if r then
            local t = player.Backpack:FindFirstChild("FilamentRod")
            if t then player.Character:FindFirstChildOfClass("Humanoid"):EquipTool(t) end
        end
        return
    end
    if action=="travel" then
        if not allow(player,"travel",.5,1) then return end
        local r = root(player)
        local plot = World.plots[player]
        if not r or not plot then return end
        local destinations = {dock=Vector3.new(0,5,23),aquarium=plot.Arrival.Position+Vector3.new(0,2,0),shop=Vector3.new(-28,5,52),craft=Vector3.new(28,5,52)}
        local destination = destinations[id]
        if destination then
            Fishing:cancel(player,true)
            FishingState:FireClient(player,{phase="Idle"})
            player.Character:PivotTo(CFrame.lookAt(destination,destination+Vector3.new(0,0,-1)))
        end
        return
    end
    if action=="debugPack" or action=="debugHatch" then
        if not RunService:IsStudio() or not Config.StudioDebug then return end
        local ok,reason = Store:transaction(player,function(data)
            if action=="debugPack" then
                if Util.count(data.items)+4>Config.InventoryLimit then return false,"full" end
                for _,species in ipairs({"silver","sunny","azure","tideEgg"}) do
                    Domain.grant(data,species,HttpService:GenerateGUID(false),Random.new():NextInteger(1,2147483646),os.time())
                end
                data.coins += 500
                data.feed.basic += 3;data.feed.premium += 3
            else
                for _,item in pairs(data.items) do
                    if item.kind=="egg" and item.location=="aquarium" then
                        local duration=item.readyAt-item.startedAt
                        item.readyAt=os.time();item.startedAt=item.readyAt-duration
                    end
                end
            end
            return true,"debugDone"
        end)
        if ok then sync(player) end;tell(player,reason);return
    end
    if not allowedActions[action] then return end
    if Fishing.sessions[player] then tell(player,"finishFishing");return end
    if not root(player) then tell(player,"notReady");return end
    if aquariumActions[action] then
        local plot = World.plots[player]
        if not plot or not near(player,plot.Anchor.Position) then tell(player,"goAquarium");return end
    elseif action=="sell" and not near(player,World.world.Shop.Position) then tell(player,"goShop");return
    elseif action=="craft" and not near(player,World.world.Craft.Position) then tell(player,"goCraft");return end
    local ok,reason = Store:transaction(player,function(data) return Domain.apply(data,action,id,option,os.time()) end)
    if ok then sync(player) end
    tell(player,reason)
end)

for _,pair in ipairs({{World.world.Shop,"fish"},{World.world.Craft,"fish"}}) do
    pair[1].Prompt.Triggered:Connect(function(player)
        if near(player,pair[1].Position) then OpenPanel:FireClient(player,pair[2]) end
    end)
end
for _,plot in ipairs(World.world.Aquariums:GetChildren()) do
    local prompt=Instance.new("ProximityPrompt")
    prompt.ActionText="수족관 / Aquarium";prompt.ObjectText="FILAMENT";prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=14
    prompt.Parent=plot.UpgradeConsole
    prompt.Triggered:Connect(function(player)
        if World.plots[player]==plot and near(player,plot.Anchor.Position) then OpenPanel:FireClient(player,"tank") end
    end)
end
local function joined(player)
    if not World:assign(player) then player:Kick("FILAMENT PoC: 수족관 16개가 모두 사용 중입니다. / Server full.");return end
    local function characterAdded()
        Fishing:cancel(player,true)
        task.wait(.4)
        World:rod(player)
        local p=Store.profiles[player]
        if p then sync(player) end
    end
    player.CharacterAdded:Connect(characterAdded)
    if player.Character then task.spawn(characterAdded) end
    local p = Store:load(player)
    if p then
        if not player.Parent then Store:release(player);World:release(player);return end
        hatch(player)
        sync(player)
    end
end
Players.PlayerAdded:Connect(joined)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(joined,player) end
Players.PlayerRemoving:Connect(function(player)
    Fishing:cancel(player,true)
    Fishing.cooldowns[player]=nil
    buckets[player]=nil
    World:release(player)
    Store:release(player)
end)
task.spawn(function()
    while not Store.closing do
        task.wait(1)
        for player in pairs(Store.profiles) do
            task.spawn(function() hatch(player);Store:renew(player) end)
        end
    end
end)
game:BindToClose(function()
    Store.closing=true
    local count=0
    for player in pairs(Store.profiles) do
        count+=1
        task.spawn(function() Store:release(player);count-=1 end)
    end
    local deadline=os.clock()+25
    while count>0 and os.clock()<deadline do task.wait(.1) end
end)
print("[FILAMENT] Fishing PoC "..Config.Version.." ready. Mode: "..(Store.memory and "STUDIO MEMORY" or "DATASTORE"))
