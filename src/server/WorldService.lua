local Shared=game:GetService("ReplicatedStorage").Shared
local Catalog=require(Shared.Catalog)
local Models=require(Shared.Models)
local Registry=require(script.Parent.PlotRegistry)
local WorldService={};WorldService.__index=WorldService
function WorldService.new(zones)
    local registry=Registry.new(zones.config)
    local self=setmetatable({zones=zones,registry=registry,plots=registry.plots,visuals=Instance.new("Folder")},WorldService)
    self.visuals.Name="CollectionVisuals";self.visuals.Parent=workspace
    return self
end
function WorldService:assign(player)
    local id=self.registry:assign(player)
    if not id then return nil end
    self.zones.world[id]:SetAttribute("OwnerUserId",player.UserId)
    if not self.visuals:FindFirstChild(tostring(player.UserId)) then
        local group=Instance.new("Folder");group.Name=tostring(player.UserId);group.Parent=self.visuals
    end
    return id
end
function WorldService:sync(player,data)
    local id=self.plots[player];if not id then return end
    local node=self.zones.world[id]
    node.OwnerSign.Label.Text.Text=id.."\n"..player.DisplayName.." · Lv."..data.aquariumLevel
    local group=self.visuals:FindFirstChild(tostring(player.UserId));if not group then return end
    local ids,desired={},{}
    for itemId,item in pairs(data.items) do if item.location=="aquarium" then table.insert(ids,itemId) end end
    table.sort(ids)
    for index,itemId in ipairs(ids) do
        desired[itemId]=true
        local item=data.items[itemId];local model=group:FindFirstChild(itemId)
        if not model then
            model=Models.make(item.kind,item.species,Catalog[item.species].color);model.Name=itemId
            model:SetAttribute("ItemId",itemId);model:SetAttribute("OwnerUserId",player.UserId);model:SetAttribute("VisualKind",item.kind)
            model.Parent=group
        end
        local p=Vector3.new(unpack(self.zones.rules.slot(id,index)))
        model:SetAttribute("SlotPosition",p);model:SetAttribute("SlotIndex",index);model:PivotTo(CFrame.new(p))
    end
    local pet=data.items[data.equippedPet];local follower=group:FindFirstChild("EquippedPet")
    if follower and (not pet or follower:GetAttribute("ItemId")~=pet.id) then follower:Destroy();follower=nil end
    if pet then
        desired.EquippedPet=true
        if not follower then
            follower=Models.make("pet",pet.species,Catalog[pet.species].color);follower.Name="EquippedPet"
            follower:SetAttribute("VisualKind","follower");follower:SetAttribute("OwnerUserId",player.UserId);follower:SetAttribute("ItemId",pet.id)
            local _,root=self.zones:position(player)
            follower:PivotTo(root and root.CFrame or CFrame.new(unpack(self.zones.config.zones[id].arrival)))
            follower.Parent=group
        end
    end
    for _,m in ipairs(group:GetChildren()) do if not desired[m.Name] then m:Destroy() end end
end
function WorldService:release(player)
    local id=self.plots[player]
    if id then
        self.zones.world[id]:SetAttribute("OwnerUserId",nil)
        self.zones.world[id].OwnerSign.Label.Text.Text=id.."\nVACANT / 비어 있음"
        self.registry:release(player)
    end
    local group=self.visuals:FindFirstChild(tostring(player.UserId));if group then group:Destroy() end
end
function WorldService:rod(player)
    local char=player.Character;local bag=player:WaitForChild("Backpack",10)
    if not char or not bag then return end
    local name=self.zones.config.rodName
    if char:FindFirstChild(name) or bag:FindFirstChild(name) then return end
    local tool=Instance.new("Tool");tool.Name=name;tool.ToolTip="낚싯대 / Fishing rod";tool.CanBeDropped=false
    local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(.18,4,.18)
    handle.Color=Color3.fromRGB(117,80,46);handle.CanCollide=false;handle.CanTouch=false;handle.Massless=true;handle.Parent=tool
    local tip=Instance.new("Attachment");tip.Name="Tip";tip.Position=Vector3.new(0,2,0);tip.Parent=handle
    tool.Grip=CFrame.new(0,-1.4,0);tool.Parent=bag
    local human=char:FindFirstChildOfClass("Humanoid");if human then human:EquipTool(tool) end
end
return WorldService
