local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local visuals=workspace:WaitForChild("Visuals")
local tracked={}
local function add(model)
    if model:IsA("Model") and model:GetAttribute("VisualKind") then tracked[model]=true end
end
for _,v in ipairs(visuals:GetDescendants()) do add(v) end
visuals.DescendantAdded:Connect(add)
visuals.DescendantRemoving:Connect(function(v) tracked[v]=nil end)
local elapsed=0
RunService.RenderStepped:Connect(function(dt)
    elapsed+=dt
    if elapsed<1/30 then return end
    elapsed=0
    local now=workspace:GetServerTimeNow()
    for model in pairs(tracked) do
        if not model.Parent then tracked[model]=nil;continue end
        local kind=model:GetAttribute("VisualKind")
        if kind=="follower" then
            local owner=Players:GetPlayerByUserId(model:GetAttribute("OwnerUserId"))
            local root=owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local target=root.CFrame*CFrame.new(3,1+math.sin(now*2)*.35,3)
                model:PivotTo(model:GetPivot():Lerp(target,.18))
            end
        else
            local center=model:GetAttribute("TankCenter")
            local i=model:GetAttribute("SwimIndex") or 1
            if center then
                if kind=="fish" then
                    local t=now*.45+i*1.7
                    local pos=center+Vector3.new(math.cos(t)*7,math.sin(t*.7+i)*1.2,math.sin(t)*3.2)
                    local nextPos=center+Vector3.new(math.cos(t+.08)*7,math.sin((t+.08)*.7+i)*1.2,math.sin(t+.08)*3.2)
                    model:PivotTo(CFrame.lookAt(pos,nextPos))
                else
                    model:PivotTo(CFrame.new(center+Vector3.new(((i-1)%5-2)*3.4,-1+math.sin(now+i)*.15,2))*CFrame.Angles(0,now*.35,0))
                end
            end
        end
    end
end)
