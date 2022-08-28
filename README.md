# Noita Archipelago
A Noita mod to provide support for the Archipelago multiworld platform

This mod takes all chests and converts them into Archipelago item checks. When interacting with a chest 
an item banner is dropped which must be walked over to pick up this then signals the archipelago server via websocket
that a check has taken place.

 - Chests are considered a check, all other items and pools are unaffected
 - Ability to spawn a chest after X number of kills
 - Items going into the pool that can be received from a check (from local or remote multiworlds)
    - GOOD:
      - Full Heal
      - Spell Refresh
      - Gold
      - Random wand (Tierd by rareity)
      - Max Health increase (Scarce)
    - BAD:
      - All stream integration "Bad" and "Awful" events
      - Bad events can be toggled in the player yaml settings
 
TODO mod install guide
 
[Local item](https://user-images.githubusercontent.com/87314354/187090201-85f3c0dd-7fa1-4844-b3bc-4a608170ba03.webm)
[Remote item](https://user-images.githubusercontent.com/87314354/187090215-37e2f8da-d315-4515-b5c2-a26cbd133e5f.webm)
