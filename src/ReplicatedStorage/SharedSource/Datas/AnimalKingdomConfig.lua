local Config = {}

Config.SchemaVersion = 1
Config.MaxDisplayedPets = 70
Config.ShakeablesPerBiome = 5
Config.ResultsPerShakeable = 5
Config.InteractionDistance = 18
Config.ShakeCooldown = 1.5
Config.NumNomCollectCooldown = 0.75
Config.IncomeTickSeconds = 1

Config.Biomes = {
	{ Id = "Meadow", DisplayName = "Meadow", MinIncome = 1, MaxIncome = 9, UnlockCost = 0 },
	{ Id = "Forest", DisplayName = "Forest", MinIncome = 10, MaxIncome = 49, UnlockCost = 2_500 },
	{ Id = "Jungle", DisplayName = "Jungle", MinIncome = 50, MaxIncome = 199, UnlockCost = 25_000 },
	{ Id = "Desert", DisplayName = "Desert", MinIncome = 200, MaxIncome = 999, UnlockCost = 250_000 },
	{ Id = "Snow", DisplayName = "Snow", MinIncome = 1_000, MaxIncome = 4_900, UnlockCost = 2_500_000 },
	{ Id = "Volcano", DisplayName = "Volcano", MinIncome = 5_000, MaxIncome = 24_900, UnlockCost = 25_000_000 },
	{ Id = "Ocean", DisplayName = "Ocean", MinIncome = 25_000, MaxIncome = 124_900, UnlockCost = 250_000_000 },
	{ Id = "AncientRuins", DisplayName = "Ancient Ruins", MinIncome = 125_000, MaxIncome = 624_900, UnlockCost = 2_500_000_000 },
	{ Id = "MagicalForest", DisplayName = "Magical Forest", MinIncome = 625_000, MaxIncome = 2_490_000, UnlockCost = 25_000_000_000 },
	{ Id = "Sky", DisplayName = "Sky", MinIncome = 2_500_000, MaxIncome = 9_990_000, UnlockCost = 250_000_000_000 },
	{ Id = "Prehistoric", DisplayName = "Prehistoric", MinIncome = 10_000_000, MaxIncome = 49_900_000, UnlockCost = 2_500_000_000_000 },
	{ Id = "Mythical", DisplayName = "Mythical", MinIncome = 50_000_000, MaxIncome = 10_000_000_000_000, UnlockCost = 25_000_000_000_000 },
}

Config.RarityCounts = { Common = 2, Uncommon = 5, Rare = 6, Epic = 6, Legendary = 4, Mystic = 2 }
Config.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mystic" }
Config.Mutations = { "Normal", "Golden", "Leafy", "Frosted", "Lava", "Shadow", "Electric", "Crystal", "Rainbow" }
Config.MutationWeights = { Normal = 9000, Golden = 300, Leafy = 180, Frosted = 130, Lava = 100, Shadow = 80, Electric = 70, Crystal = 60, Rainbow = 30 }

return table.freeze(Config)
