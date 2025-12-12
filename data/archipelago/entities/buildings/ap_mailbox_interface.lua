local Globals = dofile("data/archipelago/scripts/globals.lua")

function interacting(entity_who_interacted, entity_interacted, interactable_name)
  if interactable_name ~= "ap_mailbox_interface" then return end

  Globals.GiftMailboxOpen:toggle()
end
