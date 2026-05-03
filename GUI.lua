local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local Aim     = _G.ScoutCheat.Config.Aimbot
local Visuals = _G.ScoutCheat.Config.Visuals
local ESPConf = _G.ScoutCheat.Config.ESP
local GUIConf = _G.ScoutCheat.Config.GUI

local THEMES = {
    Purple = Color3.fromRGB(100, 100, 255),
    Red    = Color3.fromRGB(255, 100, 100),
    Green  = Color3.fromRGB(100, 255, 100),
    Blue   = Color3.fromRGB(100, 200, 255),
    Pink   = Color3.fromRGB(255, 100, 200),
    Orange = Color3.fromRGB(255, 150, 50)
}
local THEME_NAMES = {"Purple", "Red", "Green", "Blue", "Pink", "Orange"}

-- --- Config Save / Load -------------------------------------------------------
local CONFIG_FILE = "scout_cheat_config.json"

local function SaveConfig()
    local data = {
        Aim_Enabled        = Aim.Enabled,
        Aim_Smoothness     = Aim.Smoothness,
        Aim_FOV_Radius     = Aim.FOV_Radius,
        Aim_FOV_Enabled    = Aim.FOV_Enabled,
        Aim_AimPart        = Aim.AimPart,
        Aim_TeamCheck      = Aim.TeamCheck,
        Aim_Deadzone       = Aim.Deadzone,
        Aim_VisibleCheck   = Aim.VisibleCheck,
        Aim_ClosestBone    = Aim.ClosestBone,
        Aim_CurveAiming    = Aim.CurveAiming,
        Aim_CurveStrength  = Aim.CurveStrength,
        Aim_SmoothVar      = Aim.SmoothnessVariance,
        Aim_AimKey         = tostring(Aim.AimKey),
        Vis_Fullbright     = Visuals.Fullbright,
        Vis_NoFog          = Visuals.NoFog,
        Vis_Watermark      = Visuals.Watermark,
        ESP_Enabled        = ESPConf.Enabled,
        ESP_Boxes          = ESPConf.Drawing.Boxes.Full.Enabled,
        ESP_Names          = ESPConf.Drawing.Names.Enabled,
        ESP_Health         = ESPConf.Drawing.Healthbar.Enabled,
        ESP_Distance       = ESPConf.Options.Distance,
        GUI_Theme          = GUIConf.Theme
    }
    if writefile then
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
        print("[Config] Zapisano do " .. CONFIG_FILE)
    else
        warn("[Config] Executor nie wspiera writefile!")
    end
end

local function LoadConfig()
    if readfile and isfile and isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and data then
            local function b(new, old) return new ~= nil and new or old end
            Aim.Enabled            = b(data.Aim_Enabled,       Aim.Enabled)
            Aim.Smoothness         = b(data.Aim_Smoothness,    Aim.Smoothness)
            Aim.FOV_Radius         = b(data.Aim_FOV_Radius,    Aim.FOV_Radius)
            Aim.FOV_Enabled        = b(data.Aim_FOV_Enabled,   Aim.FOV_Enabled)
            Aim.AimPart            = b(data.Aim_AimPart,       Aim.AimPart)
            Aim.TeamCheck          = b(data.Aim_TeamCheck,     Aim.TeamCheck)
            Aim.Deadzone           = b(data.Aim_Deadzone,      Aim.Deadzone)
            Aim.VisibleCheck       = b(data.Aim_VisibleCheck,  Aim.VisibleCheck)
            Aim.ClosestBone        = b(data.Aim_ClosestBone,   Aim.ClosestBone)
            Aim.CurveAiming        = b(data.Aim_CurveAiming,   Aim.CurveAiming)
            Aim.CurveStrength      = b(data.Aim_CurveStrength, Aim.CurveStrength)
            Aim.SmoothnessVariance = b(data.Aim_SmoothVar,     Aim.SmoothnessVariance)
            
            if data.Aim_AimKey then
                local s = data.Aim_AimKey
                if s:find("UserInputType") then
                    Aim.AimKey = Enum.UserInputType[s:split(".")[3]]
                elseif s:find("KeyCode") then
                    Aim.AimKey = Enum.KeyCode[s:split(".")[3]]
                end
            end

            Visuals.Fullbright     = b(data.Vis_Fullbright,    Visuals.Fullbright)
            Visuals.NoFog          = b(data.Vis_NoFog,         Visuals.NoFog)
            Visuals.Watermark      = b(data.Vis_Watermark,     Visuals.Watermark)
            ESPConf.Enabled        = b(data.ESP_Enabled,       ESPConf.Enabled)
            ESPConf.Drawing.Boxes.Full.Enabled = b(data.ESP_Boxes, ESPConf.Drawing.Boxes.Full.Enabled)
            ESPConf.Drawing.Names.Enabled      = b(data.ESP_Names, ESPConf.Drawing.Names.Enabled)
            ESPConf.Drawing.Healthbar.Enabled  = b(data.ESP_Health, ESPConf.Drawing.Healthbar.Enabled)
            ESPConf.Options.Distance           = b(data.ESP_Distance, ESPConf.Options.Distance)
            GUIConf.Theme          = b(data.GUI_Theme,         GUIConf.Theme)
            print("[Config] Wczytano z " .. CONFIG_FILE)
        end
    end
