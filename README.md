#KekMount

KekMount ("KMount") is a small addon that enables a one-click summoning of an appropriate mount. That is to say, if your character has a riding skill but not a flying skill, it will pick a ground mount even if you have a flying mounts selected as favorites.

 

This mod has only been tested with English language clients and it might not work with other languages.

 
##Why I made this mod

The reason I made this mod is primarily because while the built-in mount manager is good, it doesn't support simple things like not selecting a freaking dragon when I'm using a character that can't even fly. With KMount, that's now possible and what's more, I've added additional functionality that might or might not be of use, like selecting mounts that increase underwater movement speed when your character is underwater. Even better it's all toggleable, so if you don't like a certain feature you don't have to use it all.

##How to use

Using KMount is really easy, all you have to do is create a macro containing:

/kmount

Yes, it really is that simple. No needless UIs or pages of options, it just works straight out of the box.

##What KekMount does

* Integrates seamlessly with Blizzard's built-in mount manager so you'll always be riding your favorite [appropriate] mount(s)
* Summons ground mount if in no-fly zone or if the player haven't got the prerequisites for flying
* Recognizes achievements as riding skills where applicable
* Summons flying mount in flyable areas, if the player have prerequisites for it
* Summons Ahn'quiraj mount if player is in appropriate zone and it's available
* Summons Chauffeured Mekgineer's Chopper/Mechano-Hog if player haven't got riding skill and they are available
* Summons water mount (i.e. mounts that increase underwater speed) if underwater
* Summons Seahorse of Poseidus/Seashorse if underwater in Vashj'ir zone
* Toggle preference for mounts with water walking
* Will select an appropriate mount at random if no favorite mounts have been selected

##What it doesn't do

* It does not summon Travel Form or Ghost Wolf. This is due to CastSpell and CastSpellByName being protected functions and other solutions being messy
* While it support most mounts it does not support very rare "mounts" like Dragonwrath, Tarecgosa's Rest (it's a spell, see above)
* No UI (and it will most likely never get one, if you want UI there are several other bloated addons to choose form)

#Commands

* Help - Shows a list of all available commands
* Info - Displays settings for current character.
* Togglew - Toggles water mounts (except Vashj'ir specific mounts).
* Togglepw - Toggles preference for ground mounts that can walk on water.
* Togglefd - Toggles whether or not to dismount while in flight.
* Togglebf - Toggles use of favorite mount(s) from the built-in mount manager. This overrides favorites set in KMount. This is overridden by 'togglepw' for ground mounts.
* G - Force summons a ground mount (you can fly, but want a ground mount).
* F - Force summons a flying mount (you can't fly, but want a flying mount).
* Reset - Reset settings for current character to default.

##Old system (still available)

* Get <flying|ground> - Shows a list of available, useable mounts and an associated index number. This number is what is used to set favorite mounts. A '*' next to the name means that you have selected it as a favorite in the mount manager.
* Getbyname <query> - Search through all mounts (even unavailable) and returns an index number if a match is found. Example:

    /kmount getbyname swift spec

    Would output: "KMount: Index of 'Swift Spectral Gryphon' is '422'."

    This is because Swift Spectral Gryphon is the first mount where a partial match is made.

* Setf - Sets preferred flying mount. Example:

    /kmount setf 94

    This would set preferred flying mount to 'Bronze Drake' as it has the index of 94 in the mount manager. If you don't know the index you would use /kmount get flying to get a list of all available (to your character) flying mounts and then look up the index or /kmount getbyname bronze drake to get the index of a specific mount.
* Setg - Sets preferred ground mount.
* Usetf - Unset preferred flying mount.
* Usetg - Unset preferred ground mount.

##Dev stuff
* Debug - Verbose info for debugging purposes.
* Update - Force the mount list to update.
* Mountcount - Count usable mounts

##Why the stupid name?

Lack of imagination/All good names were already taken