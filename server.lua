local ESX = exports['es_extended']:getSharedObject()

-- Versie informatie
local CurrentVersion = '1.1.3'
local GithubVersion = nil
local ResourceName = GetCurrentResourceName()

-- Bijhouden van actieve testritvoertuigen per speler
local ActiveTestDrives = {}
local PlayerCooldowns = {}



-- Check for updates from GitHub
local function CheckVersion()
    -- GitHub versie check URL
    local url = "https://raw.githubusercontent.com/BapkeD/bt_donatietestrit/main/version.txt"
    
    -- Maak een async HTTP request
    PerformHttpRequest(url, function(err, responseText, headers)
        if err ~= 200 then
            print("^3[" .. ResourceName .. "] Kan niet verbinden met GitHub voor versie controle^7")
            return
        end
        
        -- Verwerk de versie
        GithubVersion = responseText:gsub("%s+", "")  -- Remove whitespace
        
        if GithubVersion then
            if GithubVersion ~= CurrentVersion then
                print("^3[" .. ResourceName .. "] UPDATE BESCHIKBAAR!^7")
                print("^3[" .. ResourceName .. "] Huidige versie: " .. CurrentVersion .. "^7")
                print("^3[" .. ResourceName .. "] Nieuwe versie: " .. GithubVersion .. "^7")
                print("^3[" .. ResourceName .. "] Update op: github.com/BapkeD/bt_donatietestrit^7")
            else
                print("^2[" .. ResourceName .. "] Versie is up-to-date (" .. CurrentVersion .. ")^7")
            end
        end
    end, "GET", "", {["Content-Type"] = "application/json"})
end

