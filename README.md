## Noita Archipelago
A Noita mod to provide support for the Archipelago multiworld platform

This mod takes hidden chests/hearts, pedestals, orbs, and boss drops and converts them into Archipelago checks.

 - Items going into the pool that can be received from a check (from local or remote multiworlds)
    - GOOD:
      - Gold
      - Hearts
      - Random Wands
      - Potions
      - Orbs
      - Immunity Perks
      - Extra Lives
      - Other Helpful Perks
      - Miscellaneous Other Items
    - BAD:
      - All stream integration "Bad" and "Awful" events
      - Bad events can be toggled in the player yaml settings

## Installation

Find Noita in your Steam library, right click it and select Manage -> Browse Local Files.

Here you should see your game files and a folder called "mods". Create a folder called "archipelago" and place all files from within the zip folder directly into the archipelago folder. After starting Noita, select the Mods menu. Here you should see the Archipelago mod listed.

In order to enable the mod you will first need to toggle "Allow unsafe mods". This is required, as some external libraries are used in the mod in order to communicate with the Archipelago server. Enable "Allow unsafe mods" and enable the Archipelago mod.

## Configuration

In the Options menu, select Mod Settings. Under the Archipelago drop down, you will see the options for Hostname, Port, and Slot name, where you can fill in the relevant information.

Once you start a new run in Noita, you should see "Connected to Archipelago server" in the bottom left of the screen, as well as a unique perk. If you do not see this message, ensure that the mod is enabled and installed per the instructions above.

## Design Intent

Noita is a roguelike that does not have required items to beat the game (other than orbs for some endings). It's possible to beat the game without wands if you're feeling up to it. This goes against the general theme of Archipelago, since typically you need to find other players' required items so that they can find your required items, so that you can find theirs, and so on until you've all beaten your games. Despite this, Noita has something that makes it a compelling fit for Archipelago:

It's hard.

Looking at Steam's global achievement stats, it's safe to assume that most people who have played Noita have not acheived any of the endings. The design goal for this mod is to essentially make you stronger and stronger as the multiworld progresses, kind of like how a roguelite does it. As you gain extra max health, more wand options at the start, and most importantly your immunity perks, it becomes easier to actually beat the game.

## Notes and Quirks

Potions and dice do not get delivered in async (won't get delivered if they are sent to you while your game is closed).

This is because it is just plain dangerous to deliver these to you when you've just spawned. Potions sometimes break when they spawn next to you, and the dice sometimes roll when they spawn. Getting spawn killed in Archipelago does not seem like much fun. It is, however, still fun when they spawn while you're actively playing, since you would potentially have time to react.

Potions, dice, spell refreshes, gold, and extra lives do not get redelivered to you on new game.

For the potions and dice, the reason is similar to the previous note's reason: they like to break when they are spawned sometimes, espeically if they're spawned in a crowded room. We may find a nicer way to resend these on new game later on, though.

For spell refreshes, gold, and extra lives, they are intended to be "current run" buffs, rather than permanent buffs like other items act as. As noted above, you'll be getting stronger over the course of the run. You'll have less of a need for spell refreshes to be dropped on you since they'll spawn in holy mountains after you've gotten its check on a previous run. Getting stronger means you'll have less of a need for extra gold to be given to you, and you'll have less of a need for extra lives to save you.

Sometimes, Archipelago Chests spawn randomly on the ground.

The Archipelago Chests replace the hearts and chests that are normally hidden in the environment. The chest design, the Archipelago logo, is larger than regular chests and hearts are. This means that they sometimes do not fit in the space that chest or heart is supposed to be in. Noita automatically shoves items that get stuck in too-small spaces upwards until they reach an open surface they can rest on. While having a recolored or redesigned chest instead of a larger, essentially ball-shaped chest would resolve this issue, it would not be as fun. Additionally, vanilla chests do that sometimes anyway.

The Fungal Caverns don't replace all of their pedestals with checks.

The Fungal Caverns have a ridiculous number of pedestals. We decided to replace just the wand pedestals in the Fungal Caverns, rather than replacing both the wand and potion pedestals like we do in other biomes. Also, the Fungal Caverns exist in multiple places on the map, so you shouldn't have too much of a problem getting the pedestal checks for it.

On first load, the mines seem to not have as many pedestal checks as they feel like they should.

When you connect to the Archipelago server, the mod will ask the server for the DataPackage for the games that are included in the multiworld, so that the mod can populate the names, descriptions, and image types for the pedestal checks (and every other check where you can see what it is before you pick it up). If the DataPackage is very large, the pedestals may finish loading in before the DataPackage can finish arriving and being processed. The mod caches the DataPackage for individual games that it has seen before, and therefore does not ask for them again (unless the checksum is different), so this likely won't be an issue unless you've freshly installed the mod and play with several different games in the multiworld.

### Modding

The Archipelago implementation makes the following assumptions, so mods that greatly interfere with these may not
work well:

* All the vanilla biomes and Holy Mountains still exist.
* The entrance cave exists and has not been significantly altered.
* Holy Mountains exist at certain depths (with some tolerance to shifting their depth).
* There must be at least one chest or pedestal available in each of the vanilla biomes they appear normally.
* Biomes are traversed roughly in the vanilla layout, otherwise some items may be out-of-sequence.
* There are spell refreshes and shops in Holy Mountains, each with at least 5 items.
* There is a secret shop, with at least 4 items (it can be anywhere).
* The vanilla bosses and orbs still exist.
* That the player can complete their selected goal.

## Incompatible Mods (that we know about)

Below is a list of mods that have been reported not to work with this mod. This list will just include mods where you generally would expect them to work, but they don't.

Or, it would, if we had a list of any at the moment. If you find an incompatibility, please let us know and we will add it to this list.
