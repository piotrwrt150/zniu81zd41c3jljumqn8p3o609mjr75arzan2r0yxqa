-- Loader.lua
local repoURL = "https://raw.githubusercontent.com/piotrwrt150/zniu81zd41c3jljumqn8p3o609mjr75arzan2r0yxqa/main/"

print("[Eclipse Hub] Pobieranie skryptu...")

local status, content = pcall(function() 
    return game:HttpGet(repoURL .. "Hub.lua") 
end)

if status and content then
    local func, err = loadstring(content)
    if func then
        print("[Eclipse Hub] Uruchamianie...")
        func()
    else
        warn("[Eclipse Hub] Błąd składni w Hub.lua: " .. tostring(err))
        -- Wyświetlamy treść, żeby zobaczyć czy to nie 404
        print("Treść otrzymana z serwera: " .. content:sub(1, 100))
    end
else
    warn("[Eclipse Hub] Nie udało się pobrać pliku. Sprawdź połączenie lub link.")
end
