local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.Config)
local Util=require(Shared.Util)
local Machine=require(Shared.FishingMachine).new(Config.Fishing)
local Service={};Service.__index=Service
function Service.new(store,domain,rewards,zones,remote,onReward,notify)
    local self=setmetatable({sessions={},pending={},cooldowns={},store=store,domain=domain,rewards=rewards,zones=zones,
        remote=remote,onReward=onReward,notify=notify,random=Random.new()},Service)
    local elapsed=0
    RunService.Heartbeat:Connect(function(dt)
        elapsed+=dt;if elapsed<.08 then return end
        local step=elapsed;elapsed=0;self:tick(step)
    end)
    return self
end
function Service:busy(player) return self.sessions[player]~=nil or self.pending[player]==true end
function Service:valid(player)
    local p=self.zones:position(player)
    return self.zones.rules.canFish(p) and player.Character:FindFirstChild(self.zones.config.rodName)~=nil
end
function Service:cancel(player,quiet)
    local s=self.sessions[player];if not s then return end
    self.sessions[player]=nil
    if s.bobber then s.bobber:Destroy() end
    self.cooldowns[player]=os.clock()+Config.Fishing.Cooldown
    if not quiet and player.Parent then self.remote:FireClient(player,{phase="Failed"}) end
end
function Service:input(player,action)
    if action=="cancel" then self:cancel(player,false);return end
    local now=os.clock();local p=self.store.profiles[player]
    if not p or p.closed then return end
    local s=self.sessions[player]
    if action=="start" then
        if self:busy(player) or p.busy or now<(self.cooldowns[player] or 0) then return end
        if not self:valid(player) then self.notify(player,"goDock");return end
        if Util.count(p.data.items)>=Config.InventoryLimit then self.notify(player,"full");return end
        local bite,reel=self.domain.buffs(p.data)
        self.sessions[player]=Machine.begin(now,self.random:NextNumber(Config.Fishing.BiteMin,Config.Fishing.BiteMax)*bite,reel)
        self.remote:FireClient(player,{phase="Charge",progress=0,power=0})
    elseif s and self:valid(player) then
        if Machine.input(s,action,now) then self:cast(player,s) end
    end
end
function Service:cast(player,s)
    local p,root=self.zones:position(player)
    local target=self.zones.rules.castTarget(p,s.power,Config.Fishing)
    if not target then self:cancel(player,false);return end
    s.target=Vector3.new(unpack(target));s.startPosition=root.Position+Vector3.new(0,2,0)
    local bobber=Instance.new("Part");bobber.Name="Bobber_"..player.UserId;bobber.Shape=Enum.PartType.Ball;bobber.Size=Vector3.new(.7,.7,.7)
    bobber.Anchored=true;bobber.CanCollide=false;bobber.CanTouch=false;bobber.CanQuery=false
    bobber.Color=Color3.fromRGB(255,150,45);bobber.Position=s.startPosition
    local a=Instance.new("Attachment");a.Parent=bobber
    local beam=Instance.new("Beam");beam.Attachment0=player.Character[self.zones.config.rodName].Handle.Tip;beam.Attachment1=a
    beam.Width0=.05;beam.Width1=.04;beam.FaceCamera=true;beam.Color=ColorSequence.new(Color3.new(1,1,1));beam.Parent=bobber
    bobber.Parent=workspace;s.bobber=bobber
end
function Service:tick(dt)
    local now=os.clock()
    for player,s in pairs(self.sessions) do
        if not self:valid(player) or (s.target and (not s.bobber or not s.bobber.Parent)) then self:cancel(player,false);continue end
        if s.phase=="Flight" then
            local alpha=math.clamp((now-s.changedAt)/Config.Fishing.FlightSeconds,0,1)
            s.bobber.Position=s.startPosition:Lerp(s.target,alpha)
            if alpha>=1 then
                -- Actual server position + bounded water rectangle + physical lake raycast.
                if not self.zones:landed(s.bobber,s.target) then self:cancel(player,false);continue end
                s.landed=true
            end
        end
        Machine.step(s,now,dt)
        if s.phase=="Success" then
            if not s.landed then self:cancel(player,false);continue end
            self:cancel(player,true);self.pending[player]=true
            self.remote:FireClient(player,{phase="Saving"})
            -- Choose ONCE before any yielding. All retries use the same reward/id/seed.
            local reward=self.rewards.prepare(self.random:NextNumber(),HttpService:GenerateGUID(false),self.random:NextInteger(1,2147483646),os.time())
            task.spawn(function()
                local p=self.store.profiles[player];local deadline=os.clock()+12
                while p and p.busy and os.clock()<deadline do task.wait(.1) end
                local ok,reason=self.store:transaction(player,function(data) return self.rewards.grant(data,reward) end)
                self.pending[player]=nil
                if ok then
                    self.onReward(player)
                    if player.Parent then self.remote:FireClient(player,{phase="Success",species=reward.species,id=reward.id}) end
                elseif player.Parent then self.notify(player,reason);self.remote:FireClient(player,{phase="Failed"}) end
            end)
        elseif s.phase=="Failed" then self:cancel(player,false)
        else self.remote:FireClient(player,{phase=s.phase,progress=s.progress,taps=s.taps,remaining=s.deadline and math.max(0,s.deadline-now) or 0,
            power=s.power or math.clamp((now-s.started)/Config.Fishing.ChargeSeconds,0,1)}) end
    end
end
return Service
