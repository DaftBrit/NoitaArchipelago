
local tracks = {
	"animals/sheep/damage/projectile",
	"animals/sheep/damage/explosion",
	"animals/sheep/damage/projectile",
	"animals/sheep/confused",
}
local track = tracks[GameGetFrameNum() % 4 + 1]

local x, y = EntityGetTransform(GetUpdatedEntityID())
GamePlaySound("data/audio/Desktop/animals.bank", track, x, y)
