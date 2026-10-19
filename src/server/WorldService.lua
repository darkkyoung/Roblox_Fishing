local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.Catalog)
local Models = require(Shared.Models)
local WorldService = {}
WorldService.__index = WorldService
function WorldService.new()
    local self = setmetatable({plots = {}, world = workspace:WaitForChild("World")},WorldService)
    self.visuals = Instance.new("Folder")
    self.visuals.Name = "Visuals"
    self.visuals.Parent = workspace
    workspace.Terrain.WaterColor = Color3.fromRGB(49,148,171)
    workspace.Terrain.WaterTransparency = .45
    workspace.Terrain.WaterWaveSize = .12
    workspace.Terrain.WaterWaveSpeed = 8
    workspace.Terrain:FillBlock(CFrame.new(0,-2,0),Vector3.new(104,4,80),Enum.Material.Water)
    self.world.WaterPreview:Destroy()
    return self
end
function WorldService:assign(player)
    local plots = self.world.Aquariums:GetChildren()
    table.sort(plots,function(a,b) return a.Name < b.Name end)
    for _,plot in ipairs(plots) do
        if not plot:GetAttribute("OwnerUserId") then
            plot:SetAttribute("OwnerUserId",player.UserId)
            self.plots[player] = plot
            local group = Instance.new("Folder")
            group.Name = tostring(player.UserId)
            group.Parent = self.visuals
            return plot
        end
    end
    return nil
end
function WorldService:sync(player,data)
    local plot = self.plots[player]
    if not plot then return end
    plot.OwnerSign.Label.Text.Text = player.DisplayName .. "\nLv."..data.aquariumLevel.." AQUARIUM"
    local group = self.visuals:FindFirstChild(tostring(player.UserId))
    group:ClearAllChildren()
    local ids = {}
    for id,item in pairs(data.items) do if item.location == "aquarium" then table.insert(ids,id) end end
    table.sort(ids)
    for index,id in ipairs(ids) do
        local item = data.items[id]
        local m = Models.make(item.kind,item.species,Catalog[item.species].color)
        m.Name = id
        m:SetAttribute("VisualKind",item.kind)
        m:SetAttribute("OwnerUserId",player.UserId)
        m:SetAttribute("SwimIndex",index)
        m:SetAttribute("TankCenter",plot.Anchor.Position)
        m:PivotTo(CFrame.new(plot.Anchor.Position+Vector3.new((index%5-2)*3,-1,0)))
        m.Parent = group
    end
    local pet = data.items[data.equippedPet]
    if pet then
        local m = Models.make("pet",pet.species,Catalog[pet.species].color)
        m.Name = "EquippedPet"
        m:SetAttribute("VisualKind","follower")
        m:SetAttribute("OwnerUserId",player.UserId)
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        m:PivotTo(root and root.CFrame or CFrame.new(plot.Arrival.Position))
        m.Parent = group
    end
end
function WorldService:release(player)
    local plot = self.plots[player]
    if plot then plot:SetAttribute("OwnerUserId",nil); plot.OwnerSign.Label.Text.Text = "VACANT" end
    self.plots[player] = nil
    local group = self.visuals:FindFirstChild(tostring(player.UserId))
    if group then group:Destroy() end
end
function WorldService:rod(player)
    if not player.Character then return end
    local backpack = player:WaitForChild("Backpack",10)
    if not backpack then return end
    local previous = backpack:FindFirstChild("FilamentRod")
    if previous then previous:Destroy() end
    previous = player.Character:FindFirstChild("FilamentRod")
    if previous then previous:Destroy() end
    local tool = Instance.new("Tool")
    tool.Name = "FilamentRod"
    tool.ToolTip = "FILAMENT · 낚싯대 / Fishing Rod"
    tool.CanBeDropped = false
    tool.Grip = CFrame.new(0,-1,0)*CFrame.Angles(math.rad(-25),0,0)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(.18,5,.18)
    handle.Color = Color3.fromRGB(104,72,49)
    handle.Material = Enum.Material.Wood
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = tool
    local tip = Instance.new("Attachment")
    tip.Name = "Tip"
    tip.Position = Vector3.new(0,2.5,0)
    tip.Parent = handle
    tool.Parent = backpack
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid:EquipTool(tool) end
end
return WorldService