end

LoadConfig()

-- --- Drawing helpers ----------------------------------------------------------
local function reg(c)  table.insert(getgenv().ScoutCheat._connections, c) return c end
local function regD(d) table.insert(getgenv().ScoutCheat._drawings,     d) return d end

local function mkRect(z) local r = Drawing.new("Square") r.Filled=true r.Visible=false r.ZIndex=z return regD(r) end
local function mkText(s,z) local t = Drawing.new("Text") t.Size=s t.Font=Drawing.Fonts.UI t.Visible=false t.ZIndex=z return regD(t) end
local function mkLine(z) local l = Drawing.new("Line") l.Visible=false l.ZIndex=z return regD(l) end

-- --- GUI state ----------------------------------------------------------------
local GUI = { 
    Visible = false, 
    X = 120, Y = 80, 
    W = 460, H = 340, 
    Dragging = false, 
    DragOffset = Vector2.new(), 
    Tab = "Aimbot", 
    Binding = false,
    SidebarW = 100,
    HeaderH = 34
}

local COL = {
    BG     = Color3.fromRGB(15, 15, 25),
    Sidebar = Color3.fromRGB(22, 22, 35),
    Panel  = Color3.fromRGB(28, 28, 48),
    Accent = THEMES[GUIConf.Theme] or THEMES.Purple,
    Text   = Color3.new(1, 1, 1),
    Sub    = Color3.fromRGB(160, 160, 185),
    Slider = Color3.fromRGB(45, 45, 75),
    Off    = Color3.fromRGB(60, 60, 75),
    Danger = Color3.fromRGB(220, 60, 60),
    Border = Color3.fromRGB(45, 45, 65)
}

local function UpdateAccent()
    COL.Accent = THEMES[GUIConf.Theme] or THEMES.Purple
end
UpdateAccent()
-- --- Drawing objects ----------------------------------------------------------
local ALL = {}
local function trackD(d) table.insert(ALL, d); return d; end

local dBG       = trackD(mkRect(10))
local dSidebar   = trackD(mkRect(11))
local dHeader    = trackD(mkRect(11))
local dTitle     = trackD(mkText(16,12))
local dClose     = trackD(mkText(18,12))
local dBorder    = trackD(mkLine(15))

-- Tabs
local tabBtns = {
    Aimbot   = { BG = trackD(mkRect(12)), Lbl = trackD(mkText(14,13)) },
    Visuals  = { BG = trackD(mkRect(12)), Lbl = trackD(mkText(14,13)) },
    Settings = { BG = trackD(mkRect(12)), Lbl = trackD(mkText(14,13)) }
}

