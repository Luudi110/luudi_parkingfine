# Luudi_ParkingFine

Et komplet parkeringsbøde-system til FiveM/ESX med ox_lib integration.

## 📋 Features

- ✅ Job-locked til politiet (konfigurerbart)
- ✅ ox_lib UI integration (menuer, input, notifikationer)
- ✅ **ESX Billing integration** - Bøder oprettes i billing systemet
- ✅ Nummerplade-baseret (kræver ikke spiller i køretøj)
- ✅ Virker for både online og offline spillere
- ✅ MySQL database lagring af alle bøder
- ✅ Server-side validering og sikkerhed
- ✅ Keybind support (F7 som standard)
- ✅ Lokalisering (Dansk og Engelsk)
- ✅ Eksporter til eksterne scripts
- ✅ Command support (`/parkingfine`, `/payfine`, `/myfines`)

## 📦 Dependencies

Dette resource kræver følgende dependencies:

- [es_extended](https://github.com/esx-framework/esx_core) - ESX Framework
- [ox_lib](https://github.com/overextended/ox_lib) - UI library
- [oxmysql](https://github.com/overextended/oxmysql) - MySQL driver
- [esx_billing](https://github.com/esx-framework/esx_billing) - ESX Billing system (v1.0)

## 🔧 Installation

### 1. Download og installation

1. Download resourcen og placer den i din `resources/[custom]/[Luudi]` mappe
2. Omdøb mappen til `luudi_parkingfine` hvis ikke allerede gjort

### 2. Database opsætning

Kør SQL-filen for at oprette tabellen i din database:

```bash
Gå til sql/schema.sql og kør SQL kommandoerne i din database
```

Eller kør denne SQL direkte:

```sql
CREATE TABLE IF NOT EXISTS `luudi_parkingfines` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `issuer` VARCHAR(64) NOT NULL,
    `issuer_name` VARCHAR(128) DEFAULT NULL,
    `vehicle_plate` VARCHAR(16) DEFAULT NULL,
    `amount` INT NOT NULL,
    `reason` TEXT DEFAULT NULL,
    `paid` TINYINT(1) NOT NULL DEFAULT 0,
    `auto_deducted` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `paid_at` DATETIME DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_paid` (`paid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 3. Server.cfg

Tilføj følgende til din `server.cfg`:

```cfg
ensure luudi_parkingfine
```

Sørg for at resourcen startes EFTER dependencies:

```cfg
ensure es_extended
ensure ox_lib
ensure oxmysql
ensure esx_billing

ensure luudi_parkingfine
```

### 4. Konfiguration

Rediger `config.lua` for at tilpasse systemet til dine behov:

```lua
Config.Locale = 'da' -- Eller 'en' for engelsk

Config.AuthorizedJobs = {
    ['police'] = true,
    -- Tilføj flere jobs her
}

Config.MinFineAmount = 100
Config.MaxFineAmount = 50000

Config.Keybind = 'F7' -- Tast til at åbne menu
```

## 🎮 Brug

### For Politiet

#### Åbn Menu
- Tryk på **F7** (eller din konfigurerede keybind)
- Eller brug kommandoen: `/parkingfine`

#### Udsted Bøde
1. **Stil dig ved et parkeret køretøj** (ingen person behøver at være i det)
2. **Åbn menuen** med F7 eller `/parkingfine`
3. **Systemet finder nærmeste køretøj** indenfor 5 meter og viser nummerpladen
4. **Indtast:**
   - Bødebeløb (mellem min og max værdier)
   - Årsag til bøden
5. **Bekræft**
6. **Bøden oprettes i ESX Billing** systemet
   - Hvis ejer er online, modtager de notifikation
   - Hvis ejer er offline, venter bøden til de logger ind
7. **Ejer kan betale bøden** via `/bills` kommando eller ESX billing menu

#### Se Bøder
1. Åbn menuen
2. Vælg "Se Udstedte Bøder"
3. Vælg en bøde for at se detaljer eller markere som betalt

### For Spillere

#### Se og Betal Dine Bøder
Brug ESX Billing systemet:
```
/bills
```

Eller via F3 menu (ESX default) under "Fakturaer"

#### Se Dine Bøder (alternativ)
```
/myfines
```

## 📡 Integration med ESX Billing

Systemet opretter automatisk bøder i ESX Billing systemet:

- **Online spillere**: Modtager øjeblikkelig notifikation og bøde i billing system
- **Offline spillere**: Bøden venter i billing database til de logger ind
- **Betaling**: Spillere betaler via `/bills` eller ESX menu
- **Society**: Alle bøder går til `society_police`

## 📡 Events

### Client Events

#### Åbn Menu
```lua
TriggerEvent('luudi_parkingfine:client:openMenu')
```

#### Modtag Bøde (Automatisk trigger)
```lua
RegisterNetEvent('luudi_parkingfine:client:receiveFine', function(data)
    -- data.amount
    -- data.reason
    -- data.autoDeducted
end)
```

#### Bøde Udstedt (Automatisk trigger til issuer)
```lua
RegisterNetEvent('luudi_parkingfine:client:fineIssued', function(data)
    -- data.amount
    -- data.targetName
end)
```

### Server Events

#### Udsted Bøde
```lua
TriggerServerEvent('luudi_parkingfine:server:issueFine', {
    vehiclePlate = "ABC123",
    amount = 500,
    reason = "Parkeret på fortov"
})
```

**Note:** Bøder oprettes i ESX Billing systemet, så spillere kan betale via `/bills`

## 📤 Eksporter

### Server-side Eksporter

#### Hent Bøder for Spiller
```lua
local fines = exports['luudi_parkingfine']:GetParkingFineForPlayer(identifier)
```

#### Hent Alle Ubetalte Bøder
```lua
local unpaidFines = exports['luudi_parkingfine']:GetAllUnpaidFines()
```

#### Hent Specifik Bøde
```lua
local fine = exports['luudi_parkingfine']:GetFineById(fineId)
```

## 🔒 Sikkerhed

- ✅ Alle autorisation checks sker server-side
- ✅ Ingen client-side trust for penge-transaktioner
- ✅ Input validering på både client og server
- ✅ SQL injection beskyttelse via prepared statements
- ✅ Balance checks før træk af penge

## 🐛 Debug Mode

Aktivér debug mode i `config.lua`:

```lua
Config.Debug = true
```

Brug debug kommando:
```
/parkingfine_debug
```

## 🔄 Integration med ESX Logs

For at integrere med ESX logs eller andre log-systemer, rediger `LogAction` funktionen i `server/main.lua`:

```lua
function LogAction(action, source, data)
    -- Eksempel: Integration med discord webhook
    TriggerEvent('esx:log', action, source, data)
    
    -- Eller tilføj din egen log-logik her
end
```

## 📝 Kommandoer

| Kommando | Beskrivelse | Tilladelse |
|----------|-------------|------------|
| `/parkingfine` | Åbn parkeringsbøde menu | Kun autoriserede jobs |
| `/bills` | Se og betal dine bøder (ESX Billing) | Alle spillere |
| `/myfines` | Vis dine parkeringsbøder (liste) | Alle spillere |

## 🎨 Tilpasning

### Tilføj Flere Jobs

I `config.lua`:

```lua
Config.AuthorizedJobs = {
    ['police'] = true,
    ['sheriff'] = true,
    ['statepolice'] = true,
}
```

### Skift Society

Hvis dine bøder skal gå til en anden society (f.eks. sheriff):

I `server/main.lua`, find linjen:
```lua
TriggerEvent('esx_billing:sendBill', targetPlayer.source, 'society_police', 'police', reason, amount)
```

Skift til:
```lua
TriggerEvent('esx_billing:sendBill', targetPlayer.source, 'society_sheriff', 'sheriff', reason, amount)
```

### Tilpas Notifikation Varighed

I `config.lua`:

```lua
Config.NotificationDuration = 7000 -- 7 sekunder
```

## 📄 Filstruktur

```
luudi_parkingfine/
├── fxmanifest.lua          # Resource manifest
├── config.lua              # Konfigurationsfil
├── client/
│   └── main.lua           # Client-side logik
├── server/
│   └── main.lua           # Server-side logik
├── sql/
│   └── schema.sql         # Database schema
├── locales/
│   ├── da.lua            # Danske oversættelser
│   └── en.lua            # Engelske oversættelser
└── README.md              # Denne fil
```

## 🤝 Support

Hvis du oplever problemer:

1. Tjek at alle dependencies er installeret og opdateret
2. Tjek at SQL tabellen er oprettet korrekt
3. Aktivér debug mode for at se fejl i konsollen
4. Tjek server console for fejlmeddelelser

## 📜 License

Dette resource er lavet af **Luudi** og er frit til brug.

## 🔄 Changelog

### Version 1.0.0
- Initial release
- Basis funktionalitet implementeret
- ox_lib integration
- **ESX Billing integration**
- Nummerplade-baseret system
- Virker for online og offline spillere
- MySQL database support
- Lokalisering (DA/EN)
- Command support
- Eksporter til eksterne scripts

---

**Lavet med ❤️ af Luudi**
