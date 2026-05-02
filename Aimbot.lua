local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local lplayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local Aim = _G.ScoutCheat.Config.Aimbot
local aiming = false
local randomOffset = Vector3.new(0,0,0)
local lastOffsetChange = tick()


local function reg(c) table.insert(getgenv().ScoutCheat._connections, c) return c end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = Aim.FOV_Enabled
FOVCircle.Radius = Aim.FOV_Radius
FOVCircle.Color = Aim.FOV_Color
FOVCircle.Thickness = Aim.FOV_Thickness
FOVCircle.Transparency = Aim.FOV_Transparency
FOVCircle.Filled = false
table.insert(getgenv().ScoutCheat._drawings, FOVCircle)

local function IsVisible(character, aimPart)
    local part = character:FindFirstChild(aimPart)
    if not part then return false end
    local origin = camera.CFrame.Position
    local target = part.Position
    local direction = (target - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character, lplayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(origin, direction, rayParams)
    return result == nil
end

local function GetTarget()
    local closest, minDist = nil, Aim.FOV_Radius
    for _,v in pairs(Players:GetPlayers()) do
        if v~=lplayer and v.Character and v.Character:FindFirstChild(Aim.AimPart) and v.Character:FindFirstChild("Humanoid") then
            if v.Character.Humanoid.Health>0 then
                if Aim.TeamCheck and v.Team==lplayer.Team then continue end
                if Aim.VisibleCheck and not IsVisible(v.Character, Aim.AimPart) then continue end
                local pos, onScreen = camera:WorldToViewportPoint(v.Character[Aim.AimPart].Position)
                if onScreen then
                    local ml = UserInputService:GetMouseLocation()
                    local d = (Vector2.new(pos.X,pos.Y)-ml).Magnitude
                    if d < minDist then closest=v minDist=d end
                end
            end
        end
    end
    return closest, minDist
end

reg(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Aim.AimKey then
        aiming = true
        if Aim.Randomization then 
            randomOffset = Vector3.new((math.random()-0.5)*Aim.RandomIntensity, (math.random()-0.5)*Aim.RandomIntensity, (math.random()-0.5)*Aim.RandomIntensity) 
        end
    end
end))

reg(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Aim.AimKey then aiming=false end
end))

reg(RunService.RenderStepped:Connect(function()
    local ml = UserInputService:GetMouseLocation()
    FOVCircle.Position = ml
    FOVCircle.Radius = Aim.FOV_Radius
    FOVCircle.Visible = Aim.FOV_Enabled

    if Aim.Enabled and aiming then
        local target, distToMouse = GetTarget()
        if target and target.Character and target.Character:FindFirstChild(Aim.AimPart) then
            if distToMouse <= Aim.Deadzone then return end
            local tPos = target.Character[Aim.AimPart].Position
            if Aim.Randomization then
                if tick() - lastOffsetChange > 0.2 then
                    randomOffset = randomOffset:Lerp(Vector3.new((math.random()-0.5)*Aim.RandomIntensity, (math.random()-0.5)*Aim.RandomIntensity, (math.random()-0.5)*Aim.RandomIntensity), 0.1)
                    lastOffsetChange = tick()
                end
                tPos = tPos + randomOffset
            end
            local actualSmoothness = Aim.Smoothness
            if Aim.CurveSmoothing then
                actualSmoothness = actualSmoothness * math.clamp(distToMouse/Aim.FOV_Radius, 0.15, 1)
            end
            camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, tPos), actualSmoothness)
        end
    end
end))

