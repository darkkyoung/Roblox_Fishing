-- Shared arithmetic makes the UI's safe-area dimensions independently testable.
local Layout={}
function Layout.metrics(width,height)
    return {panelWidth=math.min(760,width-24),panelHeight=math.max(120,height-40),
        fishWidth=math.min(430,width-24),fishY=height<440 and 96 or 108,
        compact=height<440,cardWidth=math.min(760,width-24)-32}
end
return Layout
