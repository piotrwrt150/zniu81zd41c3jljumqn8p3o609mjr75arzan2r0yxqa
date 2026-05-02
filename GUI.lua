local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local Aim     = _G.ScoutCheat.Config.Aimbot
local Visuals = _G.ScoutCheat.Config.Visuals

-- ─── Config Save / Load ───────────────────────────────────────────────────────
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
        Vis_Fullbright     = Visuals.Fullbright,
        Vis_NoFog          = Visuals.NoFog,
        Vis_BulletTracers  = Visuals.BulletTracers,
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
            Visuals.Fullbright     = b(data.Vis_Fullbright,    Visuals.Fullbright)
            Visuals.NoFog          = b(data.Vis_NoFog,         Visuals.NoFog)
            Visuals.BulletTracers  = b(data.Vis_BulletTracers, Visuals.BulletTracers)
            print("[Config] Wczytano z " .. CONFIG_FILE)
        end
    end
end

LoadConfig()

-- ─── Drawing helpers ──────────────────────────────────────────────────────────
local function reg(c)  table.insert(getgenv().ScoutCheat._connections, c) return c end
local function regD(d) table.insert(getgenv().ScoutCheat._drawings,     d) return d end

local function mkRect(z) local r = Drawing.new("Square") r.Filled=true r.Visible=false r.ZIndex=z return regD(r) end
local function mkText(s,z) local t = Drawing.new("Text") t.Size=s t.Font=Drawing.Fonts.UI t.Visible=false t.ZIndex=z return regD(t) end
local function mkLine(z) local l = Drawing.new("Line") l.Visible=false l.ZIndex=z return regD(l) end

-- ─── GUI state ────────────────────────────────────────────────────────────────
local GUI = { Visible=false, X=120, Y=80, W=295, H=340, Dragging=false, DragOffset=Vector2.new() }
local COL = {
    BG     = Color3.fromRGB(12,12,22),
    Panel  = Color3.fromRGB(25,25,42),
    Accent = Color3.fromRGB(100,100,255),
    Text   = Color3.new(1,1,1),
    Sub    = Color3.fromRGB(155,155,180),
    Slider = Color3.fromRGB(55,55,95),
    Off    = Color3.fromRGB(70,70,80),
    Danger = Color3.fromRGB(200,50,50),
}

-- ─── Drawing objects ──────────────────────────────────────────────────────────
local dBG       = mkRect(10)
local dTitle    = mkText(15,12)
local dClose    = mkText(18,12)
local dSep1     = mkLine(11)

-- Toggles
local t1BG,t1,t1L = mkRect(11),mkRect(12),mkText(13,12)  -- Aimbot
local t2BG,t2,t2L = mkRect(11),mkRect(12),mkText(13,12)  -- FOV Circle
local t3BG,t3,t3L = mkRect(11),mkRect(12),mkText(13,12)  -- Bullet Tracers

local dSep2 = mkLine(11)

-- Sliders
local s1T,s1F,s1L,s1V = mkRect(11),mkRect(12),mkText(13,12),mkText(13,12) -- Smoothness
local s2T,s2F,s2L,s2V = mkRect(11),mkRect(12),mkText(13,12),mkText(13,12) -- FOV Radius

local dSep3     = mkLine(11)

-- Aim Part
local dPartLbl  = mkText(13,12)
local dPartBtn  = mkRect(11)
local dPartBtnL = mkText(13,12)

-- Unload button
local dUnloadBtn = mkRect(11)
local dUnloadLbl = mkText(13,12)

local SLIDER_W = 175
local SLIDER_H = 8
local sliderActive = nil

local ALL = {
    dBG,dTitle,dClose,dSep1,dSep2,dSep3,
    t1BG,t1,t1L, t2BG,t2,t2L, t3BG,t3,t3L,
    s1T,s1F,s1L,s1V, s2T,s2F,s2L,s2V,
    dPartLbl,dPartBtn,dPartBtnL,
    dUnloadBtn,dUnloadLbl,
}

local function setAll(v) for _,d in pairs(ALL) do d.Visible=v end end

