-- Hent ESX objekt
ESX = exports['es_extended']:getSharedObject()

-- Funktion til at validere om en spiller har autoriseret job
function IsPlayerAuthorized(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        return false
    end
    
    return Config.AuthorizedJobs[xPlayer.job.name] == true
end

-- Funktion til at logge handlinger (kan integreres med ESX logs)
function LogAction(action, source, data)
    if Config.Debug then
        print(string.format('[Luudi_ParkingFine] %s - Source: %s - Data: %s', 
            action, 
            source, 
            json.encode(data)
        ))
    end
    
    -- Her kan du integrere med ESX logs eller andre log-systemer
    -- Eksempel: TriggerEvent('esx:log', action, source, data)
end

-- Event til at udstede en parkeringsbøde
RegisterNetEvent('luudi_parkingfine:server:issueFine', function(data)
    local source = source
    
    -- Valider at afsenderen er autoriseret
    if not IsPlayerAuthorized(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Ingen adgang',
            description = 'Du er ikke autoriseret til at udstede bøder',
            type = 'error',
            duration = Config.NotificationDuration
        })
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Valider nummerplade
    if not data.vehiclePlate or data.vehiclePlate == '' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Fejl',
            description = 'Ugyldig nummerplade',
            type = 'error',
            duration = Config.NotificationDuration
        })
        return
    end
    
    -- Fjern mellemrum fra nummerplade
    local vehiclePlate = string.gsub(data.vehiclePlate, '%s+', '')
    
    if Config.Debug then
        print('^3[Luudi_ParkingFine] Looking up vehicle plate: ' .. vehiclePlate .. '^7')
    end
    
    -- Slå nummerplade op i owned_vehicles for at finde ejer
    -- TRIM og sammenlign uden mellemrum for at være sikker
    local query = [[
        SELECT owner FROM owned_vehicles 
        WHERE REPLACE(plate, ' ', '') = ?
    ]]
    
    MySQL.query(query, {vehiclePlate}, function(result)
        if Config.Debug then
            print('^3[Luudi_ParkingFine] Query result: ' .. json.encode(result) .. '^7')
        end
        
        if not result or #result == 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Køretøj ikke fundet',
                description = string.format('Der findes ingen registreret ejer af køretøj med nummerplade: %s', data.vehiclePlate),
                type = 'error',
                duration = Config.NotificationDuration
            })
            return
        end
        
        local targetIdentifier = result[1].owner
        local targetPlayer = ESX.GetPlayerFromIdentifier(targetIdentifier)
        
        -- Valider data
        local amount = tonumber(data.amount)
        if not amount or amount < Config.MinFineAmount or amount > Config.MaxFineAmount then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Ugyldigt beløb',
                description = 'Bødebeløbet er ugyldigt',
                type = 'error',
                duration = Config.NotificationDuration
            })
            return
        end
        
        local reason = tostring(data.reason) or 'Parkeringsbøde'
        
        -- Opret bøde direkte i database (virker for både online og offline spillere)
        local paid = 0
        
        -- Indsæt bøde i billing database
        local billingQuery = [[
            INSERT INTO billing (identifier, sender, target_type, target, label, amount) 
            VALUES (?, ?, ?, ?, ?, ?)
        ]]
        
        MySQL.insert(billingQuery, {
            targetIdentifier,
            xPlayer.identifier,
            'society',
            'society_police',
            reason,
            amount
        }, function(billingId)
            if Config.Debug then
                print('^3[Luudi_ParkingFine] Created billing with ID: ' .. tostring(billingId) .. '^7')
            end
            
            if billingId then
                -- Notificer target spiller hvis de er online
                if targetPlayer then
                    TriggerClientEvent('ox_lib:notify', targetPlayer.source, {
                        title = 'Parkeringsbøde modtaget',
                        description = string.format('Du har modtaget en parkeringsbøde på $%d\nÅrsag: %s\nKøretøj: %s\nBrug /bills for at betale', amount, reason, vehiclePlate),
                        type = 'error',
                        duration = Config.NotificationDuration * 2
                    })
                else
                    -- Notificer issuer at spilleren er offline
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Ejer offline',
                        description = 'Køretøjets ejer er offline. Bøden vil vente når de logger ind.',
                        type = 'warning',
                        duration = Config.NotificationDuration
                    })
                end
            end
        end)
        
        -- Indsæt bøde i database
        local insertQuery = [[
            INSERT INTO luudi_parkingfines 
            (identifier, issuer, issuer_name, vehicle_plate, amount, reason, paid, auto_deducted, created_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ]]
        
        MySQL.insert(insertQuery, {
            targetIdentifier,
            xPlayer.identifier,
            xPlayer.getName(),
            vehiclePlate,
            amount,
            reason,
            paid,
            0 -- auto_deducted altid 0 da ESX billing håndterer betalinger
        }, function(insertId)
            if insertId then
                -- Log handlingen
                LogAction('FINE_ISSUED', source, {
                    fineId = insertId,
                    target = targetIdentifier,
                    plate = vehiclePlate,
                    amount = amount,
                    reason = reason
                })
                
                -- Send notifikationer
                TriggerClientEvent('luudi_parkingfine:client:fineIssued', source, {
                    amount = amount,
                    targetName = targetPlayer and targetPlayer.getName() or 'Ukendt ejer'
                })
                
                -- Success notifikation til issuer
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Bøde udstedt',
                    description = string.format('Parkeringsbøde på $%d er udstedt til køretøj %s%s', 
                        amount, 
                        vehiclePlate,
                        targetPlayer and (' (Ejer: ' .. targetPlayer.getName() .. ')') or ' (Ejer offline)'
                    ),
                    type = 'success',
                    duration = Config.NotificationDuration
                })
            else
                -- Fejl ved indsættelse i database
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Database fejl',
                    description = 'Der opstod en fejl ved udstedelse af bøden',
                    type = 'error',
                    duration = Config.NotificationDuration
                })
            end
        end)
    end)
