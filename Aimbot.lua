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
local currentTarget = nil
local curveSign = 1
local detectionTime = 0
local lastTarget = nil
local lastLostTime = 0
local overshootVector = Vector3.new(0,0,0)
local targetVelocity = Vector3.new(0,0,0)
local lastPos = nil
local lastPosTime = 0


local function reg(c) table.insert(getgenv().ScoutCheat._connections, c) return c end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = Aim.FOV_Enabled
FOVCircle.Radius = Aim.FOV_Radius
FOVCircle.Color = Aim.FOV_Color
FOVCircle.Thickness = Aim.FOV_Thickness
FOVCircle.Transparency = Aim.FOV_Transparency
FOVCircle.Filled = false
table.insert(getgenv().ScoutCheat._drawings, FOVCircle)

local function IsVisible(character, partName)
    local part = character:FindFirstChild(partName)
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

local BONES = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "RightUpperArm", "LeftUpperArm", "RightUpperLeg", "LeftUpperLeg"}

local function GetTarget()
    if Aim.TargetLock and currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid") and currentTarget.Character.Humanoid.Health > 0 then
        local part = currentTarget.Character:FindFirstChild(Aim.AimPart)
        if part then
            if not Aim.VisibleCheck or IsVisible(currentTarget.Character, part.Name) then
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local ml = UserInputService:GetMouseLocation()
                    local d = (Vector2.new(pos.X,pos.Y)-ml).Magnitude
                    if d <= Aim.FOV_Radius then
                        return currentTarget, d, part
                    end
                end
            end
        end
    end

    local closest, minDist, bestPart = nil, Aim.FOV_Radius, nil
    local ml = UserInputService:GetMouseLocation()
    for _,v in pairs(Players:GetPlayers()) do
        if v~=lplayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health>0 then
            if Aim.TeamCheck and v.Team==lplayer.Team then continue end
            
            local partsToCheck = {v.Character:FindFirstChild(Aim.AimPart)}
            if Aim.ClosestBone then
                partsToCheck = {}
                for _, boneName in ipairs(BONES) do
                    local b = v.Character:FindFirstChild(boneName)
                    if b then table.insert(partsToCheck, b) end
                end
            end
            
            -- Weighted Bone Selection (Probability)
            if Aim.WeightedHitZones and #partsToCheck > 1 then
                local r = math.random(1, 100)
                local selectedBone = "HumanoidRootPart"
                if r <= 30 then selectedBone = "Head"
                elseif r <= 80 then selectedBone = "UpperTorso"
                end
                local b = v.Character:FindFirstChild(selectedBone)
                if b then partsToCheck = {b} end
            end

            for _, part in ipairs(partsToCheck) do
                if not part then continue end
                if Aim.VisibleCheck and not IsVisible(v.Character, part.Name) then continue end
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X,pos.Y)-ml).Magnitude
                    if d < minDist then 
                        closest = v 
                        minDist = d 
                        bestPart = part 
                    end
                end
            end
        end
    end
    return closest, minDist, bestPart
end

reg(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Aim.AimKey or input.KeyCode == Aim.AimKey then
        aiming = true
        if Aim.Randomization then 
            randomOffset = Vector3.new((math.random()-0.5)*Aim.RandomIntensity, (math.random()-0.5)*Aim.RandomIntensity, (math.random()-0.5)*Aim.RandomIntensity) 
        end
    end
end))

reg(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Aim.AimKey or input.KeyCode == Aim.AimKey then aiming = false end
end))

