dofile_once("data/scripts/lib/utilities.lua")

function contains_element(tbl, elem)
  for _, v in ipairs(tbl) do
    if v == elem then return true end
  end
  return false
end

function not_empty(s)
  return s ~= nil and s ~= ''
end

function EntityLoadAtPlayer(filename, xoff, yoff)
  for i, p in ipairs(get_players()) do
    local x, y = EntityGetTransform(p)
    EntityLoad(filename, x + (xoff or 0), y + (yoff or 0))
  end
end
