local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config=require(Shared.ZoneConfig)
local Rules=require(Shared.Zones).new(Config)
local ZoneService={}
ZoneService.__index=ZoneService
local function required(parent,name)
    local child=parent:FindFirstChild(name)
    assert(child,"[FILAMENT BOOT] Missing baked object: "..parent:GetFullName().."."..name.."; rebuild the place.")
    return child
end
function ZoneService.new()
    local self=setmetatable({config=Config,rules=Rules,world=required(required(workspace,"World"),"Zones")},ZoneService)
    local problems={};local count=0
    for id,z in pairs(Config.zones) do
        local node=required(self.world,id);local floor=required(node,"Floor")
        assert(floor:IsA("BasePart"),"[FILAMENT BOOT] Expected BasePart: "..floor:GetFullName())
        local position=Vector3.new(unpack(z.position));local size=Vector3.new(unpack(z.size))
        if (floor.Position-position).Magnitude>=.01 or (floor.Size-size).Magnitude>=.01 then
            table.insert(problems,string.format("%s expected Position=(%s), Size=(%s); loaded Position=(%s), Size=(%s)",
                floor:GetFullName(),tostring(position),tostring(size),tostring(floor.Position),tostring(floor.Size)))
        end
        count+=1
        node:SetAttribute("ZoneId",id);node:SetAttribute("ZoneType",z.type)
    end
    if #problems>0 then
        table.sort(problems)
        error("[FILAMENT BOOT] Zone geometry mismatch ("..#problems.."/"..count.."). Check serialized CFrame; rebuild both place files.\n"..table.concat(problems,"\n"))
    end
    self.raycast=RaycastParams.new();self.raycast.FilterType=Enum.RaycastFilterType.Include
    -- Include only physical surface parts; safety colliders are deliberately excluded.
    self.raycast.FilterDescendantsInstances={self.world.FishingLake.Floor,self.world.FishingDock.Floor}
    print("[FILAMENT BOOT] ZoneService ready: "..count.." zone floors match ZoneConfig")
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
