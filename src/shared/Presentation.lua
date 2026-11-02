-- Minimal view rules; no inventory mutation or reward decision on the client.
local P={}
function P.view(phase,equipped,atDock,modal)
    local active=phase=="Charge" or phase=="Reel" or phase=="Resist"
    return {meter=not modal and active,hint=not modal and equipped and phase=="Idle",
        action=not modal and equipped and ((phase=="Idle" and atDock) or active),
        waiting=not modal and (phase=="Waiting" or phase=="Flight" or phase=="Saving"),
        cancel=not modal and (active or phase=="Waiting" or phase=="Flight")}
end
function P.intent(phase,held)
    if held then return nil end
    return ({Idle="start",Reel="hold",Resist="tap"})[phase]
end
function P.actions(item,context,equipped,catalog)
    if item.kind=="pet" then return {item.id==equipped and "unequip" or "equip"} end
    if item.location=="aquarium" then return item.kind=="fish" and context=="aquarium" and {"retrieve"} or {} end
    if context=="aquarium" then return {"place"} end
    if item.kind=="fish" and context=="shop" then return {"sell"} end
    if item.kind=="fish" and context=="craft" then
        return catalog[item.species].premiumYield>0 and {"craftBasic","craftPremium"} or {"craftBasic"}
    end
    return {}
end
return P