reg(RunService.RenderStepped:Connect(function()
    local ml = UserInputService:GetMouseLocation()
    FOVCircle.Position = ml
    FOVCircle.Radius = Aim.FOV_Radius
    FOVCircle.Visible = Aim.FOV_Enabled

    if Aim.Enabled and aiming then
        -- Target Switching Delay
        if tick() - lastLostTime < Aim.SwitchDelay then return end

        local target, distToMouse, bestPart = GetTarget()
        if target and bestPart then
            if target ~= currentTarget then
                currentTarget = target
                curveSign = math.random() > 0.5 and 1 or -1
                detectionTime = tick()
                
                -- Initialize Overshoot
                if Aim.Overshooting then
                    local side = Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5).Unit
                    overshootVector = side * Aim.OvershootIntensity * (distToMouse / 50)
                else
                    overshootVector = Vector3.new(0,0,0)
                end
            end
            
            -- Reaction Delay
            if tick() - detectionTime < Aim.ReactionDelay then return end

            if distToMouse <= Aim.Deadzone then return end
            
            local tPos = bestPart.Position
            
            -- Velocity Tracking & Prediction
            if Aim.Prediction then
                local now = tick()
                if lastPos and now - lastPosTime > 0 then
                    local vel = (tPos - lastPos) / (now - lastPosTime)
                    targetVelocity = targetVelocity:Lerp(vel, 0.2)
                end
                lastPos = tPos
                lastPosTime = now
                
                local dist = (tPos - camera.CFrame.Position).Magnitude
                local travelTime = dist / 1000 -- Assuming 1000 studs/s projectile speed
                tPos = tPos + (targetVelocity * travelTime * Aim.PredictionStrength)
            end

            if Aim.Randomization then
                if tick() - lastOffsetChange > 0.2 then
                    randomOffset = randomOffset:Lerp(Vector3.new((math.random()-0.5)*Aim.RandomIntensity, (math.random()-0.5)*Aim.RandomIntensity, (math.random()-0.5)*Aim.RandomIntensity), 0.1)
                    lastOffsetChange = tick()
                end
                tPos = tPos + randomOffset
            end
            
            -- Overshoot Correction
            if Aim.Overshooting then
                overshootVector = overshootVector:Lerp(Vector3.new(0,0,0), 0.05)
                tPos = tPos + overshootVector
            end

            if Aim.CurveAiming then
                local toTarget = tPos - camera.CFrame.Position
                local dist = toTarget.Magnitude
                local upVec = Vector3.new(0, 1, 0)
                local rightVec = toTarget:Cross(upVec)
                if rightVec.Magnitude > 0 then rightVec = rightVec.Unit else rightVec = camera.CFrame.RightVector end
                local curveOffset = rightVec * curveSign * (distToMouse / Aim.FOV_Radius) * (dist * 0.1 * Aim.CurveStrength)
                tPos = tPos + curveOffset
            end

            local actualSmoothness = Aim.Smoothness
            
            -- Fitts's Law (Dynamic Smoothness)
            if Aim.FittsLaw then
                local distRatio = math.clamp(distToMouse / Aim.FOV_Radius, 0, 1)
                -- Faster for long distances, slower for micro-corrections
                actualSmoothness = actualSmoothness * (0.5 + distRatio * 1.5)
            end

            -- Humanized Dynamics (Acceleration & Braking)
            local currentLook = camera.CFrame.LookVector
            local targetLook = (tPos - camera.CFrame.Position).Unit
            local angle = math.acos(math.clamp(currentLook:Dot(targetLook), -1, 1))
            local angleDeg = math.deg(angle)

            if Aim.Acceleration > 0 or Aim.Braking > 0 then
                local brakingFactor = math.clamp(angleDeg / (Aim.FOV_Radius * 0.5), Aim.Braking * 0.1, 1)
                actualSmoothness = actualSmoothness * brakingFactor
            end

            if Aim.CurveSmoothing then
                actualSmoothness = actualSmoothness * math.clamp(distToMouse/Aim.FOV_Radius, 0.15, 1)
            end
            
            if Aim.SmoothnessVariance then
                actualSmoothness = actualSmoothness + (math.random() - 0.5) * (actualSmoothness * 0.2)
            end

            -- Micro-tremor (simulates hand shaking)
            if Aim.MicroTremor then
                local tremor = Vector3.new(
                    (math.random() - 0.5) * 0.05 * Aim.TremorIntensity,
                    (math.random() - 0.5) * 0.05 * Aim.TremorIntensity,
                    (math.random() - 0.5) * 0.05 * Aim.TremorIntensity
                )
                tPos = tPos + tremor
            end

            camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, tPos), math.clamp(actualSmoothness, 0.005, 1))
        else
            if currentTarget then
                lastLostTime = tick()
                currentTarget = nil
                lastPos = nil
            end
        end
    end
end))

