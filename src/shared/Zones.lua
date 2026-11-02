-- Pure geometry/access rules. Position values are {x,y,z}, shared with CLI tests.
local Zones={}
function Zones.new(config)
    local self={config=config}
    local function finite(v) return type(v)=="number" and v==v and math.abs(v)<1e7 end
    function self.point(p) return type(p)=="table" and finite(p[1]) and finite(p[2]) and finite(p[3]) end
    function self.contains(id,p,inset)
        local z=config.zones[id]
        if not z or not self.point(p) then return false end
        local margin=inset or 0
        return math.abs(p[1]-z.position[1])<=z.size[1]/2-margin and math.abs(p[3]-z.position[3])<=z.size[3]/2-margin
    end
    function self.onFloor(id,p)
        local z=config.zones[id]
        if not z or not self.contains(id,p) then return false end
        local top=z.position[2]+z.size[2]/2
        return p[2]>=top+1 and p[2]<=top+9
    end
    function self.interact(id,p)
        local z=config.zones[id]
        if not z or not z.interactionDistance or not self.onFloor(id,p) then return false end
        local q=z.interaction
        return (p[1]-q[1])^2+(p[2]-q[2])^2+(p[3]-q[3])^2<=z.interactionDistance^2
    end
    function self.isPlot(id) return type(id)=="string" and config.zones[id]~=nil and config.zones[id].type=="plot" end
    function self.context(p,ownPlot)
        if self.isPlot(ownPlot) and self.interact(ownPlot,p) then return "aquarium" end
        if self.interact("FishMarket",p) then return "shop" end
        if self.interact("FeedWorkshop",p) then return "craft" end
        return "bag"
    end
    function self.authorize(action,p,ownPlot)
        if action=="place" or action=="retrieve" or action=="upgrade" then
            if self.isPlot(ownPlot) and self.interact(ownPlot,p) then return true end
            return false,"goAquarium"
        elseif action=="sell" then return self.interact("FishMarket",p),"goShop"
        elseif action=="craft" then return self.interact("FeedWorkshop",p),"goCraft"
        elseif action=="equip" or action=="unequip" then return self.point(p),"notReady" end
        return false,"invalid"
    end
    function self.canFish(p) return self.onFloor("FishingDock",p) end
    function self.waterTarget(p)
        local lake=config.zones.FishingLake
        return self.contains("FishingLake",p,.5) and not self.contains("FishingDock",p,-.4)
            and math.abs(p[2]-(lake.position[2]+lake.size[2]/2+.35))<.05
    end
    function self.castTarget(p,power,fishing)
        if not self.canFish(p) or not finite(power) then return nil end
        local lake,dock=config.zones.FishingLake,config.zones.FishingDock
        local distance=fishing.MinDistance+(fishing.MaxDistance-fishing.MinDistance)*math.clamp(power,0,1)
        local target={dock.position[1]+dock.size[1]/2+3,lake.position[2]+lake.size[2]/2+.35,
            math.clamp(p[3]-distance,lake.position[3]-lake.size[3]/2+2,lake.position[3]+lake.size[3]/2-2)}
        return self.waterTarget(target) and target or nil
    end
    function self.slot(id,index)
        local z=config.zones[id]
        assert(self.isPlot(id) and index>=1 and index<=10)
        return {z.position[1]+((index-1)%5-2)*4,z.position[2]+z.size[2]/2+2,z.position[3]+(index>5 and -3 or 1)}
    end
    return self
end
return Zones
