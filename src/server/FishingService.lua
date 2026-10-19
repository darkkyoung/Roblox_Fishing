local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Machine = require(Shared.FishingMachine).new(Config.Fishing)
local Service = {}
Service.__index = Service
function Service.new(store, domain, remote, onReward, notify)
    local self = setmetatable({sessions = {}, cooldowns = {}, store = store, domain = domain, remote = remote, onReward = onReward, notify = notify, random = Random.new()},Service)
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < .08 then return end
        local step = elapsed
        elapsed = 0
        self:tick(step)
    end)
    return self
end
function Service:valid(player)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local human = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not human or human.Health <= 0 or not char:FindFirstChild("FilamentRod") then return false end
    local f = Config.Fishing
    return math.abs(root.Position.X-f.DockX) <= f.DockHalfX and math.abs(root.Position.Z-f.DockZ) <= f.DockHalfZ and root.Position.Y > 1 and root.Position.Y < 12
end
function Service:cancel(player, quiet)
    local s = self.sessions[player]
    if not s then return end
    self.sessions[player] = nil
    if s.bobber then s.bobber:Destroy() end
    if s.beam then s.beam:Destroy() end
    self.cooldowns[player] = os.clock()+Config.Fishing.Cooldown
    if not quiet and player.Parent then self.remote:FireClient(player,{phase="Failed"}) end
end
function Service:input(player,action)
    local now = os.clock()
    if action == "cancel" then self:cancel(player,false);return end
    local profile = self.store.profiles[player]
    if not profile or profile.closed then return end
    local s = self.sessions[player]
    if action == "start" then
        if s or profile.busy or now < (self.cooldowns[player] or 0) then return end
        if not self:valid(player) then self.notify(player,"goDock");return end
        if Util.count(profile.data.items) >= Config.InventoryLimit then self.notify(player,"full");return end
        local bite,reel = self.domain.buffs(profile.data)
        s = Machine.begin(now,self.random:NextNumber(Config.Fishing.BiteMin,Config.Fishing.BiteMax)*bite,reel)
        self.sessions[player] = s
        self.remote:FireClient(player,{phase="Charge",progress=0,power=0})
    elseif s and self:valid(player) then
        if Machine.input(s,action,now) then self:cast(player,s) end
    end
end
function Service:cast(player,s)
    local root = player.Character.HumanoidRootPart
    local distance = Config.Fishing.MinDistance + (Config.Fishing.MaxDistance-Config.Fishing.MinDistance)*s.power
    local target = Vector3.new(10,Config.Fishing.WaterY,math.clamp(root.Position.Z-distance,-35,30))
    local bobber = Instance.new("Part")
    bobber.Name = "Bobber_"..player.UserId
    bobber.Shape = Enum.PartType.Ball
    bobber.Size = Vector3.new(.65,.65,.65)
    bobber.Anchored = true
    bobber.CanCollide = false
    bobber.Color = Color3.fromRGB(255,140,74)
    bobber.Position = root.Position+Vector3.new(0,3,0)
    local attach = Instance.new("Attachment")
    attach.Parent = bobber
    bobber.Parent = workspace
    local tip = player.Character.FilamentRod.Handle.Tip
    local beam = Instance.new("Beam")
    beam.Attachment0 = tip
    beam.Attachment1 = attach
    beam.Width0 = .035
    beam.Width1 = .025
    beam.FaceCamera = true
    beam.Color = ColorSequence.new(Color3.fromRGB(235,238,222))
    beam.Parent = bobber
    s.bobber = bobber
    s.beam = beam
    TweenService:Create(bobber,TweenInfo.new(Config.Fishing.FlightSeconds,Enum.EasingStyle.Quad),{Position=target}):Play()
end
function Service:tick(dt)
    local now = os.clock()
    for player,s in pairs(self.sessions) do
        if not self:valid(player) then self:cancel(player,false)
        else
            Machine.step(s,now,dt)
            if s.phase == "Success" then
                self:cancel(player,true) -- Consume session before yielding to a save.
                self.remote:FireClient(player,{phase="Saving"})
                local species = Util.roll(Config.CatchTable,self.random:NextNumber())
                local id = HttpService:GenerateGUID(false)
                local seed = self.random:NextInteger(1,2147483646)
                task.spawn(function()
                    -- Lease renewal may be in flight. Wait briefly without rerolling/regranting.
                    local p = self.store.profiles[player]
                    local deadline = os.clock()+12
                    while p and p.busy and os.clock()<deadline do task.wait(.1) end
                    local ok,reason = self.store:transaction(player,function(data)
                        return self.domain.grant(data,species,id,seed,os.time())
                    end)
                    if ok then self.onReward(player); self.remote:FireClient(player,{phase="Success",species=species})
                    elseif player.Parent then self.notify(player,reason);self.remote:FireClient(player,{phase="Failed"}) end
                end)
            elseif s.phase == "Failed" then self:cancel(player,false)
            else
                self.remote:FireClient(player,{phase=s.phase,progress=s.progress,taps=s.taps,
                    remaining=s.deadline and math.max(0,s.deadline-now) or 0,
                    power=s.power or math.clamp((now-s.started)/Config.Fishing.ChargeSeconds,0,1)})
            end
        end
    end
end
return Service
