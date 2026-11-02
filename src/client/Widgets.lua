local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Visual=require(Shared.VisualConfig)
local Models=require(Shared.Models)
local Catalog=require(Shared.Catalog)
local W={colors={}}
for name,rgb in pairs(Visual.Colors) do W.colors[name]=Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
function W.new(class,parent,props)
    local o=Instance.new(class)
    for key,value in pairs(props or {}) do o[key]=value end
    o.Parent=parent
    return o
end
function W.round(o,radius) W.new("UICorner",o,{CornerRadius=UDim.new(0,radius or 14)}) end
function W.stroke(o,color,width)
    return W.new("UIStroke",o,{Color=color or W.colors.line,Thickness=width or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
end
function W.frame(parent,props)
    props=props or {};props.BorderSizePixel=0
    if props.BackgroundColor3==nil then props.BackgroundColor3=W.colors.panel end
    return W.new("Frame",parent,props)
end
function W.label(parent,text,pos,size,fontSize,color,bold)
    return W.new("TextLabel",parent,{Text=text,Position=pos,Size=size,BackgroundTransparency=1,
        Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextSize=fontSize or 14,
        TextColor3=color or W.colors.ink,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true})
end
function W.button(parent,text,pos,size,callback,primary)
    local b=W.new("TextButton",parent,{Text=text,Position=pos,Size=size,BackgroundColor3=primary and W.colors.accent or W.colors.card,
        TextColor3=W.colors.ink,TextSize=14,Font=Enum.Font.GothamBold,TextWrapped=true,BorderSizePixel=0,AutoButtonColor=true})
    W.round(b,12);W.stroke(b,primary and W.colors.accent or W.colors.line)
    if callback then b.Activated:Connect(callback) end
    return b
end
-- Code-native silhouettes: no image downloads or font-dependent emoji icons.
function W.icon(parent,kind,pos,size,color)
    local f=W.frame(parent,{Position=pos,Size=UDim2.fromOffset(size,size),BackgroundTransparency=1})
    local c=color or W.colors.ink
    local function box(x,y,w,h,r)
        local b=W.frame(f,{Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundColor3=c})
        if r then W.round(b,r) end
        return b
    end
    if kind=="bag" then
        box(.18,.31,.64,.57,5)
        local handle=box(.33,.13,.34,.33,5);handle.BackgroundTransparency=1;W.stroke(handle,c,2)
        local pocket=box(.31,.56,.38,.23,3);pocket.BackgroundTransparency=1;W.stroke(pocket,W.colors.panel,1.5)
    elseif kind=="fish" then
        box(.15,.27,.62,.45,20)
        local tail=box(.69,.29,.25,.41,2);tail.Rotation=45
        local eye=box(.26,.37,.08,.08,6);eye.BackgroundColor3=W.colors.panel
    elseif kind=="egg" then box(.27,.13,.48,.72,25)
    elseif kind=="pet" then
        box(.24,.42,.52,.4,18)
        for _,x in ipairs({.12,.34,.56,.78}) do box(x,.16,.17,.25,12) end
    elseif kind=="coin" then
        box(.13,.13,.74,.74,30)
        local center=box(.32,.31,.36,.38,5);center.BackgroundTransparency=1;W.stroke(center,W.colors.panel,2)
    elseif kind=="tank" then
        local tank=box(.12,.24,.76,.57,4);tank.BackgroundTransparency=1;W.stroke(tank,c,2)
        box(.2,.59,.6,.12,2)
    end
    return f
end
function W.viewport(parent,species,pos,size)
    local def=Catalog[species]
    local v=W.new("ViewportFrame",parent,{Position=pos,Size=size,BackgroundTransparency=1,
        Ambient=Color3.fromRGB(215,222,206),LightColor=Color3.fromRGB(255,241,211),LightDirection=Vector3.new(-1,-2,-3),Active=false})
    local world=W.new("WorldModel",v,{})
    local m=Models.make(def.kind,species,def.color);m.Parent=world
    local bounds,size3=m:GetBoundingBox()
    local center=bounds.Position
    local distance=math.max(5,size3.Magnitude*1.9)
    local camera=W.new("Camera",v,{FieldOfView=32,CFrame=CFrame.lookAt(center+Vector3.new(.55,.25,-1).Unit*distance,center)})
    v.CurrentCamera=camera
    return v,m
end
function W.scroll(parent,props)
    props=props or {};props.BackgroundTransparency=1;props.BorderSizePixel=0;props.ScrollBarThickness=3
    props.ScrollBarImageColor3=W.colors.water;props.CanvasSize=UDim2.new();props.AutomaticCanvasSize=Enum.AutomaticSize.Y
    props.ScrollingDirection=Enum.ScrollingDirection.Y
    return W.new("ScrollingFrame",parent,props)
end
function W.stack(parent,gap)
    return W.new("UIListLayout",parent,{Padding=UDim.new(0,gap or 10),SortOrder=Enum.SortOrder.LayoutOrder})
end
return W
