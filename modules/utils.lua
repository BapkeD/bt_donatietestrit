-- Utils module for helper functions
local Utils = {}

-- Cache om herhaaldelijke berekeningen te voorkomen
local oxLibCache = { available = false, lastCheck = 0 }
local distanceCache = {}

-- Controleer of Ox Lib beschikbaar is - met caching voor betere performance
function Utils.CheckOxLib()
    local currentTime = GetGameTimer()
    
    -- Gebruik gecachete waarde als de check recent is (afgelopen 10 seconden)
    if (currentTime - oxLibCache.lastCheck) < 10000 then
        return oxLibCache.available
    end
    
    -- Controleer daadwerkelijk of Ox Lib beschikbaar is
    local available = false
    if GetResourceState('ox_lib') == 'started' then
        -- Probeer toegang te krijgen tot lib om te controleren of het daadwerkelijk geladen is
        local success = pcall(function() return lib ~= nil end)
        available = success and lib ~= nil
    end
    
    -- Update de cache
    oxLibCache.available = available
    oxLibCache.lastCheck = currentTime
    
    return available
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

-- Formatteer getal met komma's (voor prijsweergave) - met memoization
local formatNumberCache = {}
function Utils.FormatNumber(number)
    -- Check cache first
    if formatNumberCache[number] then
        return formatNumberCache[number]
    end
    
    -- Calculate formatted number
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1.")
    local result = minus .. int:reverse():gsub("^[.]", "") .. fraction
    
    -- Store in cache
    formatNumberCache[number] = result
    
    return result
end

-- Check of een speler dichtbij een punt is - geoptimaliseerd met caching
function Utils.IsPlayerNearPoint(coords, distance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Genereer een unieke sleutel voor deze coördinaten en afstand
    local key = string.format("%.1f,%.1f,%.1f,%d", coords.x, coords.y, coords.z, distance)
    
    -- Verwijder oude cache entries (ouder dan 500ms voor betere performance)
    local currentTime = GetGameTimer()
    for k, v in pairs(distanceCache) do
        if (currentTime - v.timestamp) > 500 then
            distanceCache[k] = nil
        end
    end
    
    -- Check de cache
    if distanceCache[key] and (currentTime - distanceCache[key].timestamp) < 500 then
        return distanceCache[key].result
    end
    
    -- Gebruik squared distance voor betere performance (vermijd square root berekening)
    local dx = playerCoords.x - coords.x
    local dy = playerCoords.y - coords.y
    local dz = playerCoords.z - coords.z
    local squaredDist = dx*dx + dy*dy + dz*dz
    local squaredRange = distance * distance
    
    local result = squaredDist < squaredRange
    
    -- Sla het resultaat op in de cache
    distanceCache[key] = {
        result = result,
        timestamp = currentTime
    }
    
    return result
end

-- Geoptimaliseerde timer functie met betere performance
function Utils.CreateTimer(duration, callback, onComplete)
    Citizen.CreateThread(function()
        local endTime = GetGameTimer() + (duration * 1000)
        
        while GetGameTimer() < endTime do
            local timeLeft = math.ceil((endTime - GetGameTimer()) / 1000)
            
            if callback then
                callback(timeLeft)
            end
            
            -- Langere wachttijd als er nog veel tijd over is
            if timeLeft > 10 then
                Wait(500)
            else
                Wait(100) -- Vaker updaten als we dicht bij het einde zijn
            end
        end
        
        if onComplete then
            onComplete()
        end
    end)
end

-- Anti-exploit check met caching
local validVehicleCache = {}
function Utils.IsVehicleValid(model)
    -- Check cache first
    if validVehicleCache[model] ~= nil then
        return validVehicleCache[model]
    end
    
    -- Check if vehicle is valid
    for _, vehicle in ipairs(Config.DonationVehicles) do
        if vehicle.model == model then
            validVehicleCache[model] = true
            return true
        end
    end
    
    validVehicleCache[model] = false
    return false
end

-- Return module
return Utils 