-- Dependency checks
local function CheckDependencies()
    local missingDeps = {}
    local outdatedDeps = {}
    
    -- Check ESX
    if not ESX then
        table.insert(missingDeps, "es_extended")
    end
    
    -- Check ox_lib if being used
    if Config and Config.NotificationType == 'ox_lib' or Config.UseTarget and GetResourceState('ox_target') == 'started' then
        local oxlib = GetResourceState('ox_lib')
        if oxlib ~= 'started' then
            table.insert(missingDeps, "ox_lib")
        else
            -- Check ox_lib version (requires ox_lib v3.0.0 or newer)
            local success, version = pcall(function()
                return exports['ox_lib']:version()
            end)
            
            if not success or not version or version < '3.0.0' then
                table.insert(outdatedDeps, {name = "ox_lib", current = version or "unknown", required = "3.0.0"})
            end
        end
    end
    
    -- Check target system if enabled
    if Config and Config.UseTarget then
        local oxTarget = GetResourceState('ox_target')
        local qbTarget = GetResourceState('qb-target')
        
        if oxTarget ~= 'started' and qbTarget ~= 'started' then
            table.insert(missingDeps, "ox_target or qb-target (Config.UseTarget is enabled)")
        end
    end
    
    -- Display warnings for missing dependencies
    if #missingDeps > 0 then
        print("^1[" .. ResourceName .. "] WAARSCHUWING: Ontbrekende dependencies gedetecteerd:^7")
        for _, dep in ipairs(missingDeps) do
            print("^1[" .. ResourceName .. "] Ontbrekend: " .. dep .. "^7")
        end
    end
    
    -- Display warnings for outdated dependencies
    if #outdatedDeps > 0 then
        print("^3[" .. ResourceName .. "] WAARSCHUWING: Verouderde dependencies gedetecteerd:^7")
        for _, dep in ipairs(outdatedDeps) do
            print("^3[" .. ResourceName .. "] Verouderd: " .. dep.name .. " (huidige versie: " .. dep.current .. ", vereist: " .. dep.required .. ")^7")
        end
    end
    
    -- Check for configuration issues
    if Config then
        local configIssues = {}
        
        -- Check if there are enough locations for all donation vehicles
        if #Config.Locations < #Config.DonationVehicles then
            table.insert(configIssues, "Er zijn meer voertuigen geconfigureerd (" .. #Config.DonationVehicles .. ") dan locaties (" .. #Config.Locations .. ")")
        end
        
        -- Display warnings for configuration issues
        if #configIssues > 0 then
            print("^3[" .. ResourceName .. "] WAARSCHUWING: Configuratie problemen gedetecteerd:^7")
            for _, issue in ipairs(configIssues) do
                print("^3[" .. ResourceName .. "] Configuratie: " .. issue .. "^7")
            end
        end
    end
    
    -- Return true if no issues found
    return #missingDeps == 0 and #outdatedDeps == 0
end

-- Run dependency checks when resource starts
Citizen.CreateThread(function()
    Wait(2000) -- Wait for other resources to initialize
    local dependenciesOK = CheckDependencies()
    
    if not dependenciesOK then
        print("^1[" .. ResourceName .. "] KRITIEKE WAARSCHUWING: Deze resource werkt mogelijk niet correct vanwege ontbrekende of verouderde dependencies!^7")
        print("^1[" .. ResourceName .. "] Controleer bovenstaande berichten en los de problemen op om optimale werking te garanderen.^7")
    else
        print("^2[" .. ResourceName .. "] Dependency check: OK^7")
    end
    
    -- Check for updates
    CheckVersion()
end)

-- Event wanneer speler een testrit start
RegisterNetEvent('donation_testdrive:startTestDrive')
AddEventHandler('donation_testdrive:startTestDrive', function(vehicleModel)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if xPlayer then
        local playerName = xPlayer.getName()
        local playerIdentifier = xPlayer.getIdentifier()
        
        -- Anti-exploit check
        local validVehicle = false
        for _, vehicle in ipairs(Config.DonationVehicles) do
            if vehicle.model == vehicleModel then
                validVehicle = true
                break
            end
        end
        
        if not validVehicle then
            print("^1[donation_testdrive] WAARSCHUWING: Speler probeerde een ongeldig voertuig te spawnen: " .. playerName .. " (" .. playerIdentifier .. ") - " .. vehicleModel)
            return
        end
        
        -- Testrit informatie opslaan
        ActiveTestDrives[_source] = {
            identifier = playerIdentifier,
            name = playerName,
            model = vehicleModel,
            startTime = os.time()
        }
        
        -- Testrit start loggen
        print(string.format('^2[donation_testdrive] Player %s (%s) started test drive of %s', 
            playerName, playerIdentifier, vehicleModel))
    end
end)

-- Event wanneer speler een testrit beëindigt
RegisterNetEvent('donation_testdrive:endTestDrive')
AddEventHandler('donation_testdrive:endTestDrive', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if xPlayer and ActiveTestDrives[_source] then
        local playerName = xPlayer.getName()
        local model = ActiveTestDrives[_source].model
        local duration = os.time() - ActiveTestDrives[_source].startTime
        
        -- Testrit einde loggen
        print(string.format('^2[donation_testdrive] Player %s ended test drive of %s after %s seconds', 
            playerName, model, duration))
        
        -- Cooldown instellen indien geactiveerd
        if Config.EnableCooldown then
            local playerIdentifier = xPlayer.getIdentifier()
            PlayerCooldowns[playerIdentifier] = os.time() + Config.CooldownTime
            
            -- Sync cooldown naar client - stuur resterende seconden in plaats van timestamp
            TriggerClientEvent('donation_testdrive:syncCooldown', _source, Config.CooldownTime)
        end
        
        -- Verwijderen uit actieve testritvoertuigen
        ActiveTestDrives[_source] = nil
    end
end)

-- Event om cooldown te synchroniseren bij client connect/reconnect
RegisterNetEvent('donation_testdrive:requestCooldown')
AddEventHandler('donation_testdrive:requestCooldown', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if xPlayer and Config.EnableCooldown then
        local playerIdentifier = xPlayer.getIdentifier()
        if PlayerCooldowns[playerIdentifier] and PlayerCooldowns[playerIdentifier] > os.time() then
            -- Stuur resterende seconden in plaats van timestamp
            local remainingSeconds = PlayerCooldowns[playerIdentifier] - os.time()
            TriggerClientEvent('donation_testdrive:syncCooldown', _source, remainingSeconds)
        else
            -- Geen cooldown
            TriggerClientEvent('donation_testdrive:syncCooldown', _source, 0)
        end
    end
end)

-- Afhandelen van speler die disconnect tijdens testrit
AddEventHandler('playerDropped', function()
    local _source = source
    
    if ActiveTestDrives[_source] then
        local playerName = ActiveTestDrives[_source].name
        local model = ActiveTestDrives[_source].model
        local duration = os.time() - ActiveTestDrives[_source].startTime
        
        -- Disconnect tijdens testrit loggen
        print(string.format('^3[donation_testdrive] Player %s disconnected during test drive of %s after %s seconds', 
            playerName, model, duration))
        
        -- Verwijderen uit actieve testritvoertuigen
        ActiveTestDrives[_source] = nil
    end
end)

-- Commando om actieve testritten te controleren (voor admins)
ESX.RegisterCommand('testdrives', 'admin', function(xPlayer, args, showError)
    if next(ActiveTestDrives) == nil then
        xPlayer.triggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {'System', 'No active test drives at the moment.'}
        })
        return
    end
    
    local message = 'Active test drives:\n'
    for playerId, data in pairs(ActiveTestDrives) do
        local duration = os.time() - data.startTime
        message = message .. string.format('- Player: %s, Vehicle: %s, Duration: %s seconds\n', 
            data.name, data.model, duration)
    end
    
    xPlayer.triggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {'System', message}
    })
