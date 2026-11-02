local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config=require(Shared.ZoneConfig)
local Rules=require(Shared.Zones).new(Config)
local ZoneService={}
ZoneService.__index=ZoneService
function ZoneService.new()
    local self=setmetatable({config=Config,rules=Rules,world=workspace:WaitForChild("World"):WaitForChild("Zones")},ZoneService)
    for id,z in pairs(Config.zones) do
        local node=self.world:WaitForChild(id);local floor=node:WaitForChild("Floor")
        assert((floor.Position-Vector3.new(unpack(z.position))).Magnitude<.01,"Zone position differs: "..id)
        assert((floor.Size-Vector3.new(unpack(z.size))).Magnitude<.01,"Zone size differs: "..id)
        node:SetAttribute("ZoneId",id);node:SetAttribute("ZoneType",z.type)
    end
    self.raycast=RaycastParams.new();self.raycast.FilterType=Enum.RaycastFilterType.Include
    -- Include only physical surface parts; safety colliders are deliberately excluded.
    self.raycast.FilterDescendantsInstances={self.world.FishingLake.Floor,self.world.FishingDock.Floor}
    return self
end
function ZoneService:position(player)
    local char=player.Character;local human=char and char:FindFirstChildOfClass("Humanoid")
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if not human or human.Health<=0 or not root then return nil end
    return {root.Position.X,root.Position.Y,root.Position.Z},root
end
function ZoneService:landed(bobber,target)
    if not bobber or not bobber.Parent or (bobber.Position-target).Magnitude>.2 then return false end
    local p={bobber.Position.X,bobber.Position.Y,bobber.Position.Z}
    if not self.rules.waterTarget(p) then return false end
    local hit=workspace:Raycast(bobber.Position+Vector3.new(0,6,0),Vector3.new(0,-10,0),self.raycast)
    return hit~=nil and hit.Instance==self.world.FishingLake.Floor and math.abs(bobber.Position.Y-hit.Position.Y-.35)<.1
end
return ZoneService