-- Content Area
local cBG = trackD(mkRect(11))

-- Generic Toggles Pool (we need max ~10 toggles per tab)
local toggles = {}
for i=1, 10 do
    table.insert(toggles, { BG=trackD(mkRect(12)), Fill=trackD(mkRect(13)), Lbl=trackD(mkText(13,13)) })
end

-- Generic Sliders Pool (we need max ~5 sliders per tab)
local sliders = {}
for i=1, 5 do
    table.insert(sliders, { T=trackD(mkRect(12)), F=trackD(mkRect(13)), Lbl=trackD(mkText(13,13)), Val=trackD(mkText(13,13)) })
end

-- Dropdown / Buttons (Theme, Aim Part, Unload)
local btn1BG = trackD(mkRect(12)); local btn1Lbl = trackD(mkText(13,13)); local btn1Val = trackD(mkText(13,13))
local btn2BG = trackD(mkRect(12)); local btn2Lbl = trackD(mkText(13,13)); local btn2Val = trackD(mkText(13,13))
local btnUnload = trackD(mkRect(12)); local lblUnload = trackD(mkText(14,13))

local SLIDER_W = 180
local SLIDER_H = 8
local sliderActive = nil
local activeTogglesCount = 0
local activeSlidersCount = 0

local function setAll(v) for _,d in pairs(ALL) do d.Visible=v end end

local function drawToggle(idx, yOff, label, state)
    local tw, th = 34, 18
    local x = GUI.X + GUI.SidebarW + 20
    local w = GUI.W - GUI.SidebarW - 40
    local t = toggles[idx]
    
    t.BG.Position   = Vector2.new(x + w - tw, GUI.Y + GUI.HeaderH + yOff)
    t.BG.Size       = Vector2.new(tw, th)
    t.BG.Color      = COL.Slider
    t.BG.Visible    = true
    
    t.Fill.Position = Vector2.new(x + w - tw + (state and tw - th or 0), GUI.Y + GUI.HeaderH + yOff)
    t.Fill.Size     = Vector2.new(th, th)
    t.Fill.Color    = state and COL.Accent or COL.Off
    t.Fill.Visible  = true
    
    t.Lbl.Position  = Vector2.new(x, GUI.Y + GUI.HeaderH + yOff + 2)
    t.Lbl.Text      = label
    t.Lbl.Color     = COL.Text
    t.Lbl.Visible   = true
end

local function drawSlider(idx, yOff, label, pct, valStr)
    local x = GUI.X + GUI.SidebarW + 20
    local w = GUI.W - GUI.SidebarW - 40
    local s = sliders[idx]
    
    s.Lbl.Position = Vector2.new(x, GUI.Y + GUI.HeaderH + yOff)
    s.Lbl.Text     = label
    s.Lbl.Color    = COL.Sub
    s.Lbl.Visible  = true
    
    local sw = w - 80
    s.T.Position   = Vector2.new(x, GUI.Y + GUI.HeaderH + yOff + 16)
    s.T.Size       = Vector2.new(sw, 6)
    s.T.Color      = COL.Slider
    s.T.Visible    = true
    
    s.F.Position   = Vector2.new(x, GUI.Y + GUI.HeaderH + yOff + 16)
    s.F.Size       = Vector2.new(math.max(2, sw * pct), 6)
    s.F.Color      = COL.Accent
    s.F.Visible    = true
    
    s.Val.Position = Vector2.new(x + sw + 10, GUI.Y + GUI.HeaderH + yOff + 12)
    s.Val.Text     = valStr
    s.Val.Color    = COL.Text
    s.Val.Visible  = true
end

