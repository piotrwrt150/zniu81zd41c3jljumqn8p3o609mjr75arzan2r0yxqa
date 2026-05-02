-- Tracers.lua
-- Rysuje linie od lufy broni do miejsca trafienia po każdym strzale.
-- Linie znikają po BulletTracerFadeTime sekundach (fade out).

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Workspace    = game:GetService("Workspace")

local lplayer  = Players.LocalPlayer
local camera   = Workspace.CurrentCamera
local Visuals  = _G.ScoutCheat.Config.Visuals

-- Pula aktywnych linii: { line, spawnedAt, startPos, endPos }
local activeTracers = {}
local toolConns     = {}   -- połączenia narzędzi

local function screenPoint(worldPos)
    local p, onScreen = camera:WorldToScreenPoint(worldPos)
    return Vector2.new(p.X, p.Y), onScreen, p.Z
end

-- Tworzy jedną linię tracera (nie Drawing.Line – zamiast tego Square hack nie jest potrzebny;
-- używamy Drawing.Line bezpośrednio).
local function spawnTracer(from, to)
    if not Visuals.BulletTracers then return end
    local line = Drawing.new("Line")
    line.Thickness  = Visuals.BulletTracerThickness
    line.Color      = Visuals.BulletTracerColor
    line.Transparency = 1
    line.Visible    = true
    line.ZIndex     = 5
    table.insert(activeTracers, {
        line      = line,
        spawnedAt = tick(),
        from      = from,
        to        = to,
    })
end

-- Szuka lufy / tip narzędzia
local function getBarrelPos(tool)
    local barrel = tool:FindFirstChild("Handle")
        and (tool.Handle:FindFirstChild("Tip") or tool.Handle:FindFirstChild("Barrel"))
    if barrel then return barrel.WorldPosition end
    -- fallback: środek kamery
    return camera.CFrame.Position
end

-- Podłącza listener do każdego narzędzia postaci gracza
local function hookCharacter(char)
    if not char then return end

    char.ChildAdded:Connect(function(child)
        -- czekaj aż narzędzie będzie kompletne
        if not child:IsA("Tool") then return end
        local tool = child

        -- Szukamy zdalnego zdarzenia "Fire", "Shoot", "OnFired" itp.
        local function tryConnect(remote)
            if remote:IsA("RemoteEvent") or remote:IsA("BindableEvent") then
                local conn = remote.OnClientEvent:Connect(function()
                    -- Raycast w kierunku, w którym patrzy kamera
                    local origin    = camera.CFrame.Position
                    local direction = camera.CFrame.LookVector * 1000
                    local params    = RaycastParams.new()
                    params.FilterDescendantsInstances = {char, lplayer.Character}
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    local result = Workspace:Raycast(origin, direction, params)
                    local hitPos = result and result.Position or (origin + direction)
                    local barrelPos = getBarrelPos(tool)
                    spawnTracer(barrelPos, hitPos)
                end)
                table.insert(toolConns, conn)
            end
        end

        -- Próbuj podpiąć pod istniejące eventy
        for _, desc in ipairs(tool:GetDescendants()) do tryConnect(desc) end
        tool.DescendantAdded:Connect(tryConnect)

        -- Fallback: wykrywaj strzał przez animacje (ChildAdded "BulletImpact", Part itp.)
        -- oraz przez UserInputService (MouseButton1) jako uniwersalny trigger
    end)
end

-- InputService fallback: strzelaj tracer gdy LMB kliknięty i gracz ma broń
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local char = lplayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Raycast prosto z kamery
    local origin    = camera.CFrame.Position
    local direction = camera.CFrame.LookVector * 1000
    local params    = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(origin, direction, params)
    local hitPos = result and result.Position or (origin + direction)
    local barrelPos = getBarrelPos(tool)
    spawnTracer(barrelPos, hitPos)
end)

-- Podłącz do aktualnej postaci i jej zmian
local function initPlayer()
    if lplayer.Character then hookCharacter(lplayer.Character) end
    lplayer.CharacterAdded:Connect(hookCharacter)
end
initPlayer()

-- RenderStepped: animuj fade linii
RunService.RenderStepped:Connect(function()
    local now   = tick()
    local alive = {}
    for _, t in ipairs(activeTracers) do
        local age  = now - t.spawnedAt
        local fade = Visuals.BulletTracerFadeTime
        if age >= fade then
            pcall(function() t.line:Remove() end)
        else
            local alpha = 1 - (age / fade)   -- 1 = pełna widoczność, 0 = niewidoczna
            local sp, onS = screenPoint(t.from)
            local ep, onE = screenPoint(t.to)
            if onS or onE then
                t.line.From         = sp
                t.line.To           = ep
                t.line.Transparency = alpha
                t.line.Visible      = Visuals.BulletTracers
            else
                t.line.Visible = false
            end
            table.insert(alive, t)
        end
    end
    activeTracers = alive
end)

-- Cleanup
getgenv().ScoutCheat._cleanupTracers = function()
    for _, t in ipairs(activeTracers) do pcall(function() t.line:Remove() end) end
    activeTracers = {}
    for _, c in ipairs(toolConns) do pcall(function() c:Disconnect() end) end
    toolConns = {}
    print("[Tracers] Rozładowano.")
end
