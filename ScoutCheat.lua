-- ScoutCheat.lua
-- Ten plik ładuje wszystkie moduły cheata (Aimbot, ESP, GUI itp.)
-- Jest odpalany z poziomu Eclipse Hub.

local repoURL = "https://raw.githubusercontent.com/aH7pTep43dq/zniu81zd41c3jljumqn8p3o609mjr75arzan2r0yxqa/main/"

if _G.ScoutCheatLoaded then
    print("[ScoutCheat] Skrypt jest już załadowany!")
    return
end

_G.ScoutCheatLoaded = true

print("[ScoutCheat] Ładowanie modułów...")

local Config = loadstring(game:HttpGet(repoURL .. "src/Config.lua"))()
getgenv().ScoutCheat = { Config = Config, _connections = {}, _drawings = {} }
_G.ScoutCheat = getgenv().ScoutCheat

loadstring(game:HttpGet(repoURL .. "src/ESP.lua"))()
loadstring(game:HttpGet(repoURL .. "src/Aimbot.lua"))()
loadstring(game:HttpGet(repoURL .. "src/Visuals.lua"))()
loadstring(game:HttpGet(repoURL .. "src/Watermark.lua"))()
loadstring(game:HttpGet(repoURL .. "src/GUI.lua"))()
loadstring(game:HttpGet(repoURL .. "src/Unload.lua"))()

print("[ScoutCheat] ✔ Załadowano pomyślnie!")
