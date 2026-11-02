-- Session plot allocation. Data belongs to a player profile, never to a plot number.
local Registry={};Registry.__index=Registry
function Registry.new(config)
    local ids={};for id,zone in pairs(config.zones) do if zone.type=="plot" then table.insert(ids,id) end end;table.sort(ids)
    return setmetatable({ids=ids,plots={},owners={}},Registry)
end
function Registry:assign(owner)
    if self.plots[owner] then return self.plots[owner] end
    for _,id in ipairs(self.ids) do if self.owners[id]==nil then self.owners[id]=owner;self.plots[owner]=id;return id end end
    return nil
end
function Registry:release(owner)
    local id=self.plots[owner]
    if id and self.owners[id]==owner then self.owners[id]=nil end
    self.plots[owner]=nil
end
return Registry
