-- One-time spawn framing, then immediately hand control back to Roblox's camera.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Visual=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").VisualConfig)
local player=Players.LocalPlayer
local generation=0
local function frame(character)
    generation+=1
    local token=generation
    local root=character:WaitForChild("HumanoidRootPart",8)
    local humanoid=character:WaitForChild("Humanoid",8)
    if not root or not humanoid or token~=generation then return end
    RunService.RenderStepped:Wait()
    local camera=workspace.CurrentCamera
    if not camera or player.Character~=character then return end
    local offset=Visual.World.CameraOffset
    local target=Visual.World.CameraTarget
    camera.CameraSubject=humanoid
    camera.CameraType=Enum.CameraType.Scriptable
    camera.FieldOfView=65
    camera.CFrame=CFrame.lookAt(root.Position+Vector3.new(offset[1],offset[2],offset[3]),Vector3.new(target[1],target[2],target[3]))
    camera.Focus=CFrame.new(root.Position)
    RunService.RenderStepped:Wait()
    if token==generation then camera.CameraType=Enum.CameraType.Custom end
end
player.CharacterAdded:Connect(frame)
if player.Character then task.spawn(frame,player.Character) end
