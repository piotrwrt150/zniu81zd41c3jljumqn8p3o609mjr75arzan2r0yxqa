local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Visuals = _G.ScoutCheat.Config.Visuals

local origBrightness   = Lighting.Brightness
local origAmbient      = Lighting.Ambient
local origFogEnd       = Lighting.FogEnd
local origFogStart     = Lighting.FogStart
local origFogColor     = Lighting.FogColor

local rainbowHue = 0

RunService.RenderStepped:Connect(function(dt)
    if Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = origBrightness
        Lighting.Ambient = origAmbient
    end

    if Visuals.NoFog then
        Lighting.FogEnd   = 100000
        Lighting.FogStart = 99999
    else
        Lighting.FogEnd   = origFogEnd
        Lighting.FogStart = origFogStart
        Lighting.FogColor = origFogColor
    end

    if Visuals.RainbowChams then
        rainbowHue = (rainbowHue + dt * 0.3) % 1
        local col = Color3.fromHSV(rainbowHue, 1, 1)
        local SG = CoreGui:FindFirstChild("ESPHolder")
        if SG then
            for _, h in pairs(SG:GetDescendants()) do
                if h:IsA("Highlight") then
                    h.OutlineColor = col
                end
            end
        end
    end
end)
