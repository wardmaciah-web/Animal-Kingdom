-- One startup pass; no physics/update loop and no world regeneration.
local Policy = require(script.Parent.ServerSource.Utilities.TownCollisionPolicy)
local changed = Policy.Apply()
if #changed > 0 then print(string.format("[TownCollision] Restored %d inspected structural colliders", #changed)) end