end)

-- Callback til at hente alle bøder (kun for autoriserede)
ESX.RegisterServerCallback('luudi_parkingfine:server:getFines', function(source, cb)
    -- Valider autorisation
    if not IsPlayerAuthorized(source) then
        cb({})
        return
    end
    
    local query = [[
        SELECT * FROM luudi_parkingfines 
        ORDER BY created_at DESC 
        LIMIT 100
    ]]
    
    MySQL.query(query, {}, function(result)
        cb(result or {})
    end)
end)

-- Callback til at hente bøder for en specifik spiller
ESX.RegisterServerCallback('luudi_parkingfine:server:getPlayerFines', function(source, cb, identifier)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb({})
        return
    end
    
    -- Spillere kan kun se deres egne bøder, medmindre de er autoriserede
    local targetIdentifier = identifier or xPlayer.identifier
    
    if targetIdentifier ~= xPlayer.identifier and not IsPlayerAuthorized(source) then
        cb({})
        return
    end
    
    local query = [[
        SELECT * FROM luudi_parkingfines 
        WHERE identifier = ? 
        ORDER BY created_at DESC
    ]]
    
    MySQL.query(query, {targetIdentifier}, function(result)
        cb(result or {})
    end)
end)

-- Event til at betale en bøde
RegisterNetEvent('luudi_parkingfine:server:payFine', function(fineId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        return
    end
    
    -- Valider at spilleren er autoriseret (kun politi kan markere som betalt manuelt)
    if not IsPlayerAuthorized(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Ingen adgang',
            description = 'Du kan ikke markere bøder som betalt',
            type = 'error',
            duration = Config.NotificationDuration
        })
        return
    end
    
    -- Hent bøde fra database
    local query = [[
        SELECT * FROM luudi_parkingfines 
        WHERE id = ?
    ]]
    
    MySQL.query(query, {fineId}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Fejl',
                description = 'Bøden blev ikke fundet',
                type = 'error',
                duration = Config.NotificationDuration
            })
            return
        end
        
        local fine = result[1]
        
        if fine.paid == 1 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Allerede betalt',
                description = 'Denne bøde er allerede markeret som betalt',
                type = 'info',
                duration = Config.NotificationDuration
            })
            return
        end
        
        -- Opdater bøde som betalt
        local updateQuery = [[
            UPDATE luudi_parkingfines 
            SET paid = 1, paid_at = NOW() 
            WHERE id = ?
        ]]
        
        MySQL.update(updateQuery, {fineId}, function(affectedRows)
            if affectedRows > 0 then
                -- Log handlingen
                LogAction('FINE_PAID', source, {
                    fineId = fineId,
                    paidBy = xPlayer.identifier
                })
                
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Bøde betalt',
                    description = string.format('Bøde #%d er markeret som betalt', fineId),
                    type = 'success',
                    duration = Config.NotificationDuration
                })
            else
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Fejl',
                    description = 'Der opstod en fejl ved opdatering af bøden',
                    type = 'error',
                    duration = Config.NotificationDuration
                })
            end
        end)
    end)
end)

