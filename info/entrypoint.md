# InfilSense Entrypoint Commands

This page documents the commands currently exposed by the Entrypoint script. Commands are available from the UI and, when enabled by the control, from Quick Command and bindable actions.

## ESP

- **Stuff ESP**: Shows mission-specific objectives and important objects such as safes, computers, power boxes, keypads, and doors. (`stuffesp`)
- **Clean ESP**: Highlights NPCs and shows their type and distance. (`cleanesp`, `esp`)
- **Player ESP**: Highlights other players. (`playeresp`, `plresp`, `pesp`)
- **Camera ESP**: Highlights security cameras. (`cameraesp`, `camesp`, `cams`, `cam`)

## Telekinesis

- **Telekinesis**: Hold the left mouse button to move an unanchored object or NPC with the mouse. Use the mouse wheel to change its distance. (`telekinesis`, `tele`, `tk`)
- **Telekinesis Fling**: Launches the currently held telekinesis target. (`telekinesisfling`, `telefling`, `tkfling`, `tkf`)

## Loadouts

- **Infinite Ammo**: Continuously restores ammunition. Thumpers are excluded. (`infammo`, `ia`)
- **Minigun**: Fires at the mouse position at the requested rate; the default is 30. The Quick Command argument is the firerate. (`minigun`)
- **Rainbow Guns**: Applies a client-side cycling rainbow effect to weapons. (`rainbowguns`, `rgbguns`, `rguns`)
- **Clear Current Loadout**: Clears the current loadout slot. (`clearloadout`, `cloadout`)
- **Add Gear To Loadout**: Adds the selected gear to the current loadout. Some non-standard items can break the loadout page; clear the loadout if that happens. (`addgear`)
- **Set Primary**: Selects a primary weapon from the available weapon list. (`setweapon`)
- **Weapon Modifications**: Removes recoil and spread, increases magazine and reserve capacity, enables automatic fire, increases damage, and reduces reload/fire delay. Best used with Infinite Ammo. (`weaponmods`, `wepmods`, `wpmods`, `wmods`)

## Fun

- **Kill Rose/Rivera**: Eliminates Rose in The Blacksite or Rivera in The Cache. (`killrivera`, `killrose`, `killr`)
- **NPC Interact**: Enables NPC interaction state so NPCs can be interacted with. (`npcinteract`)
- **NPC Follow**: Makes nearby NPCs pathfind toward you, up to 20 NPCs at a time. (`npcfollow`)
- **Loop Walkspeed**: Continuously applies the entered walkspeed. Default: `50`. (`loopwalkspeed`, `loopws`, `ws`)
- **Infinite Jump**: Allows jumping while airborne. (`infinitejumps`, `infinitejump`, `infjumps`, `infjump`, `float`)

## NPC / Bring

- **Bring Armed**: Brings an armed NPC to the player. (`bringarmed`)
- **Bring Unarmed**: Brings an unarmed NPC to the player. (`bringunarmed`)
- **Bring Type**: Brings NPCs matching one or more selected types. Default: `All`. Quick Command arguments are the type selection and an optional loop boolean. (`bringtype`, `bring`)
- **Bring Bags**: Brings ground bags to the player. (`bringbags`, `bb`)
- **Loop Bring Bags**: Continuously brings ground bags to the player. (`loopbringbags`, `loopbb`, `lbb`)
- **Hide NPCs**: Moves selected NPC types to a hidden position. Quick Command arguments are the type selection and an optional loop boolean. (`hidenpcs`, `hidenpc`, `hide`)
- **Void NPCs**: Moves selected NPC types into the void. Quick Command arguments are the type selection and an optional loop boolean. (`voidnpcs`, `voidnpc`, `void`)
- **Stop Forced NPCs**: Stops active forced, hidden, or void NPC positions. (`stopforcednpcs`; aliases: `stopforced`, `unfreeze`, `noforce`)
- **Disable Cameras**: Eliminates camera operators when present. (`disablecams`, `killcams`, `byecams`, `nocams`)

### NPC type values

- `guard`: Guards
- `worker`: Workers
- `vip`: VIPs
- `chill`: Rose and other non-hostile special NPCs
- `civilian`: Civilians
- `enemy`: Hostile enemies
- `mixed`: Mixed police/Halcyon NPCs
- `all`: All supported NPC types

## Other

- **No Fog**: Removes fog and the current atmosphere. (`nofog`)
- **No Flashbang**: Disables flashbang visibility and related blur/color effects. (`noflashbang`, `noflash`)
- **Unlock Doors**: Continuously marks doors as open locally. Other players may still see them as locked until opened. (`unlockdoors`)
- **Fast Bagging**: Sets bag and pickup interaction times near zero. Intended for The Withdrawal and The Lakehouse after bags load. (`fastbag`, `fb`)
- **Break Metal Detectors**: Removes metal detector parts and touch transmitters locally. (`breakmetaldetectors`, `breakmd`)
- **Right-Alt Delete**: While holding either Alt key, left-click a non-character part to delete it locally. (`rightaltdelete`, `altdelete`, `altdel`)
- **FT Difficulty**: Selects the difficulty used by Force Teleport: Rookie, Professional, Operative, Elite, or Legend. (`settpmdiff`)
- **Force Teleport**: Selects a mission and teleports with the selected FT Difficulty. (`teleportmission`, `forceteleport`, `tpmission`, `forcetp`)
- **Look Away**: Makes NPCs face away from the player. The source notes that this feature is buggy. (`lookaway`)
- **Set FOV**: Applies the entered field of view. Default: `90`; disabling restores `70`. (`setfov`)
- **Less Class Restrictions**: Adds supported perks and gear permissions to the local player. (`lessclassres`, `lcr`)
- **Show Waypoints**: Displays NPC waypoints. (`showwaypoints`, `showwp`)
- **Godmode All**: Applies the godmode behavior to all supported actors. (`godmodeall`, `godall`)
- **Godmode Only Yourself**: Applies godmode only to the local player. (`godmodeonlyyourself`, `godmodeonlymyself`, `godmodeyourself`, `godmodemyself`, `godmodeonlyme`, `godmodeme`, `godme`)
- **Stop Godmode Functions**: Disconnects active godmode loops. (`ungodall`, `nogod`)

## Autofarm

- **Legacy Scientist Autofarm**: Runs the older automated Scientist mission flow. (`legacysciauto`, `lsciauto`)
- **Scientist Autofarm**: Runs the current automated Scientist mission flow. (`sciauto`)

Both Scientist autofarms are intended for The Scientist mission.

## Settings

- **Quick Command**: Enables command execution by ID or alias and supports command arguments where documented.
- **Don't copy Discord link on start**: Controls whether the Discord invite is copied when the script starts.
- **Don't auto load on each join**: Controls automatic loading in missions.
- **More Command Info Link**: Copies the URL for this documentation page. (`cmdinfo`; aliases: `commandsinfo`, `commandinfo`, `info`, `help`)
- **Set UI Theme**: Selects and saves a UI theme. (`settheme`, `theme`)
