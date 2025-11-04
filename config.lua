Config = {}

-- Generelle indstillinger
Config.Locale = 'da' -- 'da' eller 'en'

-- Job indstillinger
Config.AuthorizedJobs = {
    ['police'] = true,
    -- Tilføj flere jobs her hvis nødvendigt
    -- ['sheriff'] = true,
}

-- Bøde indstillinger
Config.MinFineAmount = 100        -- Minimum bødebeløb
Config.MaxFineAmount = 50000      -- Maksimum bødebeløb

-- Keybind indstillinger
Config.UseKeybind = true          -- Skal der bruges keybind til at åbne menu?
Config.Keybind = 'F7'             -- Tastekombination til at åbne menu
Config.KeybindDescription = 'Åbn Parkeringsbøde Menu'

-- Database indstillinger
Config.UseOxMySQL = true          -- true = oxmysql, false = ghmattimysql

-- Distances
Config.MaxDistance = 5.0          -- Maksimal afstand til køretøj (meter)

-- Notifikationer
Config.NotificationDuration = 5000 -- Varighed af notifikationer i millisekunder

-- Debug mode
Config.Debug = false              -- Aktivér debug beskeder i konsol
