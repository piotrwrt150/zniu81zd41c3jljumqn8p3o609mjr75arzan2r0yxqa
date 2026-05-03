-- Załaduj ten skrypt za pomocą executora!
-- Pamiętaj aby zmienić link jeśli wrzucisz to na swojego GitHuba

local repoURL = "https://raw.githubusercontent.com/aH7pTep43dq/zniu81zd41c3jljumqn8p3o609mjr75arzan2r0yxqa/main/"

print("[ScoutCheat] Ładowanie Config.lua...")
local Config = loadstring(game:HttpGet(repoURL .. "Config.lua"))()

getgenv().ScoutCheat = { Config = Config, _connections = {}, _drawings = {} }
_G.ScoutCheat = getgenv().ScoutCheat

print("[ScoutCheat] Ładowanie ESP.lua...")
loadstring(game:HttpGet(repoURL .. "ESP.lua"))()

print("[ScoutCheat] Ładowanie Aimbot.lua...")
loadstring(game:HttpGet(repoURL .. "Aimbot.lua"))()

print("[ScoutCheat] Ładowanie Visuals.lua...")
loadstring(game:HttpGet(repoURL .. "Visuals.lua"))()


print("[ScoutCheat] Ładowanie Watermark.lua...")
loadstring(game:HttpGet(repoURL .. "Watermark.lua"))()

print("[ScoutCheat] Ładowanie GUI.lua...")
loadstring(game:HttpGet(repoURL .. "GUI.lua"))()

print("[ScoutCheat] Ładowanie Unload.lua...")
loadstring(game:HttpGet(repoURL .. "Unload.lua"))()

print("[ScoutCheat] ✔ Załadowano pomyślnie!")
print("  K        – Menu (Aimbot GUI)")
print("  L        – Zapisz config")
print("  J        – Wczytaj config")
print("  DELETE   – Unload")
