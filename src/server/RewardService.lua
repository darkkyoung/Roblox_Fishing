-- Server-only reward adapter. Fishing V2 can replace input without touching inventory.
local RewardService={}
function RewardService.new(domain,config,util)
    local self={}
    function self.prepare(unit,id,seed,now)
        return {species=util.roll(config.CatchTable,unit),id=id,seed=seed,at=now}
    end
    function self.grant(data,reward)
        local ok,reason=domain.grant(data,reward.species,reward.id,reward.seed,reward.at)
        if ok then data.items[reward.id].source="fishing" end
        return ok,reason
    end
    function self.hatch(data,now)
        local origins={}
        for id,item in pairs(data.items) do if item.kind=="egg" then origins[id]=item.source or "legacy" end end
        local results=domain.hatch(data,now)
        for id,source in pairs(origins) do if data.items[id].kind=="pet" then data.items[id].source=source end end
        return results
    end
    return self
end
return RewardService
