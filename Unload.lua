-- Unload.lua
-- Naciśnij DELETE aby całkowicie wyłączyć i wyczyścić ScoutCheat.
-- Usuwa ESP, Drawing objects, disconnectuje eventy, czyści _G.

local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local function unloadAll()
    print("[ScoutCheat] Rozładowywanie...")

    -- 1. Aimbot cleanup
    if getgenv().ScoutCheat and getgenv().ScoutCheat._cleanupAimbot then
        pcall(getgenv().ScoutCheat._cleanupAimbot)
    end

    -- 2. Tracers cleanup
    if getgenv().ScoutCheat and getgenv().ScoutCheat._cleanupTracers then
        pcall(getgenv().ScoutCheat._cleanupTracers)
    end

    -- 3. Usuń ESP ScreenGui
    local espHolder = CoreGui:FindFirstChild("ESPHolder")
    if not espHolder then
        -- ESP jest w PlayerGui
        local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if pg then espHolder = pg:FindFirstChild("ESPHolder") end
    end
    if espHolder then
        pcall(function() espHolder:Destroy() end)
        print("[ESP] ScreenGui usunięty.")
    end

    -- 4. Usuń wszystkie Drawing objects (FOV Circle, GUI elementy, tracery)
    pcall(function()
        for _, drawing in pairs(getgenv().__drawings or {}) do
            pcall(function() drawing:Remove() end)
        end
    end)
    -- Agresywny fallback: Drawing.new zwraca unikalne obiekty – możemy tylko je zebrać
    -- przez wcześniej zarejestrowaną tablicę lub polegamy na per-module cleanup.

    -- 5. Wyczyść globale
    getgenv().ScoutCheat  = nil
    _G.ScoutCheat         = nil

    -- 6. Przywróć oświetlenie
    pcall(function()
        local Lighting = game:GetService("Lighting")
        -- wartości zapisane przez Visuals.lua
        if getgenv()._origLighting then
            local o = getgenv()._origLighting
            Lighting.Brightness       = o.Brightness
            Lighting.Ambient          = o.Ambient
            Lighting.OutdoorAmbient   = o.OutdoorAmbient
            Lighting.FogEnd           = o.FogEnd
            Lighting.FogStart         = o.FogStart
            Lighting.FogColor         = o.FogColor
        end
    end)

    print("[ScoutCheat] ✔ Całkowicie rozładowano. Odśwież stronę / wczytaj ponownie aby użyć skryptu.")
end

-- Klawisz DELETE = Unload
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Delete then
        unloadAll()
    end
end)

-- Eksponuj ręcznie
getgenv().ScoutUnload = unloadAll
print("[Unload] Gotowy. Naciśnij DELETE aby wyłączyć ScoutCheat.")
