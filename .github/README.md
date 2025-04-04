# BT Donatie Testrit

Een FiveM ESX resource die spelers de mogelijkheid geeft om donatiewagens te testen met een timer.

## Gecloneerd van
Deze repository is een kopie van [BTscripts](https://github.com/BTscripts/bt_donatietestrit)

## Screenshots
![Voertuig Menu](https://i.imgur.com/example1.png)
![Testrit Timer](https://i.imgur.com/example2.png)

## Kenmerken

- Verbeterde UI met realtime timer weergave tijdens testritten
- Cooldown systeem tussen testritten
- Configureerbare voertuigeigenschappen
- Admin commando's voor beheer van testritten
- Target systeem ondersteuning (ox_target/qb-target)
- Anti-exploit beveiliging
- Geoptimaliseerde performance
- Uitgebreide documentatie

## Installatie

1. Download de resource
2. Plaats het in de resources directory van je server
3. Voeg `ensure bt_donatietestrit` toe aan je server.cfg
4. Configureer de voertuigen en instellingen in `config.lua`
5. Herstart je server

## Commando's

**Speler Commando's:**
- `/endtestdrive` - Beëindig je huidige testrit

**Admin Commando's:**
- `/testdrives` - Bekijk alle actieve testritten
- `/respawntestcars` - Handmatig alle testritvoertuigen respawnen
- `/testdrivecooldowns` - Bekijk alle actieve cooldowns
- `/resetcooldown [ID]` - Reset de cooldown van een speler

## Dependencies

- ESX Framework (Legacy)
- ox_lib (optioneel maar aanbevolen)
- ox_target of qb-target (optioneel voor target integratie)

## Licentie

Dit script is onderworpen aan de voorwaarden in het bestand [LICENSE.md](LICENSE.md). 