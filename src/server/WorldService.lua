local Shared=game:GetService("ReplicatedStorage").Shared
local Catalog=require(Shared.Catalog)
local Models=require(Shared.Models)
local Visual=require(Shared.VisualConfig)
local WorldService={}
WorldService.__index=WorldService
function WorldService.new()
    local self=setmetatable({plots={},world=workspace:WaitForChild("World")},WorldService)
    self.visuals=Instance.new("Folder");self.visuals.Name="Visuals";self.visuals.Parent=workspace
    workspace.Terrain.WaterColor=Color3.fromRGB(48,147,156)
    workspace.Terrain.WaterTransparency=.48
    workspace.Terrain.WaterReflectance=.2
    workspace.Terrain.WaterWaveSize=.1
    workspace.Terrain.WaterWaveSpeed=7
    workspace.Terrain:FillBlock(CFrame.new(0,-2,0),Vector3.new(104,4,80),Enum.Material.Water)
    self.world.WaterPreview:Destroy()
    return self
end
function WorldService:assign(player)
    local plots=self.world.Aquariums:GetChildren()
    table.sort(plots,function(a,b) return a.Name<b.Name end)
    for _,plot in ipairs(plots) do
        if not plot:GetAttribute("OwnerUserId") then
            plot:SetAttribute("OwnerUserId",player.UserId);self.plots[player]=plot
            local group=Instance.new("Folder");group.Name=tostring(player.UserId);group.Parent=self.visuals
            return plot
        end
    end
    return nil
end
function WorldService:sync(player,data)
    local plot=self.plots[player]
    if not plot then return end
    plot.OwnerSign.Label.Text.Text=player.DisplayName.." · Lv."..data.aquariumLevel
    local group=self.visuals:FindFirstChild(tostring(player.UserId))
    if not group then return end
    local ids={};local desired={}
    for id,item in pairs(data.items) do if item.location=="aquarium" then table.insert(ids,id);desired[id]=true end end
    table.sort(ids)
    for index,id in ipairs(ids) do
        local item=data.items[id]
        local m=group:FindFirstChild(id)
        if not m then
            m=Models.make(item.kind,item.species,Catalog[item.species].color);m.Name=id
            m:SetAttribute("VisualKind",item.kind);m:SetAttribute("OwnerUserId",player.UserId)
            m:SetAttribute("TankCenter",plot.Anchor.Position)
            m:SetAttribute("SwimIndex",index)
            m:PivotTo(CFrame.new(plot.Anchor.Position+Vector3.new((index%4-1.5)*2.8,-1,0)))
            m.Parent=group
        else m:SetAttribute("SwimIndex",index) end
    end
    local pet=data.items[data.equippedPet]
    local follower=group:FindFirstChild("EquippedPet")
    if follower and (not pet or follower:GetAttribute("Species")~=pet.species) then follower:Destroy();follower=nil end
    if pet then
        desired.EquippedPet=true
        if not follower then
            follower=Models.make("pet",pet.species,Catalog[pet.species].color);follower.Name="EquippedPet"
            follower:SetAttribute("Species",pet.species);follower:SetAttribute("VisualKind","follower");follower:SetAttribute("OwnerUserId",player.UserId)
            local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            follower:PivotTo(root and root.CFrame or CFrame.new(plot.Arrival.Position));follower.Parent=group
        end
    end
    -- Preserve unchanged visual objects. A save or bag refresh no longer resets swimming.
    for _,m in ipairs(group:GetChildren()) do
        if not desired[m.Name] then
            local item=data.items[m.Name]
            if item and item.kind=="pet" and m:GetAttribute("VisualKind")=="egg" then
                local burst=Instance.new("Part");burst.Name="HatchPulse";burst.Anchored=true;burst.CanCollide=false;burst.Transparency=1
                burst.Size=Vector3.new(.1,.1,.1);burst.Position=m:GetPivot().Position
                burst:SetAttribute("FilamentHatch",true);burst.Parent=self.visuals
                game:GetService("Debris"):AddItem(burst,2)
            end
            m:Destroy()
        end
    end
end
function WorldService:release(player)
    local plot=self.plots[player]
    if plot then plot:SetAttribute("OwnerUserId",nil);plot.OwnerSign.Label.Text.Text=string.sub(plot.Name,5).." · VACANT" end
    self.plots[player]=nil
    local group=self.visuals:FindFirstChild(tostring(player.UserId))
    if group then group:Destroy() end
end
function WorldService:rod(player)
    local character=player.Character
    if not character then return end
    local backpack=player:WaitForChild("Backpack",10)
    if not backpack then return end
    for _,container in ipairs({backpack,character}) do
        local old=container:FindFirstChild(Visual.RodName);if old then old:Destroy() end
    end
    local tool=Instance.new("Tool");tool.Name=Visual.RodName;tool.ToolTip="낚싯대 · Fishing rod";tool.CanBeDropped=false
    tool.Grip=CFrame.new(0,-.35,0)*CFrame.Angles(math.rad(-28),0,0)
    local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(.28,1.25,.28)
    handle.Color=Color3.fromRGB(96,66,46);handle.Material=Enum.Material.Wood;handle.CanCollide=false;handle.Massless=true;handle.Parent=tool
    local function segment(name,size,offset,color)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=handle.CFrame*CFrame.new(offset)
        p.Color=color;p.CanCollide=false;p.CanTouch=false;p.Massless=true;p.Parent=tool
        local weld=Instance.new("WeldConstraint");weld.Part0=handle;weld.Part1=p;weld.Parent=p
        return p
    end
    segment("Shaft",Vector3.new(.11,3.35,.11),Vector3.new(0,2.1,0),Color3.fromRGB(48,106,103))
    segment("GripBand",Vector3.new(.31,.18,.31),Vector3.new(0,.52,0),Color3.fromRGB(229,170,89))
    local reel=segment("Reel",Vector3.new(.55,.55,.32),Vector3.new(0,.05,.28),Color3.fromRGB(211,161,85));reel.Shape=Enum.PartType.Ball
    for _,y in ipairs({1,2.1,3.5}) do segment("LineGuide",Vector3.new(.18,.08,.18),Vector3.new(0,y,0),Color3.fromRGB(218,219,191)) end
    local tip=Instance.new("Attachment");tip.Name="Tip";tip.Position=Vector3.new(0,3.8,0);tip.Parent=handle
    tool.Parent=backpack
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid:EquipTool(tool) end
end
return WorldService