-- Event til at spillere selv kan betale deres bøder
RegisterNetEvent('luudi_parkingfine:server:payOwnFine', function(fineId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        return
    end
    
    -- Hent bøde fra database
    local query = [[
        SELECT * FROM luudi_parkingfines 
        WHERE id = ? AND identifier = ?
    ]]
    
    MySQL.query(query, {fineId, xPlayer.identifier}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Fejl',
                description = 'Bøden blev ikke fundet',
                type = 'error',
                duration = Config.NotificationDuration
            })
            return
        end
        
        local fine = result[1]
        
        if fine.paid == 1 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Allerede betalt',
                description = 'Denne bøde er allerede betalt',
                type = 'info',
                duration = Config.NotificationDuration
            })
            return
        end
        
        -- Tjek om spilleren har nok penge
        local account = xPlayer.getAccount(Config.DefaultCurrency)
        
        if not account or account.money < fine.amount then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Utilstrækkelige midler',
                description = string.format('Du mangler $%d for at betale denne bøde', fine.amount - (account and account.money or 0)),
                type = 'error',
                duration = Config.NotificationDuration
            })
            return
        end
        
        -- Træk penge og opdater bøde
        xPlayer.removeAccountMoney(Config.DefaultCurrency, fine.amount)
        
        local updateQuery = [[
            UPDATE luudi_parkingfines 
            SET paid = 1, paid_at = NOW() 
            WHERE id = ?
        ]]
        
        MySQL.update(updateQuery, {fineId}, function(affectedRows)
            if affectedRows > 0 then
                -- Log handlingen
                LogAction('FINE_PAID_BY_PLAYER', source, {
                    fineId = fineId,
                    amount = fine.amount
                })
                
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Bøde betalt',
                    description = string.format('Du har betalt bøde #%d på $%d', fineId, fine.amount),
                    type = 'success',
                    duration = Config.NotificationDuration
                })
            else
                -- Refunder hvis opdatering fejlede
                xPlayer.addAccountMoney(Config.DefaultCurrency, fine.amount)
                
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Fejl',
                    description = 'Der opstod en fejl. Dine penge er blevet refunderet.',
                    type = 'error',
                    duration = Config.NotificationDuration
                })
            end
        end)
    end)
end)

-- Kommando til at åbne parkeringsbøde menu (kun for autoriserede)
RegisterCommand('parkingfine', function(source, args, rawCommand)
    if IsPlayerAuthorized(source) then
        TriggerClientEvent('luudi_parkingfine:client:openMenu', source)
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Ingen adgang',
            description = 'Du har ikke tilladelse til at bruge denne kommando',
            type = 'error',
            duration = Config.NotificationDuration
        })
    end
end, false)

-- Kommando til at betale egne bøder
RegisterCommand('payfine', function(source, args, rawCommand)
    local fineId = tonumber(args[1])
    
    if not fineId then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Ugyldig kommando',
            description = 'Brug: /payfine [bøde-id]',
            type = 'error',
            duration = Config.NotificationDuration
        })
        return
    end
    
    TriggerEvent('luudi_parkingfine:server:payOwnFine', fineId, source)
end, false)

-- Kommando til at se egne bøder
RegisterCommand('myfines', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        return
    end
    
    local query = [[
        SELECT * FROM luudi_parkingfines 
        WHERE identifier = ? 
        ORDER BY created_at DESC
    ]]
    
    MySQL.query(query, {xPlayer.identifier}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Ingen bøder',
                description = 'Du har ingen registrerede parkeringsbøder',
                type = 'info',
                duration = Config.NotificationDuration
            })
            return
        end
        
        local message = 'Dine parkeringsbøder:\n'
        for i, fine in ipairs(result) do
            local status = fine.paid == 1 and 'Betalt' or 'Ubetalt'
            message = message .. string.format('\n#%d: $%d - %s (%s)', fine.id, fine.amount, fine.reason, status)
        end
        
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Mine Bøder',
            description = message,
            type = 'info',
            duration = Config.NotificationDuration * 2
        })
    end)
end, false)

-- Export til eksterne scripts
exports('GetParkingFineForPlayer', function(identifier)
    local query = [[
        SELECT * FROM luudi_parkingfines 
        WHERE identifier = ? 
        ORDER BY created_at DESC
    ]]
    
    local result = MySQL.query.await(query, {identifier})
    return result or {}
end)

exports('GetAllUnpaidFines', function()
    local query = [[
        SELECT * FROM luudi_parkingfines 
        WHERE paid = 0 
        ORDER BY created_at DESC
    ]]
    
    local result = MySQL.query.await(query, {})
    return result or {}
end)

exports('GetFineById', function(fineId)
    local query = [[
        SELECT * FROM luudi_parkingfines 
        WHERE id = ?
    ]]
    
    local result = MySQL.query.await(query, {fineId})
    return result and result[1] or nil
end)

-- Print ved resource start
print('^2[Luudi_ParkingFine]^7 Server-side loaded successfully')
