-- Dimensions relative to CoreUISafeInsets, not the physical screen.
local Layout = {}
function Layout.metrics(width, height, touch)
    local portrait = width < 620 and height >= width
    local compact = height < 430
    local panelWidth = math.min(940, width - 24)
    local panelHeight = math.min(700, height - 24)
    local split = not portrait and panelWidth >= 590
    local detailWidth = split and math.clamp(math.floor(panelWidth * .36), 238, 320) or panelWidth - 24
    local listWidth = split and panelWidth - detailWidth - 40 or panelWidth - 24
    local cols = math.max(2, math.floor(listWidth / (compact and 124 or 144)))
    local cardWidth = math.floor((listWidth - (cols-1)*10 - 8) / cols)
    local gaugeWidth = math.min(touch and 300 or 370, width - (touch and not portrait and 240 or 36))
    local gaugeHeight = compact and 72 or 86
    local gaugeBottom = touch and (portrait and 210 or 82) or 110
    local actionSize = 64
    local actionY = math.max(70, height - (portrait and 198 or 172))
    return {
        panelWidth=panelWidth, panelHeight=panelHeight, portrait=portrait, compact=compact,
        split=split, detailWidth=detailWidth, listWidth=listWidth, columns=cols, cardWidth=cardWidth,
        cardHeight=compact and 132 or 154, gaugeWidth=gaugeWidth, gaugeHeight=gaugeHeight,
        gaugeY=height-gaugeBottom-gaugeHeight, gaugeBottom=gaugeBottom,
        actionSize=actionSize, actionX=width-actionSize-18, actionY=actionY,
        previewHeight=compact and 112 or 166,
    }
end
function Layout.hud(width)
    return {title=width>=340, coins=width>=170, bagWidth=48}
end
return Layout
