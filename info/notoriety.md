# InfilSense Notoriety Commands

This page documents the commands currently exposed by the Notoriety script. The script must be executed inside a Notoriety mission and requires an executor that supports HTTP requests.

## Visual

- **NPC ESP**: Highlights police and citizens. (`npcesp`, `esp`, `npc`)
- **Team ESP**: Highlights other criminals in the current team. (`teamesp`; aliases: `teammates`, `criminals`, `friends`, `team`)
- **Camera ESP**: Highlights intact security cameras. (`cameras`, `camera`, `camesp`)
- **Loot ESP**: Highlights money, gold, loot bags, safe spots, military crates, and other supported lootables. (`lootesp`, `lootables`, `lootable`, `loots`, `loot`)

## Local

- **Infinite Stamina**: Prevents stamina from draining while sprinting. (`infstamina`, `stamina`)
- **Loop Walkspeed**: Continuously applies the entered walkspeed. Default: `50`. (`loopwalkspeed`, `loopws`, `ws`)
- **Infinite Jump**: Allows jumping while airborne. (`infinitejumps`, `infinitejump`, `infjumps`, `infjump`, `float`)

## Weapons

- **Infinite Ammo**: Continuously restores weapon ammunition and removes spawned ammo drops. (`infiniteammo`, `weaponsammo`, `weaponammo`, `infammo`, `ammo`)
- **Weapon mods**: Modifies active weapons for high damage, automatic fire, high accuracy, large magazines, and very short reload/fire delays. (`weaponsmods`, `weaponsmod`, `weaponmods`, `weaponmod`, `wmods`, `wmod`)

## NPC

- **Auto Kill Police/Guards**: Continuously damages active police and guards using the equipped weapon. (`autokillpolice`, `killpolice`, `policekill`, `killguards`, `guardkill`)

## Other

- **Destroy Cameras**: Destroys camera models as they appear. (`destroycams`, `breakcams`)
- **Delete Glass**: Removes supported glass objects locally. (`removeglass`, `remglass`, `byeglass`, `noglass`)

## Settings

- **Quick Command**: Enables command execution by ID or alias and supports command arguments where documented.
- **Don't copy Discord link on start**: Controls whether the Discord invite is copied when the script starts.
- **Don't auto load on each join**: Controls automatic loading in missions.
- **More Command Info Link**: Copies the URL for this documentation page. (`cmdinfo`; aliases: `commandsinfo`, `commandinfo`, `info`, `help`)
- **Set UI Theme**: Selects and saves a UI theme. (`settheme`, `theme`)