local function drawButton(bg, lbl, valTxt, yOff, text, valText)
    local x = GUI.X + GUI.SidebarW + 20
    local w = GUI.W - GUI.SidebarW - 40
    
    bg.Position  = Vector2.new(x, GUI.Y + GUI.HeaderH + yOff)
    bg.Size      = Vector2.new(w, 24)
    bg.Color     = COL.Panel
    bg.Visible   = true
    
    lbl.Position = Vector2.new(x + 8, GUI.Y + GUI.HeaderH + yOff + 5)
    lbl.Text     = text
    lbl.Color    = COL.Sub
    lbl.Visible  = true
    
    if valTxt then
        valTxt.Position = Vector2.new(x + w - 100, GUI.Y + GUI.HeaderH + yOff + 5)
        valTxt.Text     = valText
        valTxt.Color    = COL.Accent
        valTxt.Visible  = true
    end
end

local function updateGUI()
    if not GUI.Visible then setAll(false) return end
    UpdateAccent()
    setAll(false)
    
    local x,y,w,h = GUI.X, GUI.Y, GUI.W, GUI.H
    local sw, hh = GUI.SidebarW, GUI.HeaderH

    -- Main BG
    dBG.Position = Vector2.new(x, y) dBG.Size = Vector2.new(w, h) dBG.Color = COL.BG dBG.Transparency = 0.9 dBG.Visible = true
    dSidebar.Position = Vector2.new(x, y + hh) dSidebar.Size = Vector2.new(sw, h - hh) dSidebar.Color = COL.Sidebar dSidebar.Visible = true
    dHeader.Position = Vector2.new(x, y) dHeader.Size = Vector2.new(w, hh) dHeader.Color = COL.Sidebar dHeader.Visible = true
    
    dTitle.Position = Vector2.new(x + 12, y + 8) dTitle.Text = "ScoutCheat Premium" dTitle.Color = COL.Accent dTitle.Visible = true
    dClose.Position = Vector2.new(x + w - 22, y + 8) dClose.Text = "X" dClose.Color = COL.Danger dClose.Visible = true
    
    -- Tabs (Sidebar)
    local function drawTab(name, idx, label)
        local btn = tabBtns[name]
        local ty = y + hh + (idx - 1) * 40
        btn.BG.Position = Vector2.new(x, ty) btn.BG.Size = Vector2.new(sw, 40)
        btn.BG.Color = GUI.Tab == name and COL.Accent or COL.Sidebar
        btn.BG.Transparency = GUI.Tab == name and 0.2 or 1
        btn.BG.Visible = true
        
        btn.Lbl.Position = Vector2.new(x + 15, ty + 12)
        btn.Lbl.Text = label
        btn.Lbl.Color = GUI.Tab == name and COL.Text or COL.Sub
        btn.Lbl.Visible = true
    end
    
    drawTab("Aimbot", 1, "Aimbot")
    drawTab("Visuals", 2, "Visuals")
    drawTab("Settings", 3, "Settings")

    cBG.Position = Vector2.new(x + sw + 5, y + hh + 5) cBG.Size = Vector2.new(w - sw - 10, h - hh - 10) cBG.Color = COL.Panel cBG.Visible = true

    if GUI.Tab == "Aimbot" then
        drawToggle(1, 15, "Enabled", Aim.Enabled)
        drawToggle(2, 40, "Visible Check", Aim.VisibleCheck)
        drawToggle(3, 65, "Closest Bone", Aim.ClosestBone)
        drawToggle(4, 90, "Curve Aiming", Aim.CurveAiming)
        drawToggle(5, 115, "Smoothness Var.", Aim.SmoothnessVariance)
        drawToggle(6, 140, "FOV Circle", Aim.FOV_Enabled)

        drawSlider(1, 175, "Smoothness", (Aim.Smoothness - 0.01) / 0.29, string.format("%.2f", Aim.Smoothness))
        drawSlider(2, 215, "FOV Radius", (Aim.FOV_Radius - 20) / 280, tostring(math.floor(Aim.FOV_Radius)))
        
        drawButton(btn1BG, btn1Lbl, btn1Val, 260, "Target Part:", Aim.AimPart)
        
        local keyName = tostring(Aim.AimKey):split(".")[3]
        drawButton(btn2BG, btn2Lbl, btn2Val, 290, "Aim Keybind:", GUI.Binding and "..." or keyName)

    elseif GUI.Tab == "Visuals" then
        drawToggle(1, 15, "ESP Master Switch", ESPConf.Enabled)
        drawToggle(2, 40, "Player Boxes", ESPConf.Drawing.Boxes.Full.Enabled)
        drawToggle(3, 65, "Health Bar", ESPConf.Drawing.Healthbar.Enabled)
        drawToggle(4, 90, "Player Names", ESPConf.Drawing.Names.Enabled)
        drawToggle(5, 115, "Distance Info", ESPConf.Options.Distance)
        
        drawToggle(6, 150, "Fullbright", Visuals.Fullbright)
        drawToggle(7, 175, "No Fog", Visuals.NoFog)

    elseif GUI.Tab == "Settings" then
        drawToggle(1, 15, "Watermark", Visuals.Watermark)
        drawButton(btn1BG, btn1Lbl, btn1Val, 45, "Theme Color:", GUIConf.Theme)

        btnUnload.Position = Vector2.new(x + sw + 20, y + h - 45)
        btnUnload.Size = Vector2.new(w - sw - 40, 30)
        btnUnload.Color = COL.Danger btnUnload.Visible = true
        lblUnload.Position = Vector2.new(x + sw + (w - sw) / 2 - 45, y + h - 38)
        lblUnload.Text = "UNLOAD SCRIPT" lblUnload.Color = COL.Text lblUnload.Visible = true
    end