-- ─── Layout constants (Y offsets from GUI.Y) ──────────────────────────────────
-- Header:     0–34
-- Toggle 1:  46
-- Toggle 2:  70
-- Toggle 3:  94
-- Sep2:     118
-- Slider 1 label: 126  track: 139
-- Slider 2 label: 159  track: 172
-- Sep3:     194
-- AimPart:  202
-- Unload:   225
-- Bottom:   255 → H=265

local function drawToggle(bg,fill,lbl, yOff, label, state)
    local tw,th = 32,16
    local x,w = GUI.X, GUI.W
    bg.Position   = Vector2.new(x+w-tw-12, GUI.Y+yOff) bg.Size = Vector2.new(tw,th)
    bg.Color      = COL.Slider bg.Visible = true
    fill.Position = Vector2.new(x+w-tw-12+(state and tw-th or 0), GUI.Y+yOff)
    fill.Size     = Vector2.new(th,th)
    fill.Color    = state and COL.Accent or COL.Off fill.Visible = true
    lbl.Position  = Vector2.new(x+12, GUI.Y+yOff) lbl.Text = label lbl.Color = COL.Text lbl.Visible = true
end

local function drawSlider(track,fill,lbl,val, yOff, label, pct, valStr)
    local x = GUI.X
    lbl.Position   = Vector2.new(x+12, GUI.Y+yOff)       lbl.Text = label   lbl.Color = COL.Sub   lbl.Visible = true
    track.Position = Vector2.new(x+12, GUI.Y+yOff+13)    track.Size = Vector2.new(SLIDER_W,SLIDER_H) track.Color = COL.Slider track.Visible = true
    fill.Position  = Vector2.new(x+12, GUI.Y+yOff+13)    fill.Size  = Vector2.new(math.max(4,SLIDER_W*pct),SLIDER_H) fill.Color = COL.Accent fill.Visible = true
    val.Position   = Vector2.new(x+12+SLIDER_W+6, GUI.Y+yOff+9) val.Text = valStr val.Color = COL.Text val.Visible = true
end

local function updateGUI()
    if not GUI.Visible then setAll(false) return end
    local x,y,w,h = GUI.X,GUI.Y,GUI.W,265

    -- Background
    dBG.Position=Vector2.new(x,y) dBG.Size=Vector2.new(w,h) dBG.Color=COL.BG dBG.Transparency=0.82 dBG.Visible=true
    -- Title
    dTitle.Position=Vector2.new(x+12,y+10) dTitle.Text="🎯 ScoutCheat  |  K=Menu  L=Save  J=Load" dTitle.Color=COL.Accent dTitle.Visible=true
    -- Close X
    dClose.Position=Vector2.new(x+w-22,y+8) dClose.Text="✕" dClose.Color=Color3.fromRGB(255,80,80) dClose.Visible=true
    -- Sep 1
    dSep1.From=Vector2.new(x+8,y+34) dSep1.To=Vector2.new(x+w-8,y+34) dSep1.Color=COL.Accent dSep1.Thickness=1 dSep1.Visible=true

    -- Toggles
    drawToggle(t1BG,t1,t1L,  46, "Aimbot Enabled",   Aim.Enabled)
    drawToggle(t2BG,t2,t2L,  70, "FOV Circle",        Aim.FOV_Enabled)
    drawToggle(t3BG,t3,t3L,  94, "Bullet Tracers",    Visuals.BulletTracers)

    -- Sep 2
    dSep2.From=Vector2.new(x+8,y+118) dSep2.To=Vector2.new(x+w-8,y+118) dSep2.Color=COL.Slider dSep2.Thickness=1 dSep2.Visible=true

    -- Sliders
    local s1pct = (Aim.Smoothness-0.01)/(0.3-0.01)
    drawSlider(s1T,s1F,s1L,s1V, 126, "Legit Smoothness", s1pct, tostring(math.floor(Aim.Smoothness*100)/100))

    local s2pct = (Aim.FOV_Radius-20)/(300-20)
    drawSlider(s2T,s2F,s2L,s2V, 159, "FOV Radius", s2pct, tostring(math.floor(Aim.FOV_Radius)))

    -- Sep 3
    dSep3.From=Vector2.new(x+8,y+194) dSep3.To=Vector2.new(x+w-8,y+194) dSep3.Color=COL.Slider dSep3.Thickness=1 dSep3.Visible=true

    -- Aim Part
    dPartLbl.Position=Vector2.new(x+12,y+202) dPartLbl.Text="Aim Part:" dPartLbl.Color=COL.Sub dPartLbl.Visible=true
    dPartBtn.Position=Vector2.new(x+82,y+200) dPartBtn.Size=Vector2.new(110,18) dPartBtn.Color=COL.Panel dPartBtn.Visible=true
    dPartBtnL.Position=Vector2.new(x+87,y+202) dPartBtnL.Text=Aim.AimPart dPartBtnL.Color=COL.Accent dPartBtnL.Visible=true

    -- Unload button
    dUnloadBtn.Position=Vector2.new(x+12,y+225) dUnloadBtn.Size=Vector2.new(w-24,22)
    dUnloadBtn.Color=COL.Danger dUnloadBtn.Transparency=0.35 dUnloadBtn.Visible=true
    dUnloadLbl.Position=Vector2.new(x+w/2-50,y+229) dUnloadLbl.Text="⏏  UNLOAD  (lub DELETE)" dUnloadLbl.Color=COL.Text dUnloadLbl.Visible=true
