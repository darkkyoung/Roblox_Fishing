-- Deliberately plain test objects. Identity and ownership never live in this model.
local Models={}
function Models.make(kind,species,rgb)
    local m=Instance.new("Model");m.Name=species
    local p=Instance.new("Part");p.Name="Body";p.Shape=Enum.PartType.Ball
    p.Size=kind=="fish" and Vector3.new(1,1,2) or (kind=="egg" and Vector3.new(1.4,1.8,1.4) or Vector3.new(1.5,1.5,1.5))
    p.Color=Color3.fromRGB(unpack(rgb));p.Material=Enum.Material.SmoothPlastic
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=m;m.PrimaryPart=p
    return m
end
return Models
