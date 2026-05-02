-- Tracers.lua
-- Rysuje linie od lufy broni do miejsca trafienia po strzale z broni.
-- Linie znikają po czasie (fade out).

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Workspace    = game:GetService("Workspace")

local lplayer  = Players.LocalPlayer
local camera   = Workspace.CurrentCamera
local mouse    = lplayer:GetMouse()
local Visuals  = _G.ScoutCheat.Config.Visuals

-- Pula aktywnych linii: { line, spawnedAt, from, to }
local activeTracers = {}
local function reg(c) table.insert(getgenv().ScoutCheat._connections, c) return c end

local function screenPoint(worldPos)
    local p, onScreen = camera:WorldToScreenPoint(worldPos)
    return Vector2.new(p.X, p.Y), onScreen, p.Z
end

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
        and (tool.Handle:FindFirstChild("Tip") or tool.Handle:FindFirstChild("Barrel") or tool.Handle:FindFirstChild("Muzzle") or tool.Handle)
    if barrel and barrel:IsA("BasePart") then return barrel.Position end
    -- fallback: głowa lub kamera
    local char = lplayer.Character
    if char and char:FindFirstChild("Head") then return char.Head.Position end
    return camera.CFrame.Position
end

-- Logika podłączania do narzędzi w ekwipunku gracza
local toolConns = {}

local function hookTool(tool)
    if not tool:IsA("Tool") then return end
    -- Jeśli już podpięliśmy, pomiń
    for _, conn in ipairs(toolConns) do
        if conn.tool == tool then return end
    end

    local conn = tool.Activated:Connect(function()
        if not Visuals.BulletTracers then return end
        
        -- W typowych grach celujemy tam, gdzie myszka
        local origin = camera.CFrame.Position
        local target = mouse.Hit.Position
        local direction = (target - origin).Unit * 1000

        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {lplayer.Character}
        params.FilterType = Enum.RaycastFilterType.Exclude

        local result = Workspace:Raycast(origin, direction, params)
        local hitPos = result and result.Position or (origin + direction)
        local barrelPos = getBarrelPos(tool)
        
        spawnTracer(barrelPos, hitPos)
    end)
    
    table.insert(toolConns, {tool = tool, conn = reg(conn)})
end

local function hookCharacter(char)
    if not char then return end
    -- Podepnij już istniejące
    for _, child in ipairs(char:GetChildren()) do hookTool(child) end
    -- Podepnij te które zostaną wyciągnięte (dodane do postaci)
    reg(char.ChildAdded:Connect(hookTool))
end

-- Podepnij od razu też w plecaku gracza
local function hookBackpack(backpack)
    for _, child in ipairs(backpack:GetChildren()) do hookTool(child) end
    reg(backpack.ChildAdded:Connect(hookTool))
end

local function initPlayer()
    if lplayer.Character then hookCharacter(lplayer.Character) end
    reg(lplayer.CharacterAdded:Connect(hookCharacter))
    
    local backpack = lplayer:FindFirstChild("Backpack")
    if backpack then hookBackpack(backpack) end
    reg(lplayer.ChildAdded:Connect(function(child)
        if child:IsA("Backpack") then hookBackpack(child) end
    end))
end
initPlayer()

-- RenderStepped: animuj fade linii
reg(RunService.RenderStepped:Connect(function()
    if not Visuals.BulletTracers then
        -- Natychmiast usuń wszystkie aktywne tracery po wyłączeniu w configu
        for _, t in ipairs(activeTracers) do pcall(function() t.line:Remove() end) end
        activeTracers = {}
        return
    end

    local now   = tick()
    local alive = {}
    for _, t in ipairs(activeTracers) do
        local age  = now - t.spawnedAt
        local fade = Visuals.BulletTracerFadeTime
        if age >= fade then
            pcall(function() t.line:Remove() end)
        else
            local alpha = 1 - (age / fade)
            local sp, onS = screenPoint(t.from)
            local ep, onE = screenPoint(t.to)
            if onS or onE then
                t.line.From         = sp
                t.line.To           = ep
                t.line.Transparency = alpha
                t.line.Visible      = true
            else
                t.line.Visible = false
            end
            table.insert(alive, t)
        end
    end
    activeTracers = alive
end))

-- Czyszczenie przy unloadzie (Unload.lua po prostu je :Remove())
getgenv().ScoutCheat._cleanupTracers = function()
    for _, t in ipairs(activeTracers) do pcall(function() t.line:Remove() end) end
end


