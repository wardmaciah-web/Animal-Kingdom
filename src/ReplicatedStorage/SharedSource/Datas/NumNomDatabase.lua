local Config = require(script.Parent.AnimalKingdomConfig)
local database = {}
local rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mystic" }
for index = 1, 82 do
	local biome = Config.Biomes[((index - 1) % #Config.Biomes) + 1]
	local rarityIndex = math.min(#rarities, math.ceil((index % 7 + 1) / 2))
	local id = string.format("NumNom_%03d", index)
	database[id] = table.freeze({
		NumNomId = id, Name = string.format("%s Num Nom %02d", biome.DisplayName, index), Biome = biome.Id,
		Rarity = rarities[rarityIndex], SpawnWeight = math.max(1, 100 - rarityIndex * 14),
		FriendshipTokens = rarityIndex, UnlockId = string.format("Decor_%03d", index),
	})
end
return table.freeze(database)
