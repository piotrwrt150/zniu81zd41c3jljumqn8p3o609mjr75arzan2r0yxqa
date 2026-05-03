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
local GUI = { Visible=false, X=120, Y=80, W=320, H=420, Dragging=false, DragOffset=Vector2.new(), Tab="Aimbot", Binding=false }
local COL = {
    BG     = Color3.fromRGB(12,12,22),
    Panel  = Color3.fromRGB(25,25,42),
    Accent = THEMES[GUIConf.Theme] or THEMES.Purple,
    Text   = Color3.new(1,1,1),
    Sub    = Color3.fromRGB(155,155,180),
    Slider = Color3.fromRGB(55,55,95),
    Off    = Color3.fromRGB(70,70,80),
    Danger = Color3.fromRGB(200,50,50),
}

local function UpdateAccent()
    COL.Accent = THEMES[GUIConf.Theme] or THEMES.Purple
end
UpdateAccent()
-- --- Drawing objects ----------------------------------------------------------
local ALL = {}
local function trackD(d) table.insert(ALL, d); return d; end

local dBG       = trackD(mkRect(10))
local dTitle    = trackD(mkText(15,12))
local dClose    = trackD(mkText(18,12))
local dSep1     = trackD(mkLine(11))

-- Tabs
local tabBtns = {
    Aimbot   = { BG = trackD(mkRect(11)), Lbl = trackD(mkText(14,12)) },
    Visuals  = { BG = trackD(mkRect(11)), Lbl = trackD(mkText(14,12)) },
    Settings = { BG = trackD(mkRect(11)), Lbl = trackD(mkText(14,12)) }
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
    local tw,th = 32,16
    local x,w = GUI.X, GUI.W
    local t = toggles[idx]
    t.BG.Position   = Vector2.new(x+w-tw-16, GUI.Y+yOff) t.BG.Size = Vector2.new(tw,th)
    t.BG.Color      = COL.Slider t.BG.Visible = true
    t.Fill.Position = Vector2.new(x+w-tw-16+(state and tw-th or 0), GUI.Y+yOff)
    t.Fill.Size     = Vector2.new(th,th)
    t.Fill.Color    = state and COL.Accent or COL.Off t.Fill.Visible = true
    t.Lbl.Position  = Vector2.new(x+16, GUI.Y+yOff) t.Lbl.Text = label t.Lbl.Color = COL.Text t.Lbl.Visible = true
end

local function drawSlider(idx, yOff, label, pct, valStr)
    local x = GUI.X
    local s = sliders[idx]
    s.Lbl.Position = Vector2.new(x+16, GUI.Y+yOff) s.Lbl.Text = label s.Lbl.Color = COL.Sub s.Lbl.Visible = true
    s.T.Position   = Vector2.new(x+16, GUI.Y+yOff+14) s.T.Size = Vector2.new(SLIDER_W,SLIDER_H) s.T.Color = COL.Slider s.T.Visible = true
    s.F.Position   = Vector2.new(x+16, GUI.Y+yOff+14) s.F.Size = Vector2.new(math.max(4,SLIDER_W*pct),SLIDER_H) s.F.Color = COL.Accent s.F.Visible = true
    s.Val.Position = Vector2.new(x+16+SLIDER_W+10, GUI.Y+yOff+9) s.Val.Text = valStr s.Val.Color = COL.Text s.Val.Visible = true
end

local function drawButton(bg, lbl, valTxt, yOff, text, valText)
    local x,w = GUI.X, GUI.W
    bg.Position = Vector2.new(x+16, GUI.Y+yOff) bg.Size = Vector2.new(w-32, 22) bg.Color = COL.Panel bg.Visible = true
    lbl.Position = Vector2.new(x+22, GUI.Y+yOff+4) lbl.Text = text lbl.Color = COL.Sub lbl.Visible = true
    if valTxt then
        valTxt.Position = Vector2.new(x+w-100, GUI.Y+yOff+4) valTxt.Text = valText valTxt.Color = COL.Accent valTxt.Visible = true
    end
end

local function updateGUI()
    if not GUI.Visible then setAll(false) return end
    UpdateAccent()
    setAll(false) -- reset visibility
    local x,y,w,h = GUI.X,GUI.Y,GUI.W,GUI.H

    -- Background
    dBG.Position=Vector2.new(x,y) dBG.Size=Vector2.new(w,h) dBG.Color=COL.BG dBG.Transparency=0.85 dBG.Visible=true
    dTitle.Position=Vector2.new(x+12,y+10) dTitle.Text="ScoutCheat | K=Menu L=Save J=Load" dTitle.Color=COL.Accent dTitle.Visible=true
    dClose.Position=Vector2.new(x+w-22,y+8) dClose.Text="X" dClose.Color=Color3.fromRGB(255,80,80) dClose.Visible=true
    
    -- Tabs (Y=34)
    local tabW = math.floor(w / 3)
    tabBtns.Aimbot.BG.Position = Vector2.new(x, y+34) tabBtns.Aimbot.BG.Size = Vector2.new(tabW, 26) 
    tabBtns.Aimbot.BG.Color = GUI.Tab=="Aimbot" and COL.Accent or COL.Panel tabBtns.Aimbot.BG.Visible = true
    tabBtns.Aimbot.Lbl.Position = Vector2.new(x+tabW/2-20, y+40) tabBtns.Aimbot.Lbl.Text = "Aimbot" tabBtns.Aimbot.Lbl.Color = COL.Text tabBtns.Aimbot.Lbl.Visible = true

    tabBtns.Visuals.BG.Position = Vector2.new(x+tabW, y+34) tabBtns.Visuals.BG.Size = Vector2.new(tabW, 26) 
    tabBtns.Visuals.BG.Color = GUI.Tab=="Visuals" and COL.Accent or COL.Panel tabBtns.Visuals.BG.Visible = true
    tabBtns.Visuals.Lbl.Position = Vector2.new(x+tabW+tabW/2-20, y+40) tabBtns.Visuals.Lbl.Text = "Visuals" tabBtns.Visuals.Lbl.Color = COL.Text tabBtns.Visuals.Lbl.Visible = true

    tabBtns.Settings.BG.Position = Vector2.new(x+tabW*2, y+34) tabBtns.Settings.BG.Size = Vector2.new(w-tabW*2, 26) 
    tabBtns.Settings.BG.Color = GUI.Tab=="Settings" and COL.Accent or COL.Panel tabBtns.Settings.BG.Visible = true
    tabBtns.Settings.Lbl.Position = Vector2.new(x+tabW*2+tabW/2-25, y+40) tabBtns.Settings.Lbl.Text = "Settings" tabBtns.Settings.Lbl.Color = COL.Text tabBtns.Settings.Lbl.Visible = true

    cBG.Position = Vector2.new(x+4, y+64) cBG.Size = Vector2.new(w-8, h-68) cBG.Color = Color3.fromRGB(18,18,28) cBG.Visible = true

    if GUI.Tab == "Aimbot" then
        GUI.H = 450
        drawToggle(1, 74, "Aimbot Enabled", Aim.Enabled)
        drawToggle(2, 98, "Visible Check", Aim.VisibleCheck)
        drawToggle(3, 122, "Closest Bone", Aim.ClosestBone)
        drawToggle(4, 146, "Curve Aiming", Aim.CurveAiming)
        drawToggle(5, 170, "Smoothness Var.", Aim.SmoothnessVariance)
        drawToggle(6, 194, "FOV Circle", Aim.FOV_Enabled)

        local s1pct = (Aim.Smoothness-0.01)/(0.3-0.01)
        drawSlider(1, 228, "Legit Smoothness", s1pct, string.format("%.2f", Aim.Smoothness))
        local s2pct = (Aim.FOV_Radius-20)/(300-20)
        drawSlider(2, 268, "FOV Radius", s2pct, tostring(math.floor(Aim.FOV_Radius)))
        local s3pct = (Aim.CurveStrength-0.1)/(3.0-0.1)
        drawSlider(3, 308, "Curve Strength", s3pct, string.format("%.2f", Aim.CurveStrength))
        local s4pct = (Aim.Deadzone-0)/(50-0)
        drawSlider(4, 348, "Target Deadzone", s4pct, tostring(math.floor(Aim.Deadzone)))

        drawButton(btn1BG, btn1Lbl, btn1Val, 388, "Aim Part:", Aim.AimPart)
        
        local keyName = tostring(Aim.AimKey):split(".")[3]
        drawButton(btn2BG, btn2Lbl, btn2Val, 412, "Aim Keybind:", GUI.Binding and "..." or keyName)

    elseif GUI.Tab == "Visuals" then
        GUI.H = 420
        drawToggle(1, 74, "ESP Master Switch", ESPConf.Enabled)
        drawToggle(2, 98, "Player Boxes", ESPConf.Drawing.Boxes.Full.Enabled)
        drawToggle(3, 122, "Health Bar", ESPConf.Drawing.Healthbar.Enabled)
        drawToggle(4, 146, "Player Names", ESPConf.Drawing.Names.Enabled)
        drawToggle(5, 170, "Distance [m]", ESPConf.Options.Distance)

    elseif GUI.Tab == "Settings" then
        GUI.H = 420
        drawToggle(1, 74, "Watermark", Visuals.Watermark)
        
        drawButton(btn1BG, btn1Lbl, btn1Val, 108, "GUI Theme:", GUIConf.Theme)

        -- Unload button
        btnUnload.Position=Vector2.new(x+16,y+GUI.H-38) btnUnload.Size=Vector2.new(w-32,26)
        btnUnload.Color=COL.Danger btnUnload.Transparency=0.35 btnUnload.Visible=true
        lblUnload.Position=Vector2.new(x+w/2-55,y+GUI.H-33) lblUnload.Text="  UNLOAD SCRIPT" lblUnload.Color=COL.Text lblUnload.Visible=true
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
    local x,y,w,h = GUI.X,GUI.Y,GUI.W,GUI.H

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if inBox(mx,my, x+w-22,y+8, 16,16) then GUI.Visible=false setAll(false) return end
        if inBox(mx,my, x,y, w,34) then GUI.Dragging=true GUI.DragOffset=Vector2.new(mx-x,my-y) return end

        local tabW = math.floor(w / 3)
        if inBox(mx,my, x, y+34, tabW, 26) then GUI.Tab="Aimbot" updateGUI() return end
        if inBox(mx,my, x+tabW, y+34, tabW, 26) then GUI.Tab="Visuals" updateGUI() return end
        if inBox(mx,my, x+tabW*2, y+34, tabW, 26) then GUI.Tab="Settings" updateGUI() return end

        if GUI.Tab == "Aimbot" then
            if inBox(mx,my, x,y+74, w,20) then Aim.Enabled = not Aim.Enabled updateGUI() end
            if inBox(mx,my, x,y+98, w,20) then Aim.VisibleCheck = not Aim.VisibleCheck updateGUI() end
            if inBox(mx,my, x,y+122, w,20) then Aim.ClosestBone = not Aim.ClosestBone updateGUI() end
            if inBox(mx,my, x,y+146, w,20) then Aim.CurveAiming = not Aim.CurveAiming updateGUI() end
            if inBox(mx,my, x,y+170, w,20) then Aim.SmoothnessVariance = not Aim.SmoothnessVariance updateGUI() end
            if inBox(mx,my, x,y+194, w,20) then Aim.FOV_Enabled = not Aim.FOV_Enabled updateGUI() end
            
            if inBox(mx,my, x+16,y+228, SLIDER_W,30) then sliderActive=1 end
            if inBox(mx,my, x+16,y+268, SLIDER_W,30) then sliderActive=2 end
            if inBox(mx,my, x+16,y+308, SLIDER_W,30) then sliderActive=3 end
            if inBox(mx,my, x+16,y+348, SLIDER_W,30) then sliderActive=4 end

            if inBox(mx,my, x+16,y+388, w-32,22) then
                local p={"Head","HumanoidRootPart","UpperTorso"}
                Aim.AimPart=p[(table.find(p,Aim.AimPart) or 1)%3+1] updateGUI()
            end
            
            if inBox(mx,my, x+16,y+412, w-32,22) then
                GUI.Binding = true
                updateGUI()
            end

        elseif GUI.Tab == "Visuals" then
            if inBox(mx,my, x,y+74, w,20) then ESPConf.Enabled = not ESPConf.Enabled updateGUI() end
            if inBox(mx,my, x,y+98, w,20) then ESPConf.Drawing.Boxes.Full.Enabled = not ESPConf.Drawing.Boxes.Full.Enabled updateGUI() end
            if inBox(mx,my, x,y+122, w,20) then ESPConf.Drawing.Healthbar.Enabled = not ESPConf.Drawing.Healthbar.Enabled updateGUI() end
            if inBox(mx,my, x,y+146, w,20) then ESPConf.Drawing.Names.Enabled = not ESPConf.Drawing.Names.Enabled updateGUI() end
            if inBox(mx,my, x,y+170, w,20) then ESPConf.Options.Distance = not ESPConf.Options.Distance updateGUI() end

        elseif GUI.Tab == "Settings" then
            if inBox(mx,my, x,y+74, w,20) then Visuals.Watermark = not Visuals.Watermark updateGUI() end
            
            if inBox(mx,my, x+16,y+108, w-32,22) then
                local idx = table.find(THEME_NAMES, GUIConf.Theme) or 1
                GUIConf.Theme = THEME_NAMES[idx%#THEME_NAMES + 1]
                updateGUI()
            end

            if inBox(mx,my, x+16,y+h-38, w-32,26) then
                if getgenv().ScoutUnload then getgenv().ScoutUnload() end
                GUI.Visible=false setAll(false)
            end
        end
    end
end))

reg(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        GUI.Dragging=false sliderActive=nil
    end
end))

reg(RunService.RenderStepped:Connect(function()
    local ml = UserInputService:GetMouseLocation()
    if GUI.Dragging then
        GUI.X=ml.X-GUI.DragOffset.X GUI.Y=ml.Y-GUI.DragOffset.Y updateGUI()
    end
    if sliderActive and GUI.Tab == "Aimbot" then
        local pct = math.clamp((ml.X-(GUI.X+16))/SLIDER_W, 0, 1)
        if     sliderActive==1 then Aim.Smoothness         = math.floor((0.01+pct*(0.3-0.01))*100)/100
        elseif sliderActive==2 then Aim.FOV_Radius         = math.floor(20+pct*(300-20))
        elseif sliderActive==3 then Aim.CurveStrength      = math.floor((0.1+pct*(3.0-0.1))*100)/100
        elseif sliderActive==4 then Aim.Deadzone           = math.floor(pct*50)
        end
        updateGUI()
    end
end))
