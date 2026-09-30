-- Compatibility name retained for existing service references.
-- WorldContentService binds gameplay to actual floors; the retired blockout builder
-- must never regenerate the authored town, plots, biomes, or admin room.
local Knit=require(game:GetService("ReplicatedStorage").Packages.Knit)
return Knit.CreateService({Name="WorldService",Client={}})
