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
    
    -- Spawn de voertuigen op elke locatie
    for i, location in ipairs(Config.Locations) do
        -- Spawn alleen een voertuig als we een model hebben voor deze locatie-index
        if Config.DonationVehicles[i] then
            local modelHash = GetHashKey(Config.DonationVehicles[i].model)
            
            -- Vraag het model aan
            RequestModel(modelHash)
            local requestTimeout = GetGameTimer() + 5000  -- 5 seconden timeout
            
            while not HasModelLoaded(modelHash) and GetGameTimer() < requestTimeout do
                Wait(10)
            end
            
            if HasModelLoaded(modelHash) then
                -- Spawn het voertuig
                local vehicle = CreateVehicle(modelHash, location.Coords.x, location.Coords.y, location.Coords.z, location.Heading, false, false)
                
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
            else
                print("^1ERROR: Model kon niet geladen worden: "..Config.DonationVehicles[i].model)
            end
            
            -- Geef het model vrij
            SetModelAsNoLongerNeeded(modelHash)
        end
    end
end

-- Get closest donation vehicle
function Vehicles.GetClosestDonationVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestDistance = 3.0 -- Only interact within 3 meters
    local closestVehicle = nil
    local closestIndex = nil
    
    for i, vehData in pairs(DonationVehicles) do
        if DoesEntityExist(vehData.entity) then
            local vehCoords = GetEntityCoords(vehData.entity)
            local distance = #(playerCoords - vehCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestVehicle = vehData.entity
                closestIndex = i
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
    
    -- Now spawn the vehicle at the location (player is already there)
    ESX.Game.SpawnVehicle(model, vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z), spawnPoint.w, function(vehicle)
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
        Wait(100)
        
        Utils.Notify('Proefrit gestart! Je hebt ' .. Config.TestDriveTime .. ' seconden.', 'success')
        Vehicles.StartTestDriveTimer()
        
        -- Display UI timer if enabled
        if Config.ShowTimerUI and UI then
            UI.DisplayTestDriveTimer(Config.TestDriveTime)
        end
        
        -- Trigger server event for tracking
        TriggerServerEvent('donation_testdrive:startTestDrive', model)
        
        -- Monitor player exiting vehicle
        Vehicles.MonitorVehicleExit()
    end)
end

-- Start test drive timer
function Vehicles.StartTestDriveTimer()
    if TimerActive then return end
    
    TimerActive = true
    timeRemaining = Config.TestDriveTime
    
    Utils.CreateTimer(Config.TestDriveTime, 
        function(timeLeft)
            timeRemaining = timeLeft
            
            if Config.ShowTimerUI and UI then
                UI.DisplayTestDriveTimer(timeLeft)
            end
            
            if timeLeft == 30 or timeLeft == 10 then
                Utils.Notify('Proefrit tijd resterend: ' .. timeLeft .. ' seconden!', 'info')
            end
        end,
        function()
            Vehicles.EndTestDrive()
        end
    )
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
    
    -- Hide timer UI
    if UI then
        UI.HideTestDriveTimer()
    end
    
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

-- Monitor if player exits the test vehicle
function Vehicles.MonitorVehicleExit()
    Citizen.CreateThread(function()
        while TestDriveActive and TestDriveVehicle do
            Wait(500)
            local playerPed = PlayerPedId()
            
            -- Check if player is still in vehicle
            if not IsPedInVehicle(playerPed, TestDriveVehicle, false) then
                Utils.Notify("Je bent uit het voertuig gestapt. De proefrit wordt beëindigd.", "error")
                
                -- Hide UI immediately when exiting vehicle
                if UI then
                    UI.HideTestDriveTimer()
                end
                
                Wait(2000)
                Vehicles.EndTestDrive()
                break
            end
            
            -- Check if vehicle is destroyed
            if IsEntityDead(TestDriveVehicle) then
                Utils.Notify("Het voertuig is beschadigd. De proefrit wordt beëindigd.", "error")
                
                -- Hide UI immediately when vehicle is destroyed
                if UI then
                    UI.HideTestDriveTimer()
                end
                
                Wait(2000)
                Vehicles.EndTestDrive()
                break
            end
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