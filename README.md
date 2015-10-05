# KekMount
KekMount is a small addon that enabled a one-click summoning of an appropriate mount.

## What KekMount does
* Summons ground mount if in no-fly zone or if the player haven't got the prerequisites for flying.
* Summons flying mount in flyable areas if the player have prerequisites (achivement, flying skill)
* Summons Ahn'quiraj mount if player is in appropriate zone
* Summons Chauffeured Mekgineer's Chopper/Mechano-Hog if player haven't got riding skill and they are available
* Summons water mount (Riding Turtle etc) if underwater (can be toggled)
* Summons Seahorse of Poseidus if underwater in Vashj'ir zone (water mount if not available)
* Prefers mounts with water walking, like _Crimson Water Strider_ (can be toggled)
* The player can set (and unset) _one_ favorite ground and flying mount, this will always be picked if possible.

## What it _doesn't_ do
* It does not summon _Travel Form_ or _Ghost Wolf_. This is due to _CastSpell_ and _CastSpellByName_ being protected functions and me being lazy.
* While it support most mounts it does not support very rare "mounts" like _Dragonwrath, Tarecgosa's Rest_.
* No UI (and it will most likely never get one, if you want UI there are several other bloated addons to choose form)

## Why the stupid name?
Lack of imagination/All good ones are already taken
