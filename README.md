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

## Design Intent

Noita is a roguelike that does not have required items to beat the game (other than orbs for some endings). It's possible to beat the game without wands if you're feeling up to it. This goes against the general theme of Archipelago, since typically you need to find other players' required items so that they can find your required items, so that you can find theirs, and so on until you've all beaten your games. Despite this, Noita has something that makes it a compelling fit for Archipelago:

It's hard.

Looking at Steam's global achievement stats, it's safe to assume that at least 85% of people who have played Noita have not acheived any of the endings. The design goal for this mod is to essentially make you stronger and stronger as the multiworld progresses, kind of like how a roguelite does it. As you gain extra max health, more wand options at the start, and most importantly your immunity perks, it becomes easier to actually beat the game.

## Todo: update preview videos
 
## Local item
https://user-images.githubusercontent.com/87314354/187090201-85f3c0dd-7fa1-4844-b3bc-4a608170ba03.webm

## Remote item
https://user-images.githubusercontent.com/87314354/187090215-37e2f8da-d315-4515-b5c2-a26cbd133e5f.webm

## Installation

Find Noita in your Steam library, right click it and select Manage -> Browse Local Files.

Here you should see your game files and a folder called "mods". Create a folder called "archipelago" and place all files from within the zip folder directly into the archipelago folder. After starting Noita, select the Mods menu. Here you should see the Archipelago mod listed.

In order to enable the mod you will first need to toggle "Allow unsafe mods". This is required, as some external libraries are used in the mod in order to communicate with the Archipelago server. Enable "Allow unsafe mods" and enable the Archipelago mod.

## Configuration

In the Options menu, select Mod Settings. Under the Archipelago drop down, you will see the options for Hostname, Port, and Slot name, where you can fill in the relevant information.

Once you start a new run in Noita, you should see "Connected to Archipelago server" in the bottom left of the screen, as well as a unique perk. If you do not see this message, ensure that the mod is enabled and installed per the instructions above.

## Notes and Quirks

Potions and dice do not get delivered in async (won't get delivered if they are sent to you while your game is closed).

This is because it is just plain dangerous to deliver these to you when you've just spawned. Potions sometimes break when they spawn next to you, and the dice sometimes roll when they spawn. Getting spawn killed in Archipelago does not seem like much fun. It is, however, still fun when they spawn while you're actively playing, since you would potentially have time to react.

Potions, dice, spell refreshes, gold, and extra lives do not get redelivered to you on new game.

For the potions and dice, similar reason to the above. They like to break when they are spawned sometimes, espeically if they're spawned in a crowded room. We may find a nicer way to resend these on new game later on, though.

For spell refreshes, gold, and extra lives, they are intended to be "current run" buffs, rather than permanent buffs like other items act as. As noted above, you'll be getting stronger over the course of the course of the run. Getting stronger means you'll have less of a need for extra gold to be given to you. You'll have less of a need for spell refreshes to be dropped on you (especially since the shop ones will spawn once you've gotten those checks). And you'll have less of a need for extra lives to save you.

Sometimes, Archipelago Chests spawn randomly on the ground.

The Archipelago Chests replace the hearts and chests that are normally hidden in the environment. The chest design, the Archipelago logo, is larger than regular chests and hearts are. This means that they sometimes do not fit in the space that chest or heart is supposed to be in. Noita automatically shoves items that get stuck in too-small spaces upwards until they reach an open surface they can rest on. While having a recolored or redesigned chest instead of a larger, essentially ball-shaped chest would resolve this issue, it would not be as fun.

The Fungal Caverns don't replace all of their pedestals with checks.

The Fungal Caverns have a ridiculous number of pedestals. We decided to replace just the wand pedestals in the Fungal Caverns, rather than replacing both the wand and potion pedestals like we do in other biomes.

## Design Choices and Notes
### Redelivery and Async
* Potions are excluded since the flasks they are contained in will collide with each other and explode, spilling their
contents (can include lava, acid, polymorphine, etc).
* Traps would all be triggered instantly, which can lead to an imminent death.

### Modding

The Archipelago implementation makes the following assumptions, so mods that greatly interfere with these may not
work well:

* All the vanilla biomes and Holy Mountains still exist.
* Holy Mountains exist at certain depths (with some tolerance to shifting their depth).
* There must be at least one chest or pedestal available in each of the vanilla biomes they appear normally.
* Biomes are traversed roughly in the vanilla layout, otherwise some items may be out-of-sequence.
* There are spell refreshes and shops in Holy Mountains, each with at least 5 items.
* There is a secret shop, with at least 4 items (it can be anywhere).
* The vanilla bosses and orbs still exist.
* That the player can complete their selected goal.
