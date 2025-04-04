-- Utils module for helper functions
local Utils = {}

-- Controleer of Ox Lib beschikbaar is
local hasOxLib = false
function Utils.CheckOxLib()
    if GetResourceState('ox_lib') == 'started' then
        -- Probeer toegang te krijgen tot lib om te controleren of het daadwerkelijk geladen is
        local success = pcall(function() return lib ~= nil end)
        hasOxLib = success and lib ~= nil
    else
        hasOxLib = false
    end
    return hasOxLib
end

-- Notificatie functie
function Utils.Notify(message, type)
    if Utils.CheckOxLib() then
        if type == 'error' then
            lib.notify({
                title = 'Donatie Voertuigen',
                description = message,
                type = 'error'
            })
        elseif type == 'success' then
            lib.notify({
                title = 'Donatie Voertuigen',
                description = message,
                type = 'success'
            })
        else
            lib.notify({
                title = 'Donatie Voertuigen',
                description = message,
                type = 'inform'
            })
        end
    elseif Config.NotificationType == 'esx' then
        ESX.ShowNotification(message)
    elseif Config.NotificationType == 'mythic' then
        exports['mythic_notify']:DoHudText(type, message)
    else
        -- Standaard terugval
        ESX.ShowNotification(message)
    end
end

-- Formatteer getal met komma's (voor prijsweergave)
function Utils.FormatNumber(number)
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1.")
    return minus .. int:reverse():gsub("^[.]", "") .. fraction
end

-- Check of een speler dichtbij een punt is
function Utils.IsPlayerNearPoint(coords, distance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    return #(playerCoords - coords) < distance
end

-- Functie om een timer te maken
function Utils.CreateTimer(duration, callback, onComplete)
    Citizen.CreateThread(function()
        local timeLeft = duration
        
        while timeLeft > 0 do
            if callback then
                callback(timeLeft)
            end
            
            Wait(1000)
            timeLeft = timeLeft - 1
        end
        
        if onComplete then
            onComplete()
        end
    end)
end

-- Anti-exploit check
function Utils.IsVehicleValid(model)
    for _, vehicle in ipairs(Config.DonationVehicles) do
        if vehicle.model == model then
            return true
        end
    end
    return false
end

-- Return module
return Utils 