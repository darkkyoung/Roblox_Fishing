-- Pure game rules. No remotes, Instances, yielding, or DataStore dependencies.
local Domain = {}
function Domain.new(config, catalog, util)
    local self = {}
    function self.default()
        return {schema = config.SchemaVersion, revision = 0, coins = config.StartingCoins,
            items = {}, feed = {basic = 0, premium = 0}, aquariumLevel = 1, equippedPet = false}
    end
    function self.valid(data)
        local function integer(v, minimum, maximum)
            return type(v) == "number" and v == v and v >= minimum and v <= maximum and v % 1 == 0
        end
        if type(data) ~= "table" or data.schema ~= config.SchemaVersion then return false end
        if not integer(data.coins,0,1e12) then return false end
        if type(data.items) ~= "table" or type(data.feed) ~= "table" or not config.Aquarium[data.aquariumLevel] then return false end
        if not integer(data.revision,0,1e12) then return false end
        for _, k in ipairs({"basic", "premium"}) do
            if not integer(data.feed[k],0,1e12) then return false end
        end
        for id, item in pairs(data.items) do
            if type(id) ~= "string" or type(item) ~= "table" or item.id ~= id or not catalog[item.species] then return false end
            if item.kind ~= catalog[item.species].kind then return false end
            if item.location ~= "bag" and item.location ~= "aquarium" then return false end
            if item.kind == "pet" and item.location ~= "bag" then return false end
            if not integer(item.obtainedAt,0,1e12) then return false end
            if item.kind == "egg" and not integer(item.seed,1,2147483646) then return false end
            if item.kind == "egg" and item.location == "aquarium" then
                if not integer(item.readyAt,0,1e12) or not integer(item.startedAt,0,item.readyAt) then return false end
                if not config.Feed[item.feedQuality] or not config.Aquarium[item.incubationLevel] then return false end
            end
        end
        if data.equippedPet then
            local pet = data.items[data.equippedPet]
            if not pet or pet.kind ~= "pet" then return false end
        end
        return true
    end
    function self.grant(data, species, id, seed, now)
        if util.count(data.items) >= config.InventoryLimit then return false, "full" end
        if data.items[id] or not catalog[species] then return false, "invalid" end
        local kind = catalog[species].kind
        data.items[id] = {id = id, species = species, kind = kind, location = "bag", obtainedAt = now,
            seed = kind == "egg" and seed or nil,
            growth = kind == "fish" and {stage = 0, experience = 0, evolutionVersion = 1} or nil}
        return true, "granted"
    end
    function self.occupied(data)
        local n = 0
        for _, item in pairs(data.items) do if item.location == "aquarium" then n += 1 end end
        return n
    end
    function self.weights(level, quality, seconds)
        local f = config.Feed[quality]
        local time = math.clamp(seconds / config.HatchSeconds, 0, 1)
        return {
            {id = "otter", weight = config.HatchWeights.common},
            {id = "fox", weight = config.HatchWeights.rare + (level-1)*config.HatchLevelBonus.rare + f.rare + time*config.HatchTimeBonus.rare},
            {id = "dragon", weight = config.HatchWeights.legendary + (level-1)*config.HatchLevelBonus.legendary + f.legendary + time*config.HatchTimeBonus.legendary},
        }
    end
    function self.apply(data, action, id, option, now)
        if action == "upgrade" then
            local cost = config.Aquarium[data.aquariumLevel].nextCost
            if cost == 0 then return false, "maxLevel" end
            if data.coins < cost then return false, "noCoins" end
            data.coins -= cost
            data.aquariumLevel += 1
            return true, "upgraded"
        end
        if action == "unequip" then
            if not data.equippedPet then return false, "invalid" end
            data.equippedPet = false
            return true, "unequipped"
        end
        local item = data.items[id]
        if not item then return false, "notOwned" end
        local definition = catalog[item.species]
        if action == "place" then
            if item.location ~= "bag" or item.kind == "pet" then return false, "stateError" end
            if self.occupied(data) >= config.Aquarium[data.aquariumLevel].capacity then return false, "tankFull" end
            if item.kind == "egg" then
                local quality = option or "none"
                if not config.Feed[quality] then return false, "invalid" end
                if quality ~= "none" then
                    if data.feed[quality] < 1 then return false, "noFeed" end
                    data.feed[quality] -= 1
                end
                item.startedAt = now
                item.readyAt = now + config.Feed[quality].duration
                item.feedQuality = quality
                item.incubationLevel = data.aquariumLevel -- snapshot; upgrades affect new incubations
            end
            item.location = "aquarium"
            return true, "placed"
        elseif action == "retrieve" then
            if item.kind ~= "fish" or item.location ~= "aquarium" then return false, "eggLocked" end
            item.location = "bag"
            return true, "retrieved"
        elseif action == "sell" or action == "craft" then
            if item.kind ~= "fish" or item.location ~= "bag" then return false, "retrieveFirst" end
            if action == "sell" then data.coins += definition.value
            else
                if option ~= "basic" and option ~= "premium" then return false, "invalid" end
                local amount = option == "basic" and definition.basicYield or definition.premiumYield
                if amount == 0 then return false, "needBetterFish" end
                data.feed[option] += amount
            end
            data.items[id] = nil
            return true, action == "sell" and "sold" or "crafted"
        elseif action == "equip" then
            if item.kind ~= "pet" then return false, "invalid" end
            data.equippedPet = id
            return true, "equipped"
        end
        return false, "invalid"
    end
    function self.hatch(data, now)
        local results = {}
        for id, egg in pairs(data.items) do
            if egg.kind == "egg" and egg.location == "aquarium" and now >= egg.readyAt then
                local species = util.roll(self.weights(egg.incubationLevel, egg.feedQuality, egg.readyAt - egg.startedAt), util.seedUnit(egg.seed))
                -- Same identity becomes a pet. Removing the egg and granting the pet is one transaction.
                data.items[id] = {id = id, kind = "pet", species = species, location = "bag", obtainedAt = now,
                    originEgg = egg.species, hatchedAt = egg.readyAt, incubation = {level = egg.incubationLevel, feed = egg.feedQuality}}
                table.insert(results, species)
            end
        end
        return results
    end
    function self.buffs(data)
        local pet = data.items[data.equippedPet]
        local d = pet and catalog[pet.species]
        return d and d.biteMultiplier or 1, d and d.reelMultiplier or 1
    end
    return self
end
return Domain
