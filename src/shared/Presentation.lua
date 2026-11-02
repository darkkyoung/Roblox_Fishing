-- Pure view state and input contract. Cannot award items or advance catches.
local Presentation = {}
function Presentation.view(phase, equipped, atPier, modal, coreMenu)
    local hidden = modal or coreMenu
    return {
        hint = not hidden and equipped and phase == "Idle",
        gauge = not hidden and (phase == "Charge" or phase == "Reel" or phase == "Resist"),
        waiting = not hidden and (phase == "Flight" or phase == "Waiting" or phase == "Saving"),
        action = not hidden and equipped and ((phase == "Idle" and atPier) or phase == "Charge" or phase == "Reel" or phase == "Resist"),
        cancel = not hidden and (phase == "Charge" or phase == "Flight" or phase == "Waiting" or phase == "Reel" or phase == "Resist"),
        result = not hidden and (phase == "Success" or phase == "Failed"),
    }
end
function Presentation.press(phase, held)
    if held then return nil end
    if phase == "Idle" then return "start" end
    if phase == "Reel" then return "hold" end
    if phase == "Resist" then return "tap" end
    return nil
end
function Presentation.canDebug(isStudio, enabled)
    return isStudio == true and enabled == true
end
function Presentation.context(distanceShop, distanceCraft, distanceTank, radius)
    -- UX hint only. The server independently validates every operation.
    if distanceTank <= radius then return "aquarium" end
    if distanceShop <= radius then return "shop" end
    if distanceCraft <= radius then return "craft" end
    return "bag"
end
function Presentation.actions(item, context, equipped)
    if item.kind == "pet" then return {item.id == equipped and "unequip" or "equip"} end
    if item.location == "aquarium" then return item.kind == "fish" and context == "aquarium" and {"retrieve"} or {} end
    if context == "aquarium" then return {"place"} end
    if item.kind == "fish" and context == "shop" then return {"sell"} end
    if item.kind == "fish" and context == "craft" then return {"craftBasic", "craftPremium"} end
    return {}
end
return Presentation
