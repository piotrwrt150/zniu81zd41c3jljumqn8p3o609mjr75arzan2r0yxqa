local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Aim = _G.ScoutCheat.Config.Aimbot
local Visuals = _G.ScoutCheat.Config.Visuals

-- Config System
local CONFIG_FILE = "scout_cheat_config.json"

local function SaveConfig()
    local data = {
        Aim_Enabled     = Aim.Enabled,
        Aim_Smoothness  = Aim.Smoothness,
        Aim_FOV_Radius  = Aim.FOV_Radius,
        Aim_FOV_Enabled = Aim.FOV_Enabled,
        Aim_AimPart     = Aim.AimPart,
        Aim_TeamCheck   = Aim.TeamCheck,
        Aim_Deadzone    = Aim.Deadzone,
        Aim_VisibleCheck = Aim.VisibleCheck,
        Vis_Fullbright  = Visuals.Fullbright,
        Vis_NoFog       = Visuals.NoFog,
    }
    if writefile then
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
        print("[Config] Zapisano ustawienia do " .. CONFIG_FILE)
    else
        warn("[Config] Twój executor nie wspiera writefile!")
    end
end

local function LoadConfig()
    if readfile and isfile and isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and data then
            Aim.Enabled      = data.Aim_Enabled      or Aim.Enabled
            Aim.Smoothness   = data.Aim_Smoothness   or Aim.Smoothness
            Aim.FOV_Radius   = data.Aim_FOV_Radius   or Aim.FOV_Radius
            Aim.FOV_Enabled  = data.Aim_FOV_Enabled  ~= nil and data.Aim_FOV_Enabled or Aim.FOV_Enabled
            Aim.AimPart      = data.Aim_AimPart      or Aim.AimPart
            Aim.TeamCheck    = data.Aim_TeamCheck     ~= nil and data.Aim_TeamCheck or Aim.TeamCheck
            Aim.Deadzone     = data.Aim_Deadzone      or Aim.Deadzone
            Aim.VisibleCheck = data.Aim_VisibleCheck  ~= nil and data.Aim_VisibleCheck or Aim.VisibleCheck
            Visuals.Fullbright = data.Vis_Fullbright ~= nil and data.Vis_Fullbright or Visuals.Fullbright
            Visuals.NoFog    = data.Vis_NoFog        ~= nil and data.Vis_NoFog or Visuals.NoFog
            print("[Config] Wczytano ustawienia z " .. CONFIG_FILE)
        end
    end
end

LoadConfig()

-- GUI System
local GUI = { Visible = false, X = 100, Y = 100, W = 280, H = 320, Dragging = false, DragOffset = Vector2.new() }
local COL = { BG=Color3.fromRGB(15,15,25), Panel=Color3.fromRGB(25,25,40), Accent=Color3.fromRGB(100,100,255), Text=Color3.new(1,1,1), Sub=Color3.fromRGB(160,160,180), Slider=Color3.fromRGB(60,60,100) }

local function mkRect(z) local r=Drawing.new("Square") r.Filled=true r.Visible=false r.ZIndex=z return r end
local function mkText(s,z) local t=Drawing.new("Text") t.Size=s t.Font=Drawing.Fonts.UI t.Visible=false t.ZIndex=z return t end
local function mkLine(z) local l=Drawing.new("Line") l.Visible=false l.ZIndex=z return l end

local dBG = mkRect(10) local dTitle = mkText(16,12) local dClose = mkText(18,12) local dSep = mkLine(11)
local dToggle1BG = mkRect(11) local dToggle1 = mkRect(12) local dToggle1Lbl = mkText(13,12)
local dToggle2BG = mkRect(11) local dToggle2 = mkRect(12) local dToggle2Lbl = mkText(13,12)
local dSlider1Track = mkRect(11) local dSlider1Fill = mkRect(12) local dSlider1Lbl = mkText(13,12) local dSlider1Val = mkText(13,12)
local dSlider2Track = mkRect(11) local dSlider2Fill = mkRect(12) local dSlider2Lbl = mkText(13,12) local dSlider2Val = mkText(13,12)
local dPartLbl = mkText(13,12) local dPartBtn = mkRect(11) local dPartBtnLbl = mkText(13,12)

local SLIDER_W = 180
local SLIDER_H = 8
local sliderActive = nil

local function setAll(vis)
    for _,d in pairs({dBG,dTitle,dClose,dSep,dToggle1BG,dToggle1,dToggle1Lbl,dToggle2BG,dToggle2,dToggle2Lbl,dSlider1Track,dSlider1Fill,dSlider1Lbl,dSlider1Val,dSlider2Track,dSlider2Fill,dSlider2Lbl,dSlider2Val,dPartLbl,dPartBtn,dPartBtnLbl}) do d.Visible=vis end
end

