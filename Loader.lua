-- Załaduj ten skrypt za pomocą executora!
-- Pamiętaj aby zmienić link jeśli wrzucisz to na swojego GitHuba

local repoURL = "https://raw.githubusercontent.com/piotrwrt150/zniu81zd41c3jljumqn8p3o609mjr75arzan2r0yxqa/main/"

print("[ScoutCheat] Ładowanie Config.lua...")
local Config = loadstring(game:HttpGet(repoURL .. "Config.lua"))()

getgenv().ScoutCheat = { Config = Config }
_G.ScoutCheat = getgenv().ScoutCheat

print("[ScoutCheat] Ładowanie ESP.lua...")
loadstring(game:HttpGet(repoURL .. "ESP.lua"))()

print("[ScoutCheat] Ładowanie Aimbot.lua...")
loadstring(game:HttpGet(repoURL .. "Aimbot.lua"))()

print("[ScoutCheat] Ładowanie Visuals.lua...")
loadstring(game:HttpGet(repoURL .. "Visuals.lua"))()

print("[ScoutCheat] Ładowanie GUI.lua...")
loadstring(game:HttpGet(repoURL .. "GUI.lua"))()

print("[ScoutCheat] Załadowano pomyślnie! Klawisz K - Menu, L - Zapis configu, J - Wczytanie configu")