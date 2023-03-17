# Noita Archipelago
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

# Todo: update preview videos
 
# Local item
https://user-images.githubusercontent.com/87314354/187090201-85f3c0dd-7fa1-4844-b3bc-4a608170ba03.webm

# Remote item
https://user-images.githubusercontent.com/87314354/187090215-37e2f8da-d315-4515-b5c2-a26cbd133e5f.webm

# Installation

Find Noita in your Steam library, right click it and select Manage -> Browse Local Files.

Here you should see your game files and a folder called "mods". Create a folder called "archipelago" and place all files from within the zip folder directly into the archipelago folder. After starting Noita, select the Mods menu. Here you should see the Archipelago mod listed.

In order to enable the mod you will first need to toggle "Allow unsafe mods". This is required, as some external libraries are used in the mod in order to communicate with the Archipelago server. Enable "Allow unsafe mods" and enable the Archipelago mod.

# Configuration

In the Options menu, select Mod Settings. Under the Archipelago drop down, you will see the options for Hostname, Port, and Slot name, where you can fill in the relevant information.

Once you start a new run in Noita, you should see "Connected to Archipelago server" in the bottom left of the screen, as well as a unique perk. If you do not see this message, ensure that the mod is enabled and installed per the instructions above.
