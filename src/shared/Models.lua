-- Original layered primitive art, shared by the world and inventory ViewportFrames.
local Models={}
local function piece(model,name,size,pos,color,shape,rotation)
    local p=Instance.new(shape=="Wedge" and "WedgePart" or "Part")
    p.Name=name;p.Size=size;p.CFrame=CFrame.new(pos)*(rotation or CFrame.identity)
    p.Color=color;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
    p.Material=Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    if shape and shape~="Wedge" then p.Shape=shape end
    p.Parent=model;return p
end
function Models.make(kind,species,rgb)
    local m=Instance.new("Model");m.Name=species
    local color=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
    local cream=Color3.fromRGB(248,228,190)
    local dark=Color3.fromRGB(30,52,58)
    local root=piece(m,"Root",Vector3.new(.1,.1,.1),Vector3.zero,color);root.Transparency=1;m.PrimaryPart=root
    if kind=="fish" then
        local bodyColor=color:Lerp(Color3.fromRGB(61,124,137),.18)
        piece(m,"Body",Vector3.new(.92,1.12,2.25),Vector3.zero,bodyColor,Enum.PartType.Ball)
        piece(m,"Belly",Vector3.new(.78,.68,1.88),Vector3.new(0,-.24,-.07),color:Lerp(cream,.68),Enum.PartType.Ball)
        for _,side in ipairs({-1,1}) do
            piece(m,"TailLobe",Vector3.new(.18,.75,.9),Vector3.new(0,side*.3,1.35),bodyColor,"Wedge",CFrame.Angles(0,0,side==1 and 0 or math.pi))
            piece(m,"SideFin",Vector3.new(.5,.12,.64),Vector3.new(side*.48,-.06,.2),color:Lerp(cream,.25),"Wedge",CFrame.Angles(0,side*.4,side*.2))
            piece(m,"EyeWhite",Vector3.new(.18,.27,.28),Vector3.new(side*.4,.16,-.72),cream,Enum.PartType.Ball)
            piece(m,"Pupil",Vector3.new(.11,.15,.15),Vector3.new(side*.49,.18,-.76),dark,Enum.PartType.Ball)
            if species=="sunny" then
                for i=1,3 do piece(m,"PerchStripe",Vector3.new(.08,.58,.12),Vector3.new(side*.44,.06,-.25+i*.33),bodyColor:Lerp(dark,.3)) end
            elseif species=="azure" then
                piece(m,"GoldGill",Vector3.new(.08,.53,.16),Vector3.new(side*.46,0,-.4),Color3.fromRGB(224,190,108))
            end
        end
        piece(m,"Dorsal",Vector3.new(.15,.55,1),Vector3.new(0,.58,.17),bodyColor,"Wedge")
    elseif kind=="egg" then
        piece(m,"Shell",Vector3.new(1.55,2.05,1.55),Vector3.zero,color:Lerp(cream,.25),Enum.PartType.Ball)
        for i=1,5 do
            local a=i*2.4
            piece(m,"TideMark",Vector3.new(.3,.44,.14),Vector3.new(math.sin(a)*.65,(i%3-1)*.43,math.cos(a)*.66),Color3.fromRGB(104,182,178),Enum.PartType.Ball,CFrame.Angles(0,a,0))
        end
        piece(m,"ShellCrown",Vector3.new(.55,.3,.55),Vector3.new(0,.94,0),cream,Enum.PartType.Ball)
    else
        piece(m,"Body",Vector3.new(1.45,1.45,1.85),Vector3.zero,color,Enum.PartType.Ball)
        piece(m,"Chest",Vector3.new(1.04,1.08,.55),Vector3.new(0,-.04,-.73),cream,Enum.PartType.Ball)
        piece(m,"Head",Vector3.new(1.55,1.35,1.4),Vector3.new(0,.78,-.67),color,Enum.PartType.Ball)
        piece(m,"Muzzle",Vector3.new(.92,.54,.53),Vector3.new(0,.52,-1.32),cream,Enum.PartType.Ball)
        piece(m,"Nose",Vector3.new(.22,.16,.18),Vector3.new(0,.62,-1.61),dark,Enum.PartType.Ball)
        for _,side in ipairs({-1,1}) do
            piece(m,"Eye",Vector3.new(.18,.25,.13),Vector3.new(side*.46,.94,-1.27),dark,Enum.PartType.Ball)
            piece(m,"EyeShine",Vector3.new(.06,.07,.05),Vector3.new(side*.43,1.01,-1.34),Color3.new(1,1,1),Enum.PartType.Ball)
            piece(m,"Ear",Vector3.new(.49,species=="fox" and .98 or .54,.48),Vector3.new(side*.53,1.43,-.63),color,species=="fox" and "Wedge" or Enum.PartType.Ball)
            piece(m,"Paw",Vector3.new(.54,.44,.65),Vector3.new(side*.58,-.65,-.45),color:Lerp(cream,.3),Enum.PartType.Ball)
            if species=="dragon" then
                piece(m,"Wing",Vector3.new(1.5,.16,1.3),Vector3.new(side*1.24,.6,.25),Color3.fromRGB(112,201,187),"Wedge",CFrame.Angles(0,side*.25,side*.28))
                piece(m,"Horn",Vector3.new(.22,.65,.3),Vector3.new(side*.45,1.6,-.4),cream,"Wedge")
            end
        end
        piece(m,"Tail",Vector3.new(.68,.68,1.6),Vector3.new(0,.08,1.12),color,Enum.PartType.Ball,CFrame.Angles(.18,0,0))
        if species=="fox" then piece(m,"TailTip",Vector3.new(.55,.55,.65),Vector3.new(0,.22,1.8),cream,Enum.PartType.Ball) end
    end
    return m
end
return Models