end

-- --- Input --------------------------------------------------------------------
local function inBox(mx,my,bx,by,bw,bh) return mx>=bx and mx<=bx+bw and my>=by and my<=by+bh end

reg(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K     then GUI.Visible=not GUI.Visible updateGUI() return end
    if input.KeyCode == Enum.KeyCode.L     then SaveConfig() return end
    if input.KeyCode == Enum.KeyCode.J     then LoadConfig() updateGUI() return end
    if input.KeyCode == Enum.KeyCode.Delete then
        if getgenv().ScoutUnload then getgenv().ScoutUnload() end
        GUI.Visible=false setAll(false) return
    end
    if GUI.Binding then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Aim.AimKey = input.KeyCode
        else
            Aim.AimKey = input.UserInputType
        end
        GUI.Binding = false
        updateGUI()
        return
    end

    local ml = UserInputService:GetMouseLocation()
    local mx,my = ml.X, ml.Y
    local x,y,w,h = GUI.X, GUI.Y, GUI.W, GUI.H
    local sw, hh = GUI.SidebarW, GUI.HeaderH

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if inBox(mx,my, x + w - 22, y + 8, 16, 16) then GUI.Visible = false setAll(false) return end
        if inBox(mx,my, x, y, w, hh) then GUI.Dragging = true GUI.DragOffset = Vector2.new(mx - x, my - y) return end

        -- Sidebar clicks
        if inBox(mx,my, x, y + hh, sw, 40) then GUI.Tab = "Aimbot" updateGUI() return end
        if inBox(mx,my, x, y + hh + 40, sw, 40) then GUI.Tab = "Visuals" updateGUI() return end
        if inBox(mx,my, x, y + hh + 80, sw, 40) then GUI.Tab = "Settings" updateGUI() return end

        if GUI.Tab == "Aimbot" then
            local cx = x + sw + 20
            local cw = w - sw - 40
            if inBox(mx,my, cx, y + hh + 15, cw, 20) then Aim.Enabled = not Aim.Enabled updateGUI() end
            if inBox(mx,my, cx, y + hh + 40, cw, 20) then Aim.VisibleCheck = not Aim.VisibleCheck updateGUI() end
            if inBox(mx,my, cx, y + hh + 65, cw, 20) then Aim.ClosestBone = not Aim.ClosestBone updateGUI() end
            if inBox(mx,my, cx, y + hh + 90, cw, 20) then Aim.CurveAiming = not Aim.CurveAiming updateGUI() end
            if inBox(mx,my, cx, y + hh + 115, cw, 20) then Aim.SmoothnessVariance = not Aim.SmoothnessVariance updateGUI() end
            if inBox(mx,my, cx, y + hh + 140, cw, 20) then Aim.FOV_Enabled = not Aim.FOV_Enabled updateGUI() end
            
            local slw = cw - 80
            if inBox(mx,my, cx, y + hh + 175, slw, 30) then sliderActive = 1 end
            if inBox(mx,my, cx, y + hh + 215, slw, 30) then sliderActive = 2 end

            if inBox(mx,my, cx, y + hh + 260, cw, 24) then
                local p = {"Head", "HumanoidRootPart", "UpperTorso"}
                Aim.AimPart = p[(table.find(p, Aim.AimPart) or 1) % 3 + 1] updateGUI()
            end
            if inBox(mx,my, cx, y + hh + 290, cw, 24) then
                GUI.Binding = true updateGUI()
            end

        elseif GUI.Tab == "Visuals" then
            local cx = x + sw + 20
            local cw = w - sw - 40
            if inBox(mx,my, cx, y + hh + 15, cw, 20) then ESPConf.Enabled = not ESPConf.Enabled updateGUI() end
            if inBox(mx,my, cx, y + hh + 40, cw, 20) then ESPConf.Drawing.Boxes.Full.Enabled = not ESPConf.Drawing.Boxes.Full.Enabled updateGUI() end
            if inBox(mx,my, cx, y + hh + 65, cw, 20) then ESPConf.Drawing.Healthbar.Enabled = not ESPConf.Drawing.Healthbar.Enabled updateGUI() end
            if inBox(mx,my, cx, y + hh + 90, cw, 20) then ESPConf.Drawing.Names.Enabled = not ESPConf.Drawing.Names.Enabled updateGUI() end
            if inBox(mx,my, cx, y + hh + 115, cw, 20) then ESPConf.Options.Distance = not ESPConf.Options.Distance updateGUI() end
            if inBox(mx,my, cx, y + hh + 150, cw, 20) then Visuals.Fullbright = not Visuals.Fullbright updateGUI() end
            if inBox(mx,my, cx, y + hh + 175, cw, 20) then Visuals.NoFog = not Visuals.NoFog updateGUI() end

        elseif GUI.Tab == "Settings" then
            local cx = x + sw + 20
            local cw = w - sw - 40
            if inBox(mx,my, cx, y + hh + 15, cw, 20) then Visuals.Watermark = not Visuals.Watermark updateGUI() end
            if inBox(mx,my, cx, y + hh + 45, cw, 24) then
                local idx = table.find(THEME_NAMES, GUIConf.Theme) or 1
                GUIConf.Theme = THEME_NAMES[idx % #THEME_NAMES + 1] updateGUI()
            end
            if inBox(mx,my, cx, y + h - 45, cw, 30) then
                if getgenv().ScoutUnload then getgenv().ScoutUnload() end
                GUI.Visible = false setAll(false)
            end
        end
    end
end))

reg(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        GUI.Dragging = false sliderActive = nil
    end
end))

reg(RunService.RenderStepped:Connect(function()
    local ml = UserInputService:GetMouseLocation()
    if GUI.Dragging then
        GUI.X = ml.X - GUI.DragOffset.X GUI.Y = ml.Y - GUI.DragOffset.Y updateGUI()
    end
    if sliderActive and GUI.Tab == "Aimbot" then
        local cx = GUI.X + GUI.SidebarW + 20
        local cw = GUI.W - GUI.SidebarW - 40
        local slw = cw - 80
        local pct = math.clamp((ml.X - cx) / slw, 0, 1)
        if     sliderActive == 1 then Aim.Smoothness = math.floor((0.01 + pct * 0.29) * 100) / 100
        elseif sliderActive == 2 then Aim.FOV_Radius = math.floor(20 + pct * 280)
        end
        updateGUI()
    end
end))