end, false)

-- Commando om alle cooldowns te bekijken
ESX.RegisterCommand('testdrivecooldowns', 'admin', function(xPlayer, args, showError)
    if next(PlayerCooldowns) == nil then
        xPlayer.triggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {'System', 'No active cooldowns at the moment.'}
        })
        return
    end
    
    local message = 'Active test drive cooldowns:\n'
    local currentTime = os.time()
    
    for identifier, cooldownTime in pairs(PlayerCooldowns) do
        local remainingTime = cooldownTime - currentTime
        if remainingTime > 0 then
            local playerName = "Unknown"
            for _, xP in pairs(ESX.GetExtendedPlayers()) do
                if xP.identifier == identifier then
                    playerName = xP.getName()
                    break
                end
            end
            message = message .. string.format('- Player: %s, Remaining: %s seconds\n', 
                playerName, remainingTime)
        end
    end
    
    xPlayer.triggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {'System', message}
    })
end, false)

-- Commando om cooldown voor een speler te resetten
ESX.RegisterCommand('resetcooldown', 'admin', function(xPlayer, args, showError)
    if not args.playerId then
        xPlayer.showNotification('Specificeer een spelernaam of ID.')
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(args.playerId)
    if not targetPlayer then
        xPlayer.showNotification('Speler niet gevonden.')
        return
    end
    
    local identifier = targetPlayer.getIdentifier()
    PlayerCooldowns[identifier] = nil
    
    -- Notificeer speler en admin
    targetPlayer.showNotification('Je testrit cooldown is gereset door een admin.')
    xPlayer.showNotification('Testrit cooldown gereset voor ' .. targetPlayer.getName())
    
    -- Sync naar client
    TriggerClientEvent('donation_testdrive:syncCooldown', targetPlayer.source, 0)
end, true, {help = 'Reset test drive cooldown for a player', arguments = {
    {name = 'playerId', help = 'Player ID', type = 'number'}
}})

-- Car wipe event handler (als je een carwipe script gebruikt)
AddEventHandler('server:deleteAllVehicles', function()
    -- Dit event zou getriggerd moeten worden door je server's carwipe script
    -- We gebruiken dit om alle actieve testrijders te informeren dat hun voertuigen worden gerespawnd
    for playerId, _ in pairs(ActiveTestDrives) do
        TriggerClientEvent('donation_testdrive:respawnTestVehicle', playerId)
    end
end)

-- Commando om handmatig alle testritvoertuigen te respawnen
ESX.RegisterCommand('respawntestcars', 'admin', function(xPlayer, args, showError)
    -- Tel actieve testritten
    local count = 0
    for _, _ in pairs(ActiveTestDrives) do
        count = count + 1
    end
    
    -- Notificeer admins
    xPlayer.triggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {'System', string.format('Respawning %d test drive vehicles.', count)}
    })
    
    -- Trigger respawn voor alle actieve testrijders
    for playerId, _ in pairs(ActiveTestDrives) do
        TriggerClientEvent('donation_testdrive:respawnTestVehicle', playerId)
    end
end, false)