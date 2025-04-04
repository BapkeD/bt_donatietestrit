-- UI Module for handling menus and displays
local UI = {}

-- Local variables for modules
local Utils = nil
local Vehicles = nil

-- Vehicle info cache om herhaalde berekeningen te vermijden
local vehicleInfoCache = {}

-- Add initialization function that takes both utils and vehicles modules
function UI.Init(utilsModule, vehiclesModule)
    Utils = utilsModule
    Vehicles = vehiclesModule
    return UI
end

-- Functie om voertuiginformatie te formatteren - met caching
function UI.GetVehicleInfo(data)
    if not data or not data.model then return {} end
    
    -- Check de cache eerst
    local cacheKey = data.model
    if vehicleInfoCache[cacheKey] then
        return vehicleInfoCache[cacheKey]
    end
    
    -- Als niet in cache, bereken de informatie
    local vehInfo = {}
    local vehicle = GetHashKey(data.model)
    
    vehInfo.name = data.label
    vehInfo.brand = GetLabelText(GetMakeNameFromVehicleModel(vehicle))
    vehInfo.model = GetLabelText(GetDisplayNameFromVehicleModel(vehicle))
    vehInfo.price = data.price
    vehInfo.formattedPrice = Config.CurrencySymbol .. Utils.FormatNumber(data.price)
    vehInfo.category = data.category
    vehInfo.topspeed = math.ceil((GetVehicleModelEstimatedMaxSpeed(vehicle) * 3.6)) -- Omzetten naar km/u
    vehInfo.acceleration = GetVehicleModelAcceleration(vehicle) * 10
    vehInfo.braking = GetVehicleModelMaxBraking(vehicle) * 10
    vehInfo.traction = GetVehicleModelMaxTraction(vehicle) * 10
    vehInfo.description = data.description
    
    -- Sla op in cache voor toekomstig gebruik
    vehicleInfoCache[cacheKey] = vehInfo
    
    return vehInfo
end

-- Open donatievoertuigen menu met Ox Lib (indien beschikbaar) of ESX
function UI.OpenDonationMenu(vehicleIndex)
    local vehicleData = Config.DonationVehicles[vehicleIndex]
    if not vehicleData then return end
    
    local vehicleInfo = UI.GetVehicleInfo(vehicleData)
    
    if Utils.CheckOxLib() then
        -- Use Ox Lib context menu
        local context = {
            {
                title = vehicleData.label .. ' - ' .. vehicleInfo.formattedPrice,
                description = vehicleInfo.description,
                icon = 'car'
            },
            {
                title = 'Model',
                description = vehicleInfo.name,
                icon = 'info-circle'
            },
            {
                title = 'Merk',
                description = vehicleInfo.brand,
                icon = 'building'
            },
            {
                title = 'Categorie',
                description = vehicleInfo.category,
                icon = 'tag'
            },
            {
                title = 'Topsnelheid',
                description = vehicleInfo.topspeed .. ' km/u',
                icon = 'tachometer-alt'
            },
            {
                title = 'Acceleratie',
                description = string.format("%.1f", vehicleInfo.acceleration) .. '/10',
                icon = 'bolt'
            },
            {
                title = 'Remmen',
                description = string.format("%.1f", vehicleInfo.braking) .. '/10',
                icon = 'brake-warning'
            },
            {
                title = 'Wegligging',
                description = string.format("%.1f", vehicleInfo.traction) .. '/10',
                icon = 'road'
            },
            {
                title = 'Proefrit',
                description = 'Start een proefrit met dit voertuig',
                icon = 'play',
                onSelect = function()
                    if TestDriveActive then
                        Utils.Notify('Je bent al bezig met een proefrit!', 'error')
                        return
                    end
                    
                    if Config.EnableCooldown and player_cooldowns[GetPlayerServerId(PlayerId())] then
                        local remaining = math.ceil((player_cooldowns[GetPlayerServerId(PlayerId())] - GetGameTimer()) / 1000)
                        Utils.Notify('Je moet nog ' .. remaining .. ' seconden wachten voordat je een nieuwe proefrit kunt starten!', 'error')
                        return
                    end
                    
                    Vehicles.StartTestDrive(vehicleData.model, DonationVehicles[vehicleIndex].location.SpawnPoint)
                end
            }
        }
        
        lib.registerContext({
            id = 'donation_vehicle_info',
            title = 'Voertuig Informatie',
            options = context
        })
        
        lib.showContext('donation_vehicle_info')
    else
        -- Fallback to ESX menu
        local infoElements = {
            {label = '<span style="color: green; font-weight: bold;">Prijs: ' .. vehicleInfo.formattedPrice .. '</span>', value = 'price_header'},
            {label = 'Model', value = vehicleInfo.name},
            {label = 'Merk', value = vehicleInfo.brand},
            {label = 'Categorie', value = vehicleInfo.category},
            {label = 'Topsnelheid', value = vehicleInfo.topspeed .. ' km/u'},
            {label = 'Acceleratie', value = string.format("%.1f", vehicleInfo.acceleration) .. '/10'},
            {label = 'Remmen', value = string.format("%.1f", vehicleInfo.braking) .. '/10'},
            {label = 'Wegligging', value = string.format("%.1f", vehicleInfo.traction) .. '/10'},
            {label = 'Beschrijving', value = vehicleInfo.description},
            {label = 'Proefrit', value = 'test_drive'}
        }
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_info', {
            title    = vehicleData.label .. ' - ' .. vehicleInfo.formattedPrice,
            align    = 'top-left',
            elements = infoElements
        }, function(data, menu)
            if data.current.value == 'test_drive' then
                if TestDriveActive then
                    Utils.Notify('Je bent al bezig met een proefrit!', 'error')
                    return
                end
                
                if Config.EnableCooldown and player_cooldowns[GetPlayerServerId(PlayerId())] then
                    local remaining = math.ceil((player_cooldowns[GetPlayerServerId(PlayerId())] - GetGameTimer()) / 1000)
                    Utils.Notify('Je moet nog ' .. remaining .. ' seconden wachten voordat je een nieuwe proefrit kunt starten!', 'error')
                    return
                end
                
                menu.close()
                Vehicles.StartTestDrive(vehicleData.model, DonationVehicles[vehicleIndex].location.SpawnPoint)
            end
        end, function(data, menu)
            menu.close()
        end)
    end
end

-- Dummy functies die niets doen - deze zijn volledig verwijderd van de UI-functionaliteit
-- Behouden voor backward compatibility
function UI.DisplayTestDriveTimer(timeLeft)
    -- Timer UI verwijderd voor performance verbetering
end

function UI.HideTestDriveTimer()
    -- Timer UI verwijderd voor performance verbetering
end

-- Vehicle cache leegmaken wanneer nodig
function UI.ClearCache()
    vehicleInfoCache = {}
end

-- Return module
return UI 