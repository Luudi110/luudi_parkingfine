-- Lokale variabler
local PlayerData = {}
local isAuthorized = false

-- Hent ESX objekt og playerdata
CreateThread(function()
    ESX = exports['es_extended']:getSharedObject()
    
    while not ESX.IsPlayerLoaded() do
        Wait(100)
    end
    
    PlayerData = ESX.GetPlayerData()
    CheckAuthorization()
end)

-- Tjek om spilleren har autoriseret job
function CheckAuthorization()
    if PlayerData.job and Config.AuthorizedJobs[PlayerData.job.name] then
        isAuthorized = true
    else
        isAuthorized = false
    end
end

-- Opdater playerdata når job ændres
RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
    CheckAuthorization()
end)

-- Registrer keybind hvis aktiveret
if Config.UseKeybind then
    lib.registerContext({
        id = 'parkingfine_keybind',
        title = Config.KeybindDescription,
        options = {}
    })
    
    RegisterCommand('parkingfine_open', function()
        if isAuthorized then
            OpenParkingFineMenu()
        else
            lib.notify({
                title = 'Ingen adgang',
                description = 'Du har ikke tilladelse til at bruge dette system',
                type = 'error',
                duration = Config.NotificationDuration
            })
        end
    end, false)
    
    RegisterKeyMapping('parkingfine_open', Config.KeybindDescription, 'keyboard', Config.Keybind)
end

-- Funktion til at finde nærmeste køretøj
function GetClosestVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestVehicle = nil
    local closestDistance = Config.MaxDistance
    
    -- Hent alle køretøjer i nærheden
    local vehicles = GetGamePool('CVehicle')
    
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(playerCoords - vehicleCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestVehicle = vehicle
            end
        end
    end
    
    return closestVehicle
end

-- Funktion til at få nummerplade fra køretøj
function GetVehiclePlate(vehicle)
    if vehicle and DoesEntityExist(vehicle) then
        return GetVehicleNumberPlateText(vehicle)
    end
    return nil
end

-- Åbn hovedmenu for parkeringsbøder
function OpenParkingFineMenu()
    if not isAuthorized then
        lib.notify({
            title = 'Ingen adgang',
            description = 'Du er ikke autoriseret til at bruge dette system',
            type = 'error',
            duration = Config.NotificationDuration
        })
        return
    end
    
    local options = {
        {
            title = 'Udsted Parkeringsbøde',
            description = 'Giv en parkeringsbøde til en person i et køretøj',
            icon = 'car',
            onSelect = function()
                OpenIssueFineMenu()
            end
        },
        {
            title = 'Se Udstedte Bøder',
            description = 'Vis en liste over alle udstedte bøder',
            icon = 'list',
            onSelect = function()
                OpenFinesListMenu()
            end
        }
    }
    
    lib.registerContext({
        id = 'parkingfine_main',
        title = 'Parkeringsbøde System',
        options = options
    })
    
    lib.showContext('parkingfine_main')
end

-- Menu til at udstede en bøde
function OpenIssueFineMenu()
    local targetVehicle = GetClosestVehicle()
    
    if not targetVehicle then
        lib.notify({
            title = 'Intet køretøj fundet',
            description = 'Der er intet køretøj i nærheden',
            type = 'error',
            duration = Config.NotificationDuration
        })
        return
    end
    
    local vehiclePlate = GetVehiclePlate(targetVehicle)
    
    if not vehiclePlate then
        lib.notify({
            title = 'Fejl',
            description = 'Kunne ikke læse nummerplade',
            type = 'error',
            duration = Config.NotificationDuration
        })
        return
    end
    
    -- Input dialog med ox_lib
    local input = lib.inputDialog('Udsted Parkeringsbøde', {
        {
            type = 'input',
            label = 'Nummerplade',
            description = 'Nummerplade på køretøjet',
            required = true,
            default = vehiclePlate,
            disabled = true,
            icon = 'car'
        },
        {
            type = 'number',
            label = 'Bødebeløb',
            description = 'Indtast bødebeløbet (mellem ' .. Config.MinFineAmount .. ' og ' .. Config.MaxFineAmount .. ')',
            required = true,
            min = Config.MinFineAmount,
            max = Config.MaxFineAmount,
            icon = 'dollar-sign'
        },
        {
            type = 'input',
            label = 'Årsag',
            description = 'Indtast årsagen til bøden',
            required = true,
            icon = 'file-text'
        }
    })
    
    if not input then
        return -- Spilleren annullerede
    end
    
    local amount = tonumber(input[2])
    local reason = input[3]
    
    -- Valider input
    if not amount or amount < Config.MinFineAmount or amount > Config.MaxFineAmount then
        lib.notify({
            title = 'Ugyldigt beløb',
            description = 'Bødebeløbet skal være mellem ' .. Config.MinFineAmount .. ' og ' .. Config.MaxFineAmount,
            type = 'error',
            duration = Config.NotificationDuration
        })
        return
    end
    
    if not reason or reason == '' then
        lib.notify({
            title = 'Manglende årsag',
            description = 'Du skal angive en årsag til bøden',
            type = 'error',
            duration = Config.NotificationDuration
        })
        return
    end
    
    -- Send data til server
    TriggerServerEvent('luudi_parkingfine:server:issueFine', {
        vehiclePlate = vehiclePlate,
        amount = amount,
        reason = reason
    })
end

-- Menu til at vise liste over bøder
function OpenFinesListMenu()
    ESX.TriggerServerCallback('luudi_parkingfine:server:getFines', function(fines)
        if not fines or #fines == 0 then
            lib.notify({
                title = 'Ingen bøder',
                description = 'Der er ingen registrerede bøder',
                type = 'info',
                duration = Config.NotificationDuration
            })
            return
        end
        
        local options = {}
        
        for _, fine in ipairs(fines) do
            local status = fine.paid == 1 and '✅ Betalt' or '❌ Ubetalt'
            local description = string.format(
                'Beløb: $%d | %s\nÅrsag: %s\nDato: %s',
                fine.amount,
                status,
                fine.reason or 'Ingen årsag angivet',
                fine.created_at or 'Ukendt'
            )
            
            table.insert(options, {
                title = 'Bøde #' .. fine.id .. ' - ' .. (fine.issuer_name or 'Ukendt betjent'),
                description = description,
                icon = fine.paid == 1 and 'check-circle' or 'exclamation-circle',
                onSelect = function()
                    OpenFineDetailsMenu(fine)
                end
            })
        end
        
        lib.registerContext({
            id = 'parkingfine_list',
            title = 'Udstedte Parkeringsbøder',
            menu = 'parkingfine_main',
            options = options
        })
        
        lib.showContext('parkingfine_list')
    end)
end

-- Menu til at vise detaljer om en specifik bøde
function OpenFineDetailsMenu(fine)
    local options = {}
    
    if fine.paid == 0 then
        table.insert(options, {
            title = 'Marker som Betalt',
            description = 'Marker denne bøde som betalt',
            icon = 'check',
            onSelect = function()
                TriggerServerEvent('luudi_parkingfine:server:payFine', fine.id)
                Wait(500)
                OpenFinesListMenu()
            end
        })
    end
    
    table.insert(options, {
        title = 'Tilbage',
        description = 'Gå tilbage til bødelisten',
        icon = 'arrow-left',
        onSelect = function()
            OpenFinesListMenu()
        end
    })
    
    lib.registerContext({
        id = 'parkingfine_details',
        title = 'Bøde #' .. fine.id,
        menu = 'parkingfine_list',
        options = options
    })
    
    lib.showContext('parkingfine_details')
end

-- Event til at åbne menu fra eksterne scripts
RegisterNetEvent('luudi_parkingfine:client:openMenu', function()
    OpenParkingFineMenu()
end)

-- Notifikation når en bøde modtages
RegisterNetEvent('luudi_parkingfine:client:receiveFine', function(data)
    lib.notify({
        title = 'Parkeringsbøde Modtaget',
        description = string.format(
            'Du har modtaget en parkeringsbøde på $%d\nÅrsag: %s\n%s',
            data.amount,
            data.reason,
            data.autoDeducted and 'Beløbet er trukket fra din bankkonto' or 'Bøden skal betales manuelt'
        ),
        type = 'error',
        duration = Config.NotificationDuration * 2
    })
end)

-- Notifikation når en bøde er udstedt (til betjenten)
RegisterNetEvent('luudi_parkingfine:client:fineIssued', function(data)
    lib.notify({
        title = 'Bøde Udstedt',
        description = string.format(
            'Du har udstedt en parkeringsbøde på $%d til %s',
            data.amount,
            data.targetName
        ),
        type = 'success',
        duration = Config.NotificationDuration
    })
end)

-- Debug kommando
if Config.Debug then
    RegisterCommand('parkingfine_debug', function()
        print('isAuthorized:', isAuthorized)
        print('PlayerData.job:', json.encode(PlayerData.job))
    end, false)
end
