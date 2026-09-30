local Config = require(script.Parent.AnimalKingdomConfig)

local database = {}
local ordered = {}
local seenBiomes, seenRarities = {}, {}
local petsPerBiome = 0
for _, rarity in ipairs(Config.RarityOrder) do
	assert(type(rarity) == "string" and not seenRarities[rarity], "Duplicate or invalid rarity in RarityOrder")
	seenRarities[rarity] = true
	local count = Config.RarityCounts[rarity]
	assert(type(count) == "number" and count >= 0 and count % 1 == 0, "Invalid rarity count for " .. rarity)
	petsPerBiome += count
end
assert(petsPerBiome > 0, "PetDatabase requires at least one configured pet per biome")

for biomeIndex, biome in ipairs(Config.Biomes) do
	assert(type(biome.Id) == "string" and biome.Id ~= "" and not seenBiomes[biome.Id], "Duplicate or invalid biome Id")
	seenBiomes[biome.Id] = true
	local petNumber = 0
	for _, rarity in ipairs(Config.RarityOrder) do
		for rarityIndex = 1, Config.RarityCounts[rarity] do
			petNumber += 1
			local petId = string.format("%s_%s_%02d", biome.Id, rarity, rarityIndex)
			local alpha = (petNumber - 1) / 24
			local income = math.floor(biome.MinIncome + (biome.MaxIncome - biome.MinIncome) * alpha)
			if biomeIndex == #Config.Biomes and petNumber == 25 then
				income = 10_000_000_000_000
			end
			local record = table.freeze({
				PetId = petId,
				Name = string.format("%s %s %02d", biome.DisplayName, rarity, rarityIndex),
				Biome = biome.Id,
				Rarity = rarity,
				CoinsPerSecond = income,
				Source = "Shakeable",
				Prismatic = rarity == "Mystic" and rarityIndex == 2,
			})
			assert(not database[petId], "Duplicate generated PetId: " .. petId)
			database[petId] = record
			table.insert(ordered, record)
		end
	end
end

assert(#ordered == #Config.Biomes * petsPerBiome, "PetDatabase count does not match the configured biome roster")
database.Ordered = table.freeze(ordered)
return table.freeze(database)
