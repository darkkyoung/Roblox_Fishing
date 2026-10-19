--!strict
local Util = {}
function Util.clone(value: any): any
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = Util.clone(v) end
    return result
end
function Util.count(map: any): number
    local n = 0
    for _ in pairs(map) do n += 1 end
    return n
end
function Util.roll(entries: any, unit: number): string
    local total = 0
    for _, entry in ipairs(entries) do total += entry.weight end
    local target = math.clamp(unit, 0, 0.999999999) * total
    for _, entry in ipairs(entries) do
        target -= entry.weight
        if target < 0 then return entry.id end
    end
    return entries[#entries].id
end
-- A persisted seed produces the same roll after retries or reconnects.
function Util.seedUnit(seed: number): number
    return ((seed * 48271) % 2147483647) / 2147483647
end
return Util
