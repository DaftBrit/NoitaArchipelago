local Globals = dofile("data/archipelago/scripts/globals.lua")

function interacting(entity_who_interacted, entity_interacted, interactable_name)
  if interactable_name ~= "ap_gift_interface" then return end

  Globals.GiftWindowOpen:set(1)
  print_error("INTERACTED! POGGIES!")
end
