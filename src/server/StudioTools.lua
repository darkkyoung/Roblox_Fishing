-- No Remote can supply arbitrary amounts/species. Every operation is gated here.
local StudioTools={}
function StudioTools.enabled(isStudio,configured) return isStudio==true and configured==true end
function StudioTools.apply(data,action,option,now,domain,newId,newSeed,isStudio,configured,levels)
    if not StudioTools.enabled(isStudio,configured) then return false,"invalid" end
    if action=="debugFish" or action=="debugEgg" then
        local species=action=="debugFish" and {"silver","sunny","azure"} or {"tideEgg"}
        -- The store runs this on a disposable candidate; failure cannot partially publish.
        for _,name in ipairs(species) do
            local id=newId();local ok,reason=domain.grant(data,name,id,newSeed(),now)
            if not ok then return false,reason end
            data.items[id].source="studioDebug"
        end
    elseif action=="debugFeed" then data.feed.basic+=3;data.feed.premium+=3
    elseif action=="debugCoins" then data.coins+=500
    elseif action=="debugLevel" then
        local level=tonumber(option)
        if not level or level%1~=0 or level<1 or level>#levels then return false,"invalid" end
        if domain.occupied(data)>levels[level].capacity then return false,"tankFull" end
        data.aquariumLevel=level
    elseif action=="debugHatch" then
        for _,item in pairs(data.items) do
            if item.kind=="egg" and item.location=="aquarium" then
                local duration=item.readyAt-item.startedAt
                item.readyAt=now;item.startedAt=now-duration;item.source="studioDebug"
            end
        end
    else return false,"invalid" end
    return true,"debugDone"
end
return StudioTools
