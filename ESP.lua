local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local lplayer = Players.LocalPlayer
local CoreGui = lplayer:WaitForChild("PlayerGui")
local Cam = Workspace.CurrentCamera

local ESP = _G.ScoutCheat.Config.ESP
local RotationAngle, Tick = -45, tick()

local Functions = {}
function Functions:Create(Class, Props)
    local obj = typeof(Class)=='string' and Instance.new(Class) or Class
    for k,v in pairs(Props) do obj[k]=v end
    return obj
end
function Functions:FadeOutOnDist(el, dist)
    local t = math.max(0.1, 1-(dist/ESP.MaxDistance))
    if el:IsA("TextLabel") then el.TextTransparency = 1-t
    elseif el:IsA("ImageLabel") then el.ImageTransparency = 1-t
    elseif el:IsA("UIStroke") then el.Transparency = 1-t
    elseif el:IsA("Frame") then el.BackgroundTransparency = 1-t
    elseif el:IsA("Highlight") then el.FillTransparency=1-t el.OutlineTransparency=1-t end
end

local SG = Functions:Create("ScreenGui",{Parent=CoreGui,Name="ESPHolder",ResetOnSpawn=false})

local function CreateESP(plr)
    if SG:FindFirstChild(plr.Name) then SG[plr.Name]:Destroy() end
    local Name = Functions:Create("TextLabel",{Parent=SG,Size=UDim2.new(0,100,0,20),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Code,TextSize=ESP.FontSize,TextStrokeTransparency=0,RichText=true})
    local Box = Functions:Create("Frame",{Parent=SG,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.75,BorderSizePixel=0})
    local G1 = Functions:Create("UIGradient",{Parent=Box,Enabled=ESP.Drawing.Boxes.GradientFill,Color=ColorSequence.new{ColorSequenceKeypoint.new(0,ESP.Drawing.Boxes.GradientFillRGB1),ColorSequenceKeypoint.new(1,ESP.Drawing.Boxes.GradientFillRGB2)}})
    local Outline = Functions:Create("UIStroke",{Parent=Box,Transparency=0,Color=Color3.new(1,1,1),LineJoinMode=Enum.LineJoinMode.Miter})
    local G2 = Functions:Create("UIGradient",{Parent=Outline,Color=ColorSequence.new{ColorSequenceKeypoint.new(0,ESP.Drawing.Boxes.GradientRGB1),ColorSequenceKeypoint.new(1,ESP.Drawing.Boxes.GradientRGB2)}})
    local HBar = Functions:Create("Frame",{Parent=SG,BackgroundColor3=Color3.new(1,1,1)})
    local HBarBG = Functions:Create("Frame",{Parent=SG,ZIndex=-1,BackgroundColor3=Color3.new(0,0,0)})
    local HBarG = Functions:Create("UIGradient",{Parent=HBar,Enabled=true,Rotation=-90,Color=ColorSequence.new{ColorSequenceKeypoint.new(0,ESP.Drawing.Healthbar.GradientRGB1),ColorSequenceKeypoint.new(0.5,ESP.Drawing.Healthbar.GradientRGB2),ColorSequenceKeypoint.new(1,ESP.Drawing.Healthbar.GradientRGB3)}})
    local Chams = Functions:Create("Highlight",{Parent=SG,FillTransparency=1,OutlineTransparency=0,OutlineColor=Color3.fromRGB(119,120,255)})

    coroutine.wrap(function()
        local Conn
        local function Hide()
            Box.Visible=false Name.Visible=false HBar.Visible=false HBarBG.Visible=false Chams.Enabled=false
            if not plr then SG:Destroy() if Conn then Conn:Disconnect() end end
        end
        Conn = RunService.RenderStepped:Connect(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local HRP = plr.Character.HumanoidRootPart
                local Hum = plr.Character:FindFirstChild("Humanoid")
                if not Hum then return Hide() end
                local Pos, OnScreen = Cam:WorldToScreenPoint(HRP.Position)
                local Dist = (Cam.CFrame.Position - HRP.Position).Magnitude / 3.57
                if OnScreen and Dist <= ESP.MaxDistance then
                    local sf = (HRP.Size.Y * Cam.ViewportSize.Y)/(Pos.Z*2)
                    local w,h = 3*sf, 4.5*sf
                    if ESP.FadeOut.OnDistance then
                        Functions:FadeOutOnDist(Box,Dist) Functions:FadeOutOnDist(Name,Dist)
                        Functions:FadeOutOnDist(HBar,Dist) Functions:FadeOutOnDist(Chams,Dist)
                    end
                    Chams.Adornee=plr.Character Chams.Enabled=ESP.Drawing.Chams.Enabled
                    Chams.FillColor=ESP.Drawing.Chams.FillRGB Chams.OutlineColor=ESP.Drawing.Chams.OutlineRGB
                    if ESP.Drawing.Chams.Thermal then
                        Chams.FillTransparency = ESP.Drawing.Chams.Fill_Transparency+(0.2*math.abs(math.sin(tick()*2)))
                    end
                    Chams.DepthMode = ESP.Drawing.Chams.VisibleCheck and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
                    Box.Position=UDim2.new(0,Pos.X-w/2,0,Pos.Y-h/2) Box.Size=UDim2.new(0,w,0,h) Box.Visible=ESP.Drawing.Boxes.Full.Enabled
                    Box.BackgroundTransparency = ESP.Drawing.Boxes.Filled.Enabled and ESP.Drawing.Boxes.Filled.Transparency or 1
                    RotationAngle = RotationAngle+(tick()-Tick)*ESP.Drawing.Boxes.RotationSpeed*math.cos(math.pi/4*tick()-math.pi/2)
                    G1.Rotation=RotationAngle G2.Rotation=RotationAngle Tick=tick()
                    local hp = Hum.Health/Hum.MaxHealth
                    HBarBG.Position=UDim2.new(0,Pos.X-w/2-6,0,Pos.Y-h/2) HBarBG.Size=UDim2.new(0,4,0,h)
                    HBar.Position=UDim2.new(0,Pos.X-w/2-6,0,Pos.Y-h/2+h*(1-hp)) HBar.Size=UDim2.new(0,4,0,h*hp)
                    HBar.Visible=ESP.Drawing.Healthbar.Enabled HBarBG.Visible=ESP.Drawing.Healthbar.Enabled
                    Name.Visible=ESP.Drawing.Names.Enabled
                    if ESP.Options.Friendcheck and lplayer:IsFriendsWith(plr.UserId) then
                        Name.Text=string.format('(<font color="rgb(%d,%d,%d)">F</font>) %s',ESP.Options.FriendcheckRGB.R*255,ESP.Options.FriendcheckRGB.G*255,ESP.Options.FriendcheckRGB.B*255,plr.Name)
                    else
                        Name.Text=string.format('(<font color="rgb(255,0,0)">E</font>) %s',plr.Name)
                    end
                    Name.Position=UDim2.new(0,Pos.X,0,Pos.Y-h/2-9)
                else Hide() end
            else Hide() end
        end)
    end)()
end

for _,v in pairs(Players:GetPlayers()) do
    if v~=lplayer then coroutine.wrap(CreateESP)(v) end
end
Players.PlayerAdded:Connect(function(v) coroutine.wrap(CreateESP)(v) end)