local function updateGUI()
    if not GUI.Visible then setAll(false) return end
    local x,y,w,h = GUI.X, GUI.Y, GUI.W, GUI.H

    dBG.Position=Vector2.new(x,y) dBG.Size=Vector2.new(w,h) dBG.Color=COL.BG dBG.Transparency=0.8 dBG.Visible=true
    dTitle.Position=Vector2.new(x+12,y+10) dTitle.Text="🎯 Aimbot GUI" dTitle.Color=COL.Accent dTitle.Visible=true
    dClose.Position=Vector2.new(x+w-22,y+8) dClose.Text="✕" dClose.Color=Color3.fromRGB(255,80,80) dClose.Visible=true
    dSep.From=Vector2.new(x+8,y+34) dSep.To=Vector2.new(x+w-8,y+34) dSep.Color=COL.Accent dSep.Thickness=1 dSep.Visible=true

    local function drawToggle(bg,fill,lbl,yOff,label,state)
        local tw,th = 32,16
        bg.Position=Vector2.new(x+w-tw-12,y+yOff) bg.Size=Vector2.new(tw,th) bg.Color=COL.Slider bg.Visible=true
        fill.Position=Vector2.new(x+w-tw-12+(state and tw-th or 0),y+yOff) fill.Size=Vector2.new(th,th) fill.Color=state and COL.Accent or Color3.fromRGB(80,80,80) fill.Visible=true
        lbl.Position=Vector2.new(x+12,y+yOff) lbl.Text=label lbl.Color=COL.Text lbl.Visible=true
    end

    drawToggle(dToggle1BG,dToggle1,dToggle1Lbl,46,"Aimbot Enabled",Aim.Enabled)
    drawToggle(dToggle2BG,dToggle2,dToggle2Lbl,72,"Show FOV Circle",Aim.FOV_Enabled)

    local s1pct = (Aim.Smoothness-0.01)/(0.3-0.01)
    dSlider1Lbl.Position=Vector2.new(x+12,y+100) dSlider1Lbl.Text="Legit Smoothness" dSlider1Lbl.Color=COL.Sub dSlider1Lbl.Visible=true
    dSlider1Track.Position=Vector2.new(x+12,y+114) dSlider1Track.Size=Vector2.new(SLIDER_W,SLIDER_H) dSlider1Track.Color=COL.Slider dSlider1Track.Visible=true
    dSlider1Fill.Position=Vector2.new(x+12,y+114) dSlider1Fill.Size=Vector2.new(math.max(4,SLIDER_W*s1pct),SLIDER_H) dSlider1Fill.Color=COL.Accent dSlider1Fill.Visible=true
    dSlider1Val.Position=Vector2.new(x+12+SLIDER_W+6,y+110) dSlider1Val.Text=tostring(math.floor(Aim.Smoothness*100)/100) dSlider1Val.Color=COL.Text dSlider1Val.Visible=true

    local s2pct = (Aim.FOV_Radius-20)/(300-20)
    dSlider2Lbl.Position=Vector2.new(x+12,y+140) dSlider2Lbl.Text="FOV Radius" dSlider2Lbl.Color=COL.Sub dSlider2Lbl.Visible=true
    dSlider2Track.Position=Vector2.new(x+12,y+154) dSlider2Track.Size=Vector2.new(SLIDER_W,SLIDER_H) dSlider2Track.Color=COL.Slider dSlider2Track.Visible=true
    dSlider2Fill.Position=Vector2.new(x+12,y+154) dSlider2Fill.Size=Vector2.new(math.max(4,SLIDER_W*s2pct),SLIDER_H) dSlider2Fill.Color=COL.Accent dSlider2Fill.Visible=true
    dSlider2Val.Position=Vector2.new(x+12+SLIDER_W+6,y+150) dSlider2Val.Text=tostring(math.floor(Aim.FOV_Radius)) dSlider2Val.Color=COL.Text dSlider2Val.Visible=true

    dPartLbl.Position=Vector2.new(x+12,y+190) dPartLbl.Text="Aim Part:" dPartLbl.Color=COL.Sub dPartLbl.Visible=true
    dPartBtn.Position=Vector2.new(x+70,y+188) dPartBtn.Size=Vector2.new(100,18) dPartBtn.Color=COL.Panel dPartBtn.Visible=true
    dPartBtnLbl.Position=Vector2.new(x+75,y+190) dPartBtnLbl.Text=Aim.AimPart dPartBtnLbl.Color=COL.Accent dPartBtnLbl.Visible=true
end

local function inBox(mx,my, bx,by,bw,bh) return mx>=bx and mx<=bx+bw and my>=by and my<=by+bh end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then GUI.Visible = not GUI.Visible updateGUI() return end
    if input.KeyCode == Enum.KeyCode.L then SaveConfig() end
    if input.KeyCode == Enum.KeyCode.J then LoadConfig() updateGUI() end

    if not GUI.Visible then return end
    local ml = UserInputService:GetMouseLocation()
    local mx,my = ml.X, ml.Y
    local x,y,w = GUI.X,GUI.Y,GUI.W

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if inBox(mx,my, x+w-22,y+8, 16,16) then GUI.Visible=false setAll(false) return end
        if inBox(mx,my, x,y, w,34) then GUI.Dragging=true GUI.DragOffset=Vector2.new(mx-x,my-y) return end
        if inBox(mx,my, x+w-44,y+46, 32,16) then Aim.Enabled=not Aim.Enabled updateGUI() end
        if inBox(mx,my, x+w-44,y+72, 32,16) then Aim.FOV_Enabled=not Aim.FOV_Enabled updateGUI() end
        if inBox(mx,my, x+70,y+188, 100,18) then 
            local p={"Head","HumanoidRootPart","UpperTorso"} Aim.AimPart=p[(table.find(p,Aim.AimPart) or 1)%3+1] updateGUI() 
        end
        if inBox(mx,my, x+12,y+110, SLIDER_W,20) then sliderActive=1 end
        if inBox(mx,my, x+12,y+150, SLIDER_W,20) then sliderActive=2 end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then GUI.Dragging=false sliderActive=nil end
end)

RunService.RenderStepped:Connect(function()
    local ml = UserInputService:GetMouseLocation()
    if GUI.Dragging then GUI.X=ml.X-GUI.DragOffset.X GUI.Y=ml.Y-GUI.DragOffset.Y updateGUI() end
    if sliderActive then
        local pct = math.clamp((ml.X-(GUI.X+12))/SLIDER_W,0,1)
        if sliderActive==1 then Aim.Smoothness=math.floor((0.01+pct*(0.3-0.01))*100)/100
        elseif sliderActive==2 then Aim.FOV_Radius=math.floor(20+pct*(300-20)) end
        updateGUI()
    end
end)
