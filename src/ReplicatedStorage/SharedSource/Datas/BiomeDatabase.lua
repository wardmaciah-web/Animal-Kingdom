local Config = require(script.Parent.AnimalKingdomConfig)
local byId = {}
for index, biome in ipairs(Config.Biomes) do
	byId[biome.Id] = table.freeze({
		Id = biome.Id,
		DisplayName = biome.DisplayName,
		Order = index,
		UnlockCost = biome.UnlockCost,
		PreviousBiome = index > 1 and Config.Biomes[index - 1].Id or nil,
	})
end
return table.freeze(byId)
