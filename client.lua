local ESX = exports['es_extended']:getSharedObject()
local ResourceName = GetCurrentResourceName()

-- Modules
local Utils = nil
local UI = nil
local Vehicles = nil

-- Globale variabelen voor voertuigen
local CurrentVehicle = nil
local TestDriveVehicle = nil
local TestDriveActive = false
local TimerActive = false
local timeRemaining = 0
local currentTestModel = nil
local lastPlayerPosition = nil
local DonationVehicles = {}
local player_cooldowns = {}

-- Export modules - keep these but they'll be set up properly after modules are loaded
exports('getUtils', function() return Utils end)
exports('getUI', function() return UI end)
exports('getVehicles', function() return Vehicles end)

-- Resource stop handler (verberg UI als de resource stopt)
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if UI and TestDriveActive then
            UI.HideTestDriveTimer()
        end
    end
end)

-- Player death handler
AddEventHandler('esx:onPlayerDeath', function(data)
    if UI and TestDriveActive then
        Utils.Notify("Je bent overleden. De proefrit wordt beëindigd.", "error")
        
        -- Hide UI immediately when player dies
        UI.HideTestDriveTimer()
        
        -- End test drive after a short delay
        Citizen.SetTimeout(2000, function()
            if Vehicles and TestDriveActive then
                Vehicles.EndTestDrive()
            end
        end)
    end
end)

-- Client-side dependency checks
local function CheckDependencies()
    local issues = {}
    
    -- Check ESX
    if not ESX then
        table.insert(issues, "ESX kon niet worden geladen")
    end
    
    -- Check ox_lib if being used
    if Config.NotificationType == 'ox_lib' or Config.UseTarget and GetResourceState('ox_target') == 'started' then
        local oxlib = GetResourceState('ox_lib')
        if oxlib ~= 'started' then
            table.insert(issues, "ox_lib is niet gestart maar wel vereist voor deze configuratie")
        end
    end
    
    -- Check target integrations
    if Config.UseTarget then
        local oxTarget = GetResourceState('ox_target')
        local qbTarget = GetResourceState('qb-target')
        
        if oxTarget ~= 'started' and qbTarget ~= 'started' then
            table.insert(issues, "Config.UseTarget is ingeschakeld, maar er is geen target systeem (ox_target of qb-target) actief")
        end
    end
    
    return issues
end

-- Load modules with proper dependency management - fix circular references
function LoadModules()
    -- First load Utils (no dependencies)
    local utilsFile = LoadResourceFile(GetCurrentResourceName(), 'modules/utils.lua')
    Utils = load(utilsFile)()
    
    -- Next load all module files without initializing them yet
    local uiFile = LoadResourceFile(GetCurrentResourceName(), 'modules/ui.lua')
    local uiModuleUninitialized = load(uiFile)()
    
    local vehiclesFile = LoadResourceFile(GetCurrentResourceName(), 'modules/vehicles.lua')
    local vehiclesModuleUninitialized = load(vehiclesFile)()
    
    -- Now initialize them in the right order to avoid circular dependencies
    Vehicles = vehiclesModuleUninitialized.Init(Utils, nil) -- Initialize with nil for UI first
    UI = uiModuleUninitialized.Init(Utils, Vehicles) -- UI needs both Utils and Vehicles
    
    -- Update Vehicles with the UI reference
    Vehicles = vehiclesModuleUninitialized.Init(Utils, UI)
    
    -- Return success
    return Utils ~= nil and UI ~= nil and Vehicles ~= nil
end

-- Initialization thread
Citizen.CreateThread(function()
    Wait(500) -- Geef de resource een moment om volledig te laden
    
    -- Load modules with proper dependency management
    local modulesLoaded = LoadModules()
    
    if not modulesLoaded then
        print("^1[" .. ResourceName .. "] ERROR: Failed to load modules^7")
        return
    end
    
    -- Controleer dependencies na initialisatie
    local issues = CheckDependencies()
    if #issues > 0 then
        print("^1[" .. ResourceName .. "] CLIENT: Problemen gedetecteerd:^7")
        for _, issue in ipairs(issues) do
            print("^1[" .. ResourceName .. "] " .. issue .. "^7")
        end
    end
    
    -- Initialiseer de resource
    InitializeResource()
end)

-- Initialisatie functie
function InitializeResource()
    while ESX == nil do
        Wait(100)
    end
    
    -- Maak de blip
    Vehicles.CreateDonationBlip()
    
    -- Spawn de voertuigen
    Vehicles.SpawnDonationVehicles()
    
    -- Vraag huidige cooldown op bij server
    TriggerServerEvent('donation_testdrive:requestCooldown')
end

-- Event handler voor cooldown synchronisatie
RegisterNetEvent('donation_testdrive:syncCooldown')
AddEventHandler('donation_testdrive:syncCooldown', function(remainingSeconds)
    local serverId = GetPlayerServerId(PlayerId())
    -- Gebruik GetGameTimer in plaats van os.time (niet beschikbaar in client context)
    player_cooldowns[serverId] = remainingSeconds > 0 and (GetGameTimer() + (remainingSeconds * 1000)) or nil
end)

