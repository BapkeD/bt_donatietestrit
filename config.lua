Config = {}

-- Algemene instellingen
Config.UseTarget = false -- Zet op true als je qb-target of ox_target gebruikt
Config.TestDriveTime = 60 -- Tijd in seconden voor de testrit
Config.CurrencySymbol = '€' 

-- Cooldown instellingen
Config.EnableCooldown = false -- Zet op true om een cooldown tussen testritten in te schakelen
Config.CooldownTime = 60 -- Tijd in seconden tussen testritten (standaard: 5 minuten)

-- UI instellingen
-- Timer UI is verwijderd in v1.2.0 voor drastische performance verbetering
Config.NotificationType = 'esx' -- 'esx', 'mythic', 'ox_lib', 'custom'

-- Blip instellingen
Config.Blip = {
    Sprite = 326,
    Color = 3,
    Display = 4,
    Scale = 0.7,
    Name = "Donatie Voertuigen"
}

-- Meerdere locaties instellen
Config.Locations = {
    {
        Coords = vector3(-213.3504, -1953.4397, 27.2067),
        Heading = 288.4078,
        SpawnPoint = vector4(-858.5919, -3220.7864, 13.9446, 177.7453)
    },
    {
        Coords = vector3(-212.3855, -1956.2253, 27.2067),
        Heading = 289.1292,
        SpawnPoint = vector4(-858.5919, -3220.7864, 13.9446, 177.7453)
    },
    {
        Coords = vector3(-211.4155, -1959.0284, 27.2067),
        Heading = 289.1293,
        SpawnPoint = vector4(-858.5919, -3220.7864, 13.9446, 177.7453)
    }
}

-- Retourneer punt bij het verlaten van het voertuig
Config.ReturnPoint = vector3(-214.4155, -1950.0284, 27.2067)

-- Performance instellingen
Config.OptimizationLevel = 2 -- 1 = basis, 2 = gemiddeld, 3 = maximaal
Config.CacheRefreshInterval = 30 -- Seconden tussen cache verversingen

-- Marker instellingen (alleen gebruikt als UseTarget false is)
Config.Marker = {
    Type = 36,
    Size = vector3(1.0, 1.0, 1.0),
    Color = {r = 255, g = 0, b = 0, a = 100},
    DrawDistance = 10.0
}

-- Voertuig aanpassingen (optioneel)
Config.UseCustomVehicleProperties = false -- Zet op true om custom voertuigeigenschappen te gebruiken
Config.CustomVehicleProperties = {
    -- Voorbeeld:
    -- ['adder'] = {
    --     colors = {primary = 12, secondary = 0},
    --     extras = {1 = true, 2 = false},
    --     mods = {[0] = 1, [1] = 2},  -- Voertuigmods: [modType] = modIndex
    --     livery = 0
    -- }
}

-- Voertuigen beschikbaar voor testrit
Config.DonationVehicles = {
    -- Voorbeeld hoe je een voertuig toevoegt:
    -- {
    --     model = 'jester',          -- Spawn naam van het voertuig
    --     label = 'Dinka Jester',    -- Naam die getoond wordt in het menu
    --     price = 15,                -- Prijs in euro's 
    --     category = 'Supercars',    -- Categorie voor het menu
    --     description = 'Exclusief donatie voertuig - Supercar klasse' -- Beschrijving die getoond wordt
    -- },
    {
        model = 'adder',
        label = 'Adder',
        price = 10,
        category = 'Supercars',
        description = 'Exclusief donatie voertuig - Supercar klasse'
    },
    {
        model = 'zentorno',
        label = 'Zentorno',
        price = 10,
        category = 'Supercars',
        description = 'Exclusief donatie voertuig - Supercar klasse'
    },
    {
        model = 't20',
        label = 'T20',
        price = 5,
        category = 'Supercars',
        description = 'Exclusief donatie voertuig - Supercar klasse'
    },
    {
        model = 'bati',
        label = 'Bati 801',
        price = 10,
        category = 'Motoren',
        description = 'Exclusief donatie voertuig - Motor klasse'
    }
} 