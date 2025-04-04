-- Vehicles Module for handling vehicle management and test drives
local Vehicles = {}

-- Remove the exports and make local variables that will be set through Init
local Utils = nil
local UI = nil

-- Add initialization function
function Vehicles.Init(utilsModule, uiModule)
    Utils = utilsModule
    UI = uiModule
    return Vehicles
end

-- Globale variabelen voor voertuigen
DonationVehicles = {}
TestDriveVehicle = nil
TestDriveActive = false
TimerActive = false
timeRemaining = 0
currentTestModel = nil
lastPlayerPosition = nil
player_cooldowns = {}

-- Cache voor voertuig locaties om herhaaldelijke berekeningen te voorkomen
local vehicleLocationsCache = {}

-- Maak een enkele blip voor het donatiegebied
function Vehicles.CreateDonationBlip()
    -- Bereken het middelpunt van alle locaties
    local centerX, centerY, centerZ = 0, 0, 0
    for i, location in ipairs(Config.Locations) do
        centerX = centerX + location.Coords.x
        centerY = centerY + location.Coords.y
        centerZ = centerZ + location.Coords.z
    end
    
    centerX = centerX / #Config.Locations
    centerY = centerY / #Config.Locations
    centerZ = centerZ / #Config.Locations
    
    -- Maak een enkele blip op het middelpunt
    local blip = AddBlipForCoord(centerX, centerY, centerZ)
    SetBlipSprite(blip, Config.Blip.Sprite)
    SetBlipDisplay(blip, Config.Blip.Display)
    SetBlipScale(blip, Config.Blip.Scale)
    SetBlipColour(blip, Config.Blip.Color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.Name)
    EndTextCommandSetBlipName(blip)
end

-- Spawn alle donatievoertuigen
function Vehicles.SpawnDonationVehicles()
    -- Verwijder eerst alle bestaande voertuigen
    for _, vehicle in pairs(DonationVehicles) do
        if DoesEntityExist(vehicle.entity) then
            DeleteVehicle(vehicle.entity)
        end
    end
    
    -- Maak de tabel leeg
    DonationVehicles = {}
    vehicleLocationsCache = {}
    
    -- Optimaliseer door alle modellen eerst te laden
    local modelHashes = {}
    for i, vehConfig in ipairs(Config.DonationVehicles) do
        if i <= #Config.Locations then
            modelHashes[i] = GetHashKey(vehConfig.model)
            RequestModel(modelHashes[i])
        end
    end
    
    -- Wacht tot modellen geladen zijn (max 5 seconden)
    local timeout = GetGameTimer() + 5000
    while GetGameTimer() < timeout do
        local allLoaded = true
        for i, hash in pairs(modelHashes) do
            if not HasModelLoaded(hash) then
                allLoaded = false
                break
            end
        end
        
        if allLoaded then
            break
        end
        
        Wait(50)
    end
    
    -- Spawn de voertuigen op elke locatie
    for i, location in ipairs(Config.Locations) do
        -- Spawn alleen een voertuig als we een model hebben voor deze locatie-index
        if Config.DonationVehicles[i] and HasModelLoaded(modelHashes[i]) then
            -- Spawn het voertuig
            local vehicle = CreateVehicle(modelHashes[i], location.Coords.x, location.Coords.y, location.Coords.z, location.Heading, false, false)
            
            -- Voertuig instellen
            SetVehicleDoorsLocked(vehicle, 2) -- Vergrendel het voertuig
            SetVehicleDirtLevel(vehicle, 0.0) -- Maak voertuig schoon
            FreezeEntityPosition(vehicle, true) -- Voorkom dat het beweegt
            SetVehicleNumberPlateText(vehicle, "DONATIE"..i)
            
            -- Sla referentie op met modelgegevens
            DonationVehicles[i] = {
                entity = vehicle,
                data = Config.DonationVehicles[i],
                location = location
            }
            
            -- Cache de locatie voor snellere toegang
            vehicleLocationsCache[vehicle] = {
                index = i,
                coords = vector3(location.Coords.x, location.Coords.y, location.Coords.z)
            }
        else
            if not HasModelLoaded(modelHashes[i]) then
                print("^1ERROR: Model kon niet geladen worden: "..Config.DonationVehicles[i].model)
            end
        end
    end
    
    -- Geef de modellen vrij
    for _, hash in pairs(modelHashes) do
        SetModelAsNoLongerNeeded(hash)
    end
end

-- Get closest donation vehicle - Performance geoptimaliseerde versie
function Vehicles.GetClosestDonationVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestDistance = 3.0 -- Only interact within 3 meters
    local closestVehicle = nil
    local closestIndex = nil
    
    -- Gebruik de cache voor snellere verwerking
    for entity, data in pairs(vehicleLocationsCache) do
        if DoesEntityExist(entity) then
            local distance = #(playerCoords - data.coords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestVehicle = entity
                closestIndex = data.index
            end
        end
    end
    
    return closestVehicle, closestIndex, closestDistance
end

-- Start test drive
function Vehicles.StartTestDrive(model, spawnPoint)
    local playerPed = PlayerPedId()
    
    -- Validate model
    if not Utils.IsVehicleValid(model) then
        Utils.Notify("Ongeldig voertuigmodel!", "error")
        return
    end
    
    -- Save player position before test drive
    lastPlayerPosition = GetEntityCoords(playerPed)
    
    -- First teleport the player to the spawn location to avoid OneSync range issues
    DoScreenFadeOut(500)
    Wait(600)
    
    -- Teleport player to test drive location temporarily (invisible to player due to fade out)
    SetEntityCoords(playerPed, spawnPoint.x, spawnPoint.y, spawnPoint.z)
    SetEntityHeading(playerPed, spawnPoint.w)
    Wait(100) -- Give the game a moment to process the teleport
    
    -- Request model asynchronously
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    
    -- Wacht tot model geladen is (max 5 seconden)
    local timeout = GetGameTimer() + 5000
    local modelLoaded = false
    
    while GetGameTimer() < timeout do
        if HasModelLoaded(modelHash) then
            modelLoaded = true
            break
        end
        Wait(50)
    end
    
    if not modelLoaded then
        Utils.Notify("Voertuig model kon niet geladen worden!", "error")
        DoScreenFadeIn(500)
        return
    end
    
    -- Now spawn the vehicle directly for better performance
    local vehicle = CreateVehicle(modelHash, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, false)
    
    if DoesEntityExist(vehicle) then
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleModKit(vehicle, 0)
        SetVehicleNumberPlateText(vehicle, "PROEF"..math.random(100, 999))
        
        -- Ensure the vehicle is properly set up
        if Config.UseCustomVehicleProperties and Config.CustomVehicleProperties[model] then
            Vehicles.ApplyVehicleProperties(vehicle, Config.CustomVehicleProperties[model])
        end
        
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        TestDriveVehicle = vehicle
        TestDriveActive = true
        currentTestModel = model
        
        DoScreenFadeIn(500)
        
        Utils.Notify('Proefrit gestart! Je hebt ' .. Config.TestDriveTime .. ' seconden.', 'success')
        Vehicles.StartTestDriveTimer()
        
        -- Trigger server event for tracking
        TriggerServerEvent('donation_testdrive:startTestDrive', model)
        
        -- Monitor player exiting vehicle
        Vehicles.MonitorVehicleExit()
    else
        Utils.Notify("Fout bij het spawnen van het voertuig!", "error")
        DoScreenFadeIn(500)
    end
    
    -- Geef het model vrij
    SetModelAsNoLongerNeeded(modelHash)
end

-- Start test drive timer - Geoptimaliseerde versie
function Vehicles.StartTestDriveTimer()
    if TimerActive then return end
    
    TimerActive = true
    local endTime = GetGameTimer() + (Config.TestDriveTime * 1000)
    timeRemaining = Config.TestDriveTime
    
    Citizen.CreateThread(function()
        local notifyPoints = {30, 10} -- Alleen op deze momenten notificaties sturen
        
        while TestDriveActive and GetGameTimer() < endTime do
            local remaining = math.ceil((endTime - GetGameTimer()) / 1000)
            timeRemaining = remaining
            
            -- Alleen op specifieke momenten notificeren om spammen te voorkomen
            for i, seconds in ipairs(notifyPoints) do
                if remaining == seconds then
                    Utils.Notify('Proefrit tijd resterend: ' .. seconds .. ' seconden!', 'info')
                    table.remove(notifyPoints, i)
                    break
                end
            end
            
            Citizen.Wait(1000) -- Check elke seconde
        end
        
        if TestDriveActive then
            Vehicles.EndTestDrive()
        end
        
        TimerActive = false
    end)
end

-- End test drive
function Vehicles.EndTestDrive()
    if not TestDriveActive then return end
    
    DoScreenFadeOut(500)
    Wait(600)
    
    if TestDriveVehicle and DoesEntityExist(TestDriveVehicle) then
        DeleteVehicle(TestDriveVehicle)
    end
    
    TestDriveActive = false
    TestDriveVehicle = nil
    currentTestModel = nil
    timeRemaining = 0
    TimerActive = false
    
    -- Return player to their original position or a set return point
    if lastPlayerPosition then
        SetEntityCoords(PlayerPedId(), lastPlayerPosition.x, lastPlayerPosition.y, lastPlayerPosition.z)
        lastPlayerPosition = nil
    else
        SetEntityCoords(PlayerPedId(), Config.ReturnPoint.x, Config.ReturnPoint.y, Config.ReturnPoint.z)
    end
    
    Wait(100)
    DoScreenFadeIn(500)
    
    Utils.Notify('Proefrit is beëindigd.', 'info')
    
    -- Set cooldown if enabled
    if Config.EnableCooldown then
        player_cooldowns[GetPlayerServerId(PlayerId())] = GetGameTimer() + (Config.CooldownTime * 1000)
    end
    
    -- Trigger server event for tracking
    TriggerServerEvent('donation_testdrive:endTestDrive')
end

-- Monitor if player exits the test vehicle - Geoptimaliseerde versie
function Vehicles.MonitorVehicleExit()
    Citizen.CreateThread(function()
        local checkInterval = 1000 -- Minder frequente controles voor betere performance
        local vehicleDestroyedFlag = false
        local playerExitedFlag = false
        
        while TestDriveActive and TestDriveVehicle do
            local playerPed = PlayerPedId()
            
            -- Check of het voertuig nog bestaat om onnodige controles te voorkomen
            if not DoesEntityExist(TestDriveVehicle) then
                break
            end
            
            -- Check if player is still in vehicle
            if not IsPedInVehicle(playerPed, TestDriveVehicle, false) and not playerExitedFlag then
                playerExitedFlag = true
                Utils.Notify("Je bent uit het voertuig gestapt. De proefrit wordt beëindigd.", "error")
                
                -- Korte vertraging voor feedback aan speler
                Citizen.SetTimeout(2000, function()
                    if TestDriveActive then
                        Vehicles.EndTestDrive()
                    end
                end)
                break
            end
            
            -- Check if vehicle is destroyed
            if not vehicleDestroyedFlag and IsEntityDead(TestDriveVehicle) then
                vehicleDestroyedFlag = true
                Utils.Notify("Het voertuig is beschadigd. De proefrit wordt beëindigd.", "error")
                
                -- Korte vertraging voor feedback aan speler
                Citizen.SetTimeout(2000, function()
                    if TestDriveActive then
                        Vehicles.EndTestDrive()
                    end
                end)
                break
            end
            
            Wait(checkInterval)
        end
    end)
end

-- Apply custom properties to a vehicle
function Vehicles.ApplyVehicleProperties(vehicle, props)
    if not props or not DoesEntityExist(vehicle) then return end
    
    -- Basic properties
    SetVehicleModKit(vehicle, 0)
    
    -- Colors
    if props.colors then
        SetVehicleColours(vehicle, props.colors.primary or 0, props.colors.secondary or 0)
    end
    
    -- Extras
    if props.extras then
        for extraId, enabled in pairs(props.extras) do
            SetVehicleExtra(vehicle, tonumber(extraId), not enabled)
        end
    end
    
    -- Mods
    if props.mods then
        for modType, modIndex in pairs(props.mods) do
            SetVehicleMod(vehicle, tonumber(modType), tonumber(modIndex), false)
        end
    end
    
    -- Livery
    if props.livery then
        SetVehicleLivery(vehicle, props.livery)
    end
end

-- For server event handling
RegisterNetEvent('donation_testdrive:respawnTestVehicle')
AddEventHandler('donation_testdrive:respawnTestVehicle', function()
    if TestDriveActive then
        Utils.Notify("De beheerder heeft alle voertuigen respawned. Je proefrit wordt beëindigd.", "error")
        Vehicles.EndTestDrive()
    end
end)

-- Return module
return Vehicles 