local Config = {
    ESP = {
        Enabled = true, TeamCheck = false, MaxDistance = 500, FontSize = 11,
        FadeOut = { OnDistance = true },
        Options = { Friendcheck = true, FriendcheckRGB = Color3.fromRGB(0,255,0) },
        Drawing = {
            Chams = { Enabled=true, Thermal=true, FillRGB=Color3.fromRGB(119,120,255), Fill_Transparency=0.5, OutlineRGB=Color3.fromRGB(119,120,255), VisibleCheck=true },
            Names = { Enabled=true },
            Boxes = {
                Animate=true, RotationSpeed=300,
                Gradient=false, GradientRGB1=Color3.fromRGB(119,120,255), GradientRGB2=Color3.fromRGB(0,0,0),
                GradientFill=true, GradientFillRGB1=Color3.fromRGB(119,120,255), GradientFillRGB2=Color3.fromRGB(0,0,0),
                Filled = { Enabled=true, Transparency=0.75 },
                Full = { Enabled=true },
                Corner = { Enabled=true, RGB=Color3.fromRGB(255,255,255) },
            },
            Healthbar = { Enabled=true, Gradient=true, GradientRGB1=Color3.fromRGB(200,0,0), GradientRGB2=Color3.fromRGB(60,60,125), GradientRGB3=Color3.fromRGB(119,120,255) },
        }
    },
    Aimbot = {
        Enabled = true,
        TeamCheck = false,
        AimPart = "Head",
        Smoothness = 0.08, 
        MaxDistance = 500,
        AimKey = Enum.UserInputType.MouseButton2,
        Deadzone = 12, 
        Randomization = true,
        RandomIntensity = 0.6, 
        CurveSmoothing = true, 
        FOV_Enabled = true,
        FOV_Radius = 75,
        FOV_Color = Color3.fromRGB(255,255,255),
        FOV_Thickness = 1,
        FOV_Transparency = 0.8,
        VisibleCheck = true,
        -- Prediction
        Prediction = true,
        PredictionStrength = 0.14, -- sekundy w przód (im wyższy ping, tym większa wartość)
    },
    Visuals = {
        Fullbright = false,
        NoFog = false,
        RainbowChams = false,
        -- Bullet Tracers
        BulletTracers = true,
        BulletTracerColor = Color3.fromRGB(255, 80, 80),
        BulletTracerThickness = 1.5,
        BulletTracerFadeTime = 0.45, -- sekundy zanim linia zniknie
    }
}
return Config
