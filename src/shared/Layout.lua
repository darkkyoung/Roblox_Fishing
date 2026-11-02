local Layout={}
function Layout.metrics(w,h,touch)
    local portrait=w<600 and h>w
    local meterWidth=math.min(340,w-(touch and not portrait and 300 or 32))
    return {panelWidth=math.min(680,w-20),panelHeight=math.min(660,h-20),
        meterWidth=meterWidth,meterY=h-(touch and (portrait and 310 or 180) or 256),meterHeight=90,
        actionX=touch and w-82 or w/2-60,actionY=h-(touch and (portrait and 200 or 158) or 158),
        actionW=touch and 64 or 120,actionH=touch and 64 or 44,
        cancelX=touch and w-138 or w/2+68,hintY=h-(touch and portrait and 248 or 114),portrait=portrait}
end
function Layout.hud(width)
    local bagWidth=math.min(84,math.max(44,width-12))
    local bagX=width-bagWidth-8
    local coinWidth=math.min(136,math.max(44,bagX-16))
    return {bagX=bagX,bagWidth=bagWidth,coinX=bagX-coinWidth-8,coinWidth=coinWidth,showCoins=width>=150}
end
return Layout
