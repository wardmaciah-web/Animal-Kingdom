local Config = require(script.Parent.AnimalKingdomConfig)
local Pets = require(script.Parent.PetDatabase)
local database = {}
for _, biome in ipairs(Config.Biomes) do
	local biomePets = {}
	for _, pet in ipairs(Pets.Ordered) do
		if pet.Biome == biome.Id then table.insert(biomePets, pet.PetId) end
	end
	for objectIndex = 1, 5 do
		local results = {}
		for resultIndex = 1, 5 do
			local petIndex = ((objectIndex - 1) * 5 + resultIndex - 1) % 25 + 1
			table.insert(results, biomePets[petIndex])
		end
		local id = string.format("%s_Shakeable_%02d", biome.Id, objectIndex)
		database[id] = table.freeze({ Id = id, Biome = biome.Id, Cost = math.max(10, biome.MinIncome * 10), Results = table.freeze(results) })
	end
end
return table.freeze(database)