end

-- ─── Input ────────────────────────────────────────────────────────────────────
local function inBox(mx,my,bx,by,bw,bh) return mx>=bx and mx<=bx+bw and my>=by and my<=by+bh end

reg(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    -- Hotkeys
    if input.KeyCode == Enum.KeyCode.K     then GUI.Visible=not GUI.Visible updateGUI() return end
    if input.KeyCode == Enum.KeyCode.L     then SaveConfig() return end
    if input.KeyCode == Enum.KeyCode.J     then LoadConfig() updateGUI() return end
    if input.KeyCode == Enum.KeyCode.Delete then
        if getgenv().ScoutUnload then getgenv().ScoutUnload() end
        GUI.Visible=false setAll(false) return
    end
    if not GUI.Visible then return end

    local ml = UserInputService:GetMouseLocation()
    local mx,my = ml.X, ml.Y
    local x,y,w = GUI.X,GUI.Y,GUI.W

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Close
        if inBox(mx,my, x+w-22,y+8, 16,16) then GUI.Visible=false setAll(false) return end
        -- Drag header
        if inBox(mx,my, x,y, w,34) then GUI.Dragging=true GUI.DragOffset=Vector2.new(mx-x,my-y) return end

        -- Toggles (click anywhere on the row)
        if inBox(mx,my, x,y+46,  w,20) then Aim.Enabled          = not Aim.Enabled          updateGUI() end
        if inBox(mx,my, x,y+70,  w,20) then Aim.FOV_Enabled       = not Aim.FOV_Enabled       updateGUI() end
        if inBox(mx,my, x,y+94,  w,20) then Visuals.BulletTracers = not Visuals.BulletTracers updateGUI() end

        -- Slider hit areas (label + track region)
        if inBox(mx,my, x+12,y+126, SLIDER_W,30) then sliderActive=1 end
        if inBox(mx,my, x+12,y+159, SLIDER_W,30) then sliderActive=2 end

        -- Aim Part cycle
        if inBox(mx,my, x+82,y+200, 110,18) then
            local p={"Head","HumanoidRootPart","UpperTorso"}
            Aim.AimPart=p[(table.find(p,Aim.AimPart) or 1)%3+1] updateGUI()
        end

        -- Unload button
        if inBox(mx,my, x+12,y+225, w-24,22) then
            if getgenv().ScoutUnload then getgenv().ScoutUnload() end
            GUI.Visible=false setAll(false)
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
    if sliderActive then
        local pct = math.clamp((ml.X-(GUI.X+12))/SLIDER_W, 0, 1)
        if     sliderActive==1 then Aim.Smoothness         = math.floor((0.01+pct*(0.3-0.01))*100)/100
        elseif sliderActive==2 then Aim.FOV_Radius         = math.floor(20+pct*(300-20))
        end
        updateGUI()
    end
end))
