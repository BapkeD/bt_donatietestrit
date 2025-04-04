# Donatie Voertuigen Testrit

Een FiveM ESX resource die spelers de mogelijkheid geeft om donatiewagens te testen met een timer.

## Licentie en Gebruik

**BELANGRIJK:**
- Dit script is ontwikkeld door BTscripts en wordt gratis ter beschikking gesteld
- Doorverkoop van dit script is NIET toegestaan
- Wijzigingen aanbrengen voor eigen gebruik is toegestaan
- Redistibutie alleen met toestemming van de oorspronkelijke maker

## Kenmerken

- Configureerbare voertuigeigenschappen
- Admin commando's voor beheer van testritten
- Target systeem ondersteuning (ox_target/qb-target)
- Anti-exploit beveiliging
- Intelligente geheugenbeheer en caching
- Geoptimaliseerde performance
- Uitgebreide documentatie

## Installatie

1. Download de resource
2. Plaats het in de resources directory van je server
3. Voeg `ensure bt_donatietestrit` toe aan je server.cfg
4. Configureer de voertuigen en instellingen in `config.lua`
5. Herstart je server

## Configuratie

Je kunt de volgende instellingen aanpassen in het `config.lua` bestand:

- Testrit tijdsduur
- Voertuiglijst en informatie
- Performance optimalisatie niveau
- Dealer locatie(s)
- Target integratie configuratie
- Aangepaste voertuigeigenschappen

## Benodigdheden

- ESX Framework (Legacy)
- ox_lib (optioneel maar aanbevolen)

## Optionele afhankelijkheden

- ox_target of qb-target (voor target integratie)

## Changelog

### v1.2.1
- Verwijderd: Cooldown systeem tussen testritten
- Verbeterd: 3D tekst is nu groter en beter zichtbaar
- Verbeterd: Prestaties door geoptimaliseerde voertuig spawning
- Verbeterd: Betere performance door geavanceerde caching
- Verbeterd: Squared distance calculation voor snellere afstandsberekening
- Verbeterd: Dynamische update intervals voor betere CPU-belasting

### v1.2.0
- Verwijderd: UI timer voor drastische prestatieverbetering
- Toegevoegd: Intelligente caching voor voertuiggegevens
- Toegevoegd: Performance monitoring en optimalisatie
- Toegevoegd: Adaptieve resource management
- Geoptimaliseerd: Voertuig spawning en model laden
- Geoptimaliseerd: 3D tekst rendering
- Verbeterd: Geheugengebruik en resource cleanup

### v1.1.3
- Opgelost: UI blijft nu verborgen wanneer speler overlijdt tijdens testrit
- Toegevoegd: Event handler voor speler dood tijdens testrit
- Verbeterd: Algemene betrouwbaarheid van UI weergave

### v1.1.2
- Opgelost: UI blijft nu verborgen wanneer de resource herstart of stopt
- Verbeterd: Betere afhandeling van resource stoppen/herstarten
- Toegevoegd: Event handler voor resource stop

### v1.1.1
- Opgelost: 'os is nil' error in client.lua bij cooldown berekening
- Opgelost: UI blijft zichtbaar na het verlaten van het voertuig
- Verbeterd: Modulaire structuur en afhankelijkheden
- Verbeterd: Cooldown synchronisatie tussen server en client

### v1.1.0
- Modulaire code structuur voor betere organisatie
- Toegevoegd: Zichtbare timer tijdens testritten
- Toegevoegd: Cooldown systeem
- Toegevoegd: Aangepaste voertuigeigenschappen
- Verbeterd: Optimalisaties voor performance
- Verbeterd: Anti-exploit bescherming
- Verbeterd: Target systeem integratie

### v1.0.0
- Initiële release

## Credits

Gemaakt door BTscripts

