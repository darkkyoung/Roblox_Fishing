-- Basic display only: one simple model per item; no effects, previews or decoration.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local localPlayer=Players.LocalPlayer
local visuals=workspace:WaitForChild("CollectionVisuals",15)
if not visuals then
    local status=game:GetService("ReplicatedStorage")
    warn("[FILAMENT CLIENT] CollectionVisuals unavailable. Boot="..tostring(status:GetAttribute("FilamentBootStatus"))
        .."; stage="..tostring(status:GetAttribute("FilamentBootStage")).."; "..tostring(status:GetAttribute("FilamentBootError")))
    return
end
local tracked={}
local function add(m) if m:IsA("Model") and m:GetAttribute("VisualKind") then tracked[m]=true end end
for _,m in ipairs(visuals:GetDescendants()) do add(m) end
visuals.DescendantAdded:Connect(add);visuals.DescendantRemoving:Connect(function(m) tracked[m]=nil end)
-- Visibility is a convenience; the server independently checks ownership and distance.
for _,node in ipairs(workspace:WaitForChild("World"):WaitForChild("Zones"):GetChildren()) do
    if string.sub(node.Name,1,12)=="AquariumPlot" then
        local prompt=node:WaitForChild("Console"):WaitForChild("Prompt")
        local function refresh() prompt.Enabled=node:GetAttribute("OwnerUserId")==localPlayer.UserId end
        node:GetAttributeChangedSignal("OwnerUserId"):Connect(refresh);refresh()
    end
end
local elapsed=0
RunService.RenderStepped:Connect(function(dt)
    elapsed+=dt;if elapsed<.05 then return end
    local step=elapsed;elapsed=0;local now=workspace:GetServerTimeNow()
    for m in pairs(tracked) do
        if not m.Parent then tracked[m]=nil;continue end
        if m:GetAttribute("VisualKind")=="follower" then
            local owner=Players:GetPlayerByUserId(m:GetAttribute("OwnerUserId"));local root=owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local target=root.CFrame*CFrame.new(2.5,.5,3)
                m:PivotTo((m:GetPivot().Position-target.Position).Magnitude>30 and target or m:GetPivot():Lerp(target,1-math.exp(-8*step)))
            end
        elseif m:GetAttribute("VisualKind")=="fish" then
            local p=m:GetAttribute("SlotPosition")
            if p then m:PivotTo(CFrame.new(p+Vector3.new(math.sin(now+(m:GetAttribute("SlotIndex") or 0))*.5,0,0))) end
        end
    end
end)
local function camera(character)
    local root=character:WaitForChild("HumanoidRootPart",8);local human=character:WaitForChild("Humanoid",8)
    if not root or not human then return end
    RunService.RenderStepped:Wait();local c=workspace.CurrentCamera
    if c and localPlayer.Character==character then
        c.CameraType=Enum.CameraType.Scriptable;c.CameraSubject=human
        c.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,10,18),root.Position+Vector3.new(0,0,-20));c.Focus=root.CFrame
        RunService.RenderStepped:Wait();c.CameraType=Enum.CameraType.Custom
    end
end
localPlayer.CharacterAdded:Connect(camera);if localPlayer.Character then task.spawn(camera,localPlayer.Character) end
