local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Visual=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").VisualConfig)
local localPlayer=Players.LocalPlayer
local visuals=workspace:WaitForChild("Visuals")
local tracked,bobbers={},{}
local fx=Instance.new("Folder");fx.Name="FilamentLocalEffects";fx.Parent=workspace
local function dot(position,color,size)
    local p=Instance.new("Part");p.Size=Vector3.new(size,size,size);p.Shape=Enum.PartType.Ball
    p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Position=position;p.Parent=fx
    return p
end
local function ripple(position,color,diameter)
    local p=dot(position,color,1)
    p.Shape=Enum.PartType.Cylinder;p.CFrame=CFrame.new(position)*CFrame.Angles(0,0,math.pi/2)
    p.Size=Vector3.new(.045,.7,.7);p.Transparency=.5
    TweenService:Create(p,TweenInfo.new(.7,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(.045,diameter,diameter),Transparency=1}):Play()
    Debris:AddItem(p,.8)
end
local function hatchBurst(position)
    for i=1,10 do
        local a=i*math.pi/5
        local p=dot(position,Color3.fromRGB(244,186,102),.18)
        local target=position+Vector3.new(math.cos(a)*2,1.8+(i%3)*.4,math.sin(a)*2)
        TweenService:Create(p,TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=target,Transparency=1}):Play()
        Debris:AddItem(p,1.1)
    end
end
local function add(object)
    if object:IsA("Model") and object:GetAttribute("VisualKind") then tracked[object]=true
    elseif object:IsA("BasePart") and object:GetAttribute("FilamentHatch") then hatchBurst(object.Position) end
end
for _,object in ipairs(visuals:GetDescendants()) do add(object) end
visuals.DescendantAdded:Connect(add)
visuals.DescendantRemoving:Connect(function(object) tracked[object]=nil end)
local function trackBobber(object)
    if not object:IsA("BasePart") or not object:GetAttribute("FilamentBobber") then return end
    bobbers[object]={phase="Flight",rippleAt=0}
end
workspace.ChildAdded:Connect(trackBobber)
workspace.ChildRemoved:Connect(function(object) bobbers[object]=nil end)
for _,object in ipairs(workspace:GetChildren()) do trackBobber(object) end
local function ownerMarker(plot)
    local anchor=plot:WaitForChild("UpgradeConsole")
    local marker=Instance.new("BillboardGui");marker.Name="LocalOwnerMarker";marker.Adornee=anchor
    marker.Size=UDim2.fromOffset(116,28);marker.StudsOffset=Vector3.new(0,3,0);marker.MaxDistance=100;marker.AlwaysOnTop=false
    local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(45,85,83)
    label.Text=string.sub(localPlayer.LocaleId,1,2)=="ko" and "내 수족관" or "YOUR AQUARIUM"
    label.TextColor3=Color3.fromRGB(255,231,180);label.TextSize=12;label.Font=Enum.Font.GothamBold;label.Parent=marker
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,9);corner.Parent=label
    marker.Parent=anchor
    local function refresh() marker.Enabled=plot:GetAttribute("OwnerUserId")==localPlayer.UserId end
    plot:GetAttributeChangedSignal("OwnerUserId"):Connect(refresh);refresh()
end
for _,plot in ipairs(workspace:WaitForChild("World").Aquariums:GetChildren()) do ownerMarker(plot) end
local elapsed=0
RunService.RenderStepped:Connect(function(dt)
    elapsed+=dt
    if elapsed<1/30 then return end
    local step=elapsed;elapsed=0
    local now=workspace:GetServerTimeNow()
    local camera=workspace.CurrentCamera
    for m in pairs(tracked) do
        if not m.Parent then tracked[m]=nil;continue end
        if camera and (m:GetPivot().Position-camera.CFrame.Position).Magnitude>180 then continue end
        local kind=m:GetAttribute("VisualKind")
        if kind=="follower" then
            local owner=Players:GetPlayerByUserId(m:GetAttribute("OwnerUserId"))
            local root=owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local target=root.CFrame*CFrame.new(2.8,.7+math.sin(now*2)*.2,3.3)
                local current=m:GetPivot()
                m:PivotTo((current.Position-target.Position).Magnitude>30 and target or current:Lerp(target,1-math.exp(-7*step)))
            end
        else
            local center=m:GetAttribute("TankCenter")
            local index=m:GetAttribute("SwimIndex") or 1
            if center then
                if kind=="fish" then
                    local a=now*(.31+(index%3)*.035)+index*2.3
                    local r=Visual.World.SwimRadius
                    local pos=center+Vector3.new(math.cos(a)*r[1],math.sin(a*.7+index)*r[2],math.sin(a)*r[3])
                    local ahead=center+Vector3.new(math.cos(a+.08)*r[1],math.sin((a+.08)*.7+index)*r[2],math.sin(a+.08)*r[3])
                    m:PivotTo(CFrame.lookAt(pos,ahead)*CFrame.Angles(0,0,math.sin(a*3)*.05))
                else
                    local offset=Vector3.new(((index-1)%5-2)*2.8,-1+math.sin(now+index)*.07,index>5 and -2 or 2)
                    m:PivotTo(CFrame.new(center+offset)*CFrame.Angles(0,math.sin(now*.4+index)*.12,0))
                end
            end
        end
    end
    for bobber,state in pairs(bobbers) do
        if not bobber.Parent then bobbers[bobber]=nil;continue end
        local phase=bobber:GetAttribute("FishingPhase")
        if phase~=state.phase then
            if phase=="Waiting" then ripple(bobber.Position-Vector3.new(0,.15,0),Color3.fromRGB(212,235,218),3.5)
            elseif phase=="Reel" and state.phase=="Waiting" then
                ripple(bobber.Position,Color3.fromRGB(246,189,94),4.5)
                local alert=Instance.new("BillboardGui");alert.Size=UDim2.fromOffset(35,45);alert.StudsOffset=Vector3.new(0,1.8,0);alert.AlwaysOnTop=true;alert.Adornee=bobber
                local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text="!";label.TextSize=34;label.Font=Enum.Font.GothamBold;label.TextColor3=Color3.fromRGB(255,187,80);label.TextStrokeTransparency=.5;label.Parent=alert;alert.Parent=bobber
                Debris:AddItem(alert,1.1)
            end
            state.phase=phase
        end
        if phase=="Waiting" and now-state.rippleAt>2.2 then
            ripple(bobber.Position-Vector3.new(0,.15,0),Color3.fromRGB(193,222,207),2.2);state.rippleAt=now
        end
    end
end)
