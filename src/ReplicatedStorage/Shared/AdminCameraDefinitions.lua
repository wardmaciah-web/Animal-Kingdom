-- One registry for physical camera panels, camera targets, and the client overlay.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KingdomConfig = require(ReplicatedStorage.SharedSource.Datas.AnimalKingdomConfig)

local definitions = {
	{ Id = "PlayerPlots", DisplayName = "PLAYER PLOTS", Target = "PlotCollection" },
	{ Id = "Town", DisplayName = "TOWN", Target = "TownPlaza" },
	{ Id = "Meadow", DisplayName = "MEADOW", Target = "Biome" },
	{ Id = "Forest", DisplayName = "FOREST", Target = "Biome" },
	{ Id = "Jungle", DisplayName = "JUNGLE", Target = "Biome" },
	{ Id = "Desert", DisplayName = "DESERT", Target = "Biome" },
	{ Id = "Snow", DisplayName = "SNOW", Target = "Biome" },
	{ Id = "Volcano", DisplayName = "VOLCANO", Target = "Biome" },
	{ Id = "Ocean", DisplayName = "OCEAN", Target = "Biome" },
	{ Id = "AncientRuins", DisplayName = "ANCIENT RUINS", Target = "Biome" },
	{ Id = "MagicalForest", DisplayName = "MAGICAL FOREST", Target = "Biome" },
	{ Id = "Sky", DisplayName = "SKY", Target = "Biome" },
	{ Id = "Prehistoric", DisplayName = "PREHISTORIC", Target = "Biome" },
	{ Id = "Mythical", DisplayName = "MYTHICAL", Target = "Biome" },
	{ Id = "HighOverview", DisplayName = "HIGH OVERVIEW", Target = "AllBiomes" },
}

local seen = {}
local targetTypes = { PlotCollection = true, TownPlaza = true, Biome = true, AllBiomes = true }
for _, camera in ipairs(definitions) do
	assert(type(camera.Id) == "string" and camera.Id ~= "", "Camera Id is required")
	assert(targetTypes[camera.Target], "Invalid Target for camera: " .. camera.Id)
	assert(not seen[camera.Id], "Duplicate camera Id: " .. camera.Id)
	seen[camera.Id] = true
end
for _, biome in ipairs(KingdomConfig.Biomes) do
	assert(seen[biome.Id], "Missing admin camera definition for biome: " .. biome.Id)
end

return table.freeze(definitions)