-- Hoofdloop voor interactie met de voertuigen (als target systeem niet wordt gebruikt)
Citizen.CreateThread(function()
    -- Wacht tot modules geladen zijn
    while Utils == nil or Vehicles == nil or UI == nil do
        Wait(100)
    end
    
    if Config.UseTarget then return end
    
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        
        if not TestDriveActive then
            local playerCoords = GetEntityCoords(playerPed)
            local closestVehicle, closestIndex, distance = Vehicles.GetClosestDonationVehicle()
            
            if closestVehicle and closestIndex then
                sleep = 0
                
                if Utils.IsPlayerNearPoint(GetEntityCoords(closestVehicle), 2.0) then
                    -- Teken 3D tekst
                    local pos = GetEntityCoords(closestVehicle)
                    DrawText3D(pos.x, pos.y, pos.z + 1.0, '[~g~E~w~] Bekijk ' .. Config.DonationVehicles[closestIndex].label)
                    
                    -- Controleer input
                    if IsControlJustReleased(0, 38) then -- E toets
                        UI.OpenDonationMenu(closestIndex)
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Functie voor het tekenen van 3D tekst
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 41, 41, 125)
end

-- Target system integratie
Citizen.CreateThread(function()
    -- Wacht tot modules geladen zijn
    while Utils == nil or Vehicles == nil or UI == nil do
        Wait(100)
    end
    
    if not Config.UseTarget then return end
    
    -- Wacht voor de voertuigen om te spawnen
    Wait(1000)
    
    if GetResourceState('ox_target') == 'started' then
        for i, vehData in pairs(DonationVehicles) do
            if DoesEntityExist(vehData.entity) then
                exports.ox_target:addLocalEntity(vehData.entity, {
                    {
                        name = 'view_donation_vehicle_' .. i,
                        icon = 'fas fa-car',
                        label = 'Bekijk Voertuig',
                        onSelect = function()
                            if TestDriveActive then
                                Utils.Notify('Je bent al bezig met een proefrit!', 'error')
                                return
                            end
                            UI.OpenDonationMenu(i)
                        end,
                        canInteract = function()
                            return not TestDriveActive
                        end
                    }
                })
            end
        end
    elseif GetResourceState('qb-target') == 'started' then
        for i, vehData in pairs(DonationVehicles) do
            if DoesEntityExist(vehData.entity) then
                exports['qb-target']:AddTargetEntity(vehData.entity, {
                    options = {
                        {
                            type = "client",
                            icon = "fas fa-car",
                            label = "Bekijk Voertuig",
                            action = function()
                                if TestDriveActive then
                                    Utils.Notify('Je bent al bezig met een proefrit!', 'error')
                                    return
                                end
                                UI.OpenDonationMenu(i)
                            end,
                            canInteract = function()
                                return not TestDriveActive
                            end
                        },
                    },
                    distance = 2.5,
                })
            end
        end
    end
end)

-- Command om een testrit handmatig te beëindigen
RegisterCommand('endtestdrive', function()
    -- Wacht tot modules geladen zijn
    if Utils == nil or Vehicles == nil then return end
    
    if TestDriveActive then
        Vehicles.EndTestDrive()
    else
        Utils.Notify('Je bent momenteel niet bezig met een proefrit.', 'error')
    end
end, false)

-- Event handler for starting test drive (called from UI module)
RegisterNetEvent('donation_testdrive:startTestDrive')
AddEventHandler('donation_testdrive:startTestDrive', function(model, spawnPoint)
    -- Wacht tot modules geladen zijn
    if Vehicles == nil then return end
    
    Vehicles.StartTestDrive(model, spawnPoint)
end)

-- Event handler for respawning test drive vehicle after car wipe
RegisterNetEvent('donation_testdrive:respawnTestVehicle')
AddEventHandler('donation_testdrive:respawnTestVehicle', function()
    -- Wacht tot modules geladen zijn
    if Utils == nil or Vehicles == nil then return end
    
    if TestDriveActive and currentTestModel then
        Utils.Notify('Je proefrit voertuig wordt opnieuw gespawnd na server cleanup.', 'info')
        
        -- Small delay to ensure any carwipe script finishes first
        Citizen.SetTimeout(1000, function()
            -- Find the original location
            local spawnPoint = nil
            for _, vehData in pairs(DonationVehicles) do
                if vehData.data.model == currentTestModel then
                    spawnPoint = vehData.location.SpawnPoint
                    break
                end
            end
            
            if spawnPoint then
                Vehicles.StartTestDrive(currentTestModel, spawnPoint)
            else
                -- Fallback to first location
                Vehicles.StartTestDrive(currentTestModel, Config.Locations[1].SpawnPoint)
            end
        end)
    end
    
    -- Also respawn all donation vehicles
    Citizen.SetTimeout(1500, function()
        Vehicles.SpawnDonationVehicles()
    end)
end) 