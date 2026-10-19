-- Original primitive art. No external meshes, images, or marketplace assets.
local Models = {}
local function piece(model, name, size, position, color, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Color = color
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Material = Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if shape then p.Shape = shape end
    p.Parent = model
    return p
end
function Models.make(kind, species, rgb)
    local m = Instance.new("Model")
    m.Name = species
    local color = Color3.fromRGB(rgb[1],rgb[2],rgb[3])
    local root = piece(m,"Root",Vector3.new(.2,.2,.2),Vector3.zero,color)
    root.Transparency = 1
    m.PrimaryPart = root
    if kind == "fish" then
        piece(m,"Body",Vector3.new(.9,1,2.2),Vector3.zero,color,Enum.PartType.Ball)
        piece(m,"Tail",Vector3.new(.25,1.3,.7),Vector3.new(0,0,1.3),color)
        piece(m,"Fin",Vector3.new(.18,.6,.8),Vector3.new(0,.5,.1),color)
        for _,x in ipairs({-.42,.42}) do piece(m,"Eye",Vector3.new(.16,.16,.16),Vector3.new(x,.16,-.7),Color3.new(.06,.1,.13),Enum.PartType.Ball) end
    elseif kind == "egg" then
        piece(m,"Shell",Vector3.new(1.6,2.1,1.6),Vector3.zero,color,Enum.PartType.Ball)
        for _,v in ipairs({Vector3.new(.6,.3,-.3),Vector3.new(-.35,-.3,-.65),Vector3.new(.1,.65,-.5)}) do
            piece(m,"Spot",Vector3.new(.45,.45,.22),v,Color3.fromRGB(246,231,167),Enum.PartType.Ball)
        end
    else
        piece(m,"Body",Vector3.new(1.6,1.4,1.8),Vector3.zero,color,Enum.PartType.Ball)
        piece(m,"Head",Vector3.new(1.5,1.3,1.3),Vector3.new(0,.65,-.7),color,Enum.PartType.Ball)
        piece(m,"Muzzle",Vector3.new(.85,.55,.45),Vector3.new(0,.4,-1.32),Color3.fromRGB(251,230,196),Enum.PartType.Ball)
        for _,x in ipairs({-.48,.48}) do
            piece(m,"Eye",Vector3.new(.17,.22,.15),Vector3.new(x,.8,-1.24),Color3.new(.07,.09,.13),Enum.PartType.Ball)
            piece(m,"Ear",Vector3.new(.45,species == "fox" and 1 or .5,.5),Vector3.new(x,1.35,-.6),color,Enum.PartType.Ball)
        end
        if species == "dragon" then
            for _,x in ipairs({-1.3,1.3}) do
                local wing = piece(m,"Wing",Vector3.new(1.7,.15,1.5),Vector3.new(x,.6,.2),Color3.fromRGB(107,221,211))
                wing.Orientation = Vector3.new(0,0,x*15)
            end
        end
        piece(m,"Tail",Vector3.new(.65,.65,1.5),Vector3.new(0,.1,1.1),color,Enum.PartType.Ball)
    end
    return m
end
return Models
