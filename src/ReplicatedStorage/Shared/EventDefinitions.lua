-- Shared event metadata. Only the server service decides which event is active.
local EVENT_DURATION = 7 * 60

local function normal(id, displayName, description, weight)
	return {
		Id = id,
		DisplayName = displayName,
		Category = "Normal",
		Description = description,
		Weight = weight,
		Duration = EVENT_DURATION,
		IsAutomatic = true,
		IsSecret = false,
		Buffs = {},
		ImageId = "",
		DisplayEffects = {},
	}
end

local function secret(id, displayName, description)
	return {
		Id = id,
		DisplayName = displayName,
		Category = "Secret",
		Description = description,
		Weight = 0,
		Duration = EVENT_DURATION,
		IsAutomatic = false,
		IsSecret = true,
		Buffs = {},
		ImageId = "",
		DisplayEffects = {},
	}
end

local definitions = {
	SunnySkies = normal("SunnySkies", "Sunny Skies", "Clear skies and warm sunlight.", 18),
	RainyDay = normal("RainyDay", "Rainy Day", "A steady rain across the kingdom.", 14),
	Thunderstorm = normal("Thunderstorm", "Thunderstorm", "Dark clouds, thunder, and lightning.", 9),
	Snowfall = normal("Snowfall", "Snowfall", "Soft snow falls over the world.", 9),
	Foggy = normal("Foggy", "Foggy", "A thick mist settles over the land.", 10),
	Windy = normal("Windy", "Windy", "Strong winds sweep through the biomes.", 10),
	Heatwave = normal("Heatwave", "Heatwave", "Intense heat fills the air.", 9),
	Aurora = normal("Aurora", "Aurora", "Colorful lights shimmer overhead.", 5),
	BloodMoon = normal("BloodMoon", "Blood Moon", "A crimson moon rises over the kingdom.", 4),
	MeteorShower = normal("MeteorShower", "Meteor Shower", "Meteors streak across the night sky.", 5),
	SpiritNight = normal("SpiritNight", "Spirit Night", "An eerie, mystical night arrives.", 4),
	Rainbow = normal("Rainbow", "Rainbow", "A bright rainbow spans the sky.", 4),
	Chaos = secret("Chaos", "Chaos", "An unpredictable disturbance takes hold."),
	Inverted = secret("Inverted", "Inverted", "The world takes on an inverted theme."),
	Nightmare = secret("Nightmare", "Nightmare", "A haunting nightmare atmosphere arrives."),
	Void = secret("Void", "Void", "A mysterious void overtakes the sky."),
	Golden = secret("Golden", "Golden", "The kingdom glows with a golden theme."),
	AdminAbuse = secret("AdminAbuse", "Admin Abuse", "A special admin-controlled event theme."),
}

-- Structured server gameplay modifiers. A value of 1 is neutral.
-- DisplayEffects below remain presentation text and are never parsed for gameplay.
local gameplayBuffs = {
	SunnySkies = { CoinMultiplier = 1.5, PetLuckMultiplier = 1.10 },
	RainyDay = { CoinMultiplier = 1.25, CommonPetMultiplier = 1.15 },
	Thunderstorm = { RarePetMultiplier = 1.5, MutationMultiplier = 1.25 },
	Snowfall = { CoinMultiplier = 2.0, IcePetMultiplier = 1.25 },
	Foggy = { ShinyMultiplier = 1.25 },
	Windy = { FlyingPetMultiplier = 1.5, MovementSpeedMultiplier = 1.25 },
	Heatwave = { CoinMultiplier = 2.0, DesertPetMultiplier = 1.25 },
	Aurora = { ShinyMultiplier = 3.0, RarePetMultiplier = 1.5 },
	BloodMoon = { MutationMultiplier = 2.0, LegendaryPetMultiplier = 1.5 },
	MeteorShower = { RarePetMultiplier = 3.0 },
	SpiritNight = { MythicalPetMultiplier = 2.0 },
	Rainbow = { GlobalLuckMultiplier = 2.0 },
	Chaos = { CoinMultiplier = 5.0, PetLuckMultiplier = 5.0, ShinyMultiplier = 5.0, MutationMultiplier = 5.0, PetXPMultiplier = 5.0 },
	Inverted = { RarePetMultiplier = 3.0 },
	Nightmare = { LegendaryPetMultiplier = 10.0 },
	Void = { MythicalPetMultiplier = 5.0, MutationMultiplier = 3.0 },
	Golden = { CoinMultiplier = 10.0, ShinyMultiplier = 5.0 },
	AdminAbuse = { CoinMultiplier = 5.0, PetLuckMultiplier = 3.0, RarePetMultiplier = 3.0, LegendaryPetMultiplier = 3.0, MythicalPetMultiplier = 3.0, ShinyMultiplier = 5.0, MutationMultiplier = 5.0, PetXPMultiplier = 3.0, MovementSpeedMultiplier = 1.5 },
}

for id, buffs in pairs(gameplayBuffs) do
	definitions[id].Buffs = buffs
end

-- Presentation text only; some named pet types do not exist in game data yet.
local display = {
	SunnySkies = { "Beautiful weather has covered the kingdom!", "+50% Coins", "+10% Pet Luck" },
	RainyDay = { "Rain is falling across Animal Kingdom.", "+25% Coins", "+15% Common Pet Chance" },
	Thunderstorm = { "Lightning crackles across the kingdom!", "+50% Rare Pet Chance", "+25% Mutation Chance" },
	Snowfall = { "Snow is covering the kingdom!", "2x Coins", "+25% Ice Pet Chance" },
	Foggy = { "A mysterious fog has rolled in.", "+25% Shiny Chance", "Special Fog Pets" },
	Windy = { "Powerful winds sweep across the kingdom.", "+50% Flying Pet Chance", "+25% Movement Speed" },
	Heatwave = { "The kingdom is heating up!", "2x Coins", "+25% Desert Pet Chance" },
	Aurora = { "A magical aurora shines above the kingdom.", "3x Shiny Chance", "+50% Rare Pet Chance" },
	BloodMoon = { "The Blood Moon has risen...", "2x Mutation Chance", "+50% Legendary Pet Chance" },
	MeteorShower = { "Meteors are raining across the kingdom!", "3x Rare Pet Chance", "Meteor Pets" },
	SpiritNight = { "Spirits have awakened throughout the kingdom.", "2x Mythical Pet Chance", "Ghost Pets" },
	Rainbow = { "A magical rainbow has appeared!", "2x Luck", "Improved Pet Chances" },
	Chaos = { "Reality has completely broken.", "5x Everything", "Random Chaos Effects" },
	Inverted = { "The kingdom has been turned upside down.", "3x Rare Pet Chance", "Strange Physics" },
	Nightmare = { "A nightmare has consumed Animal Kingdom.", "10x Legendary Pet Chance", "Nightmare Pets" },
	Void = { "The Void is consuming the kingdom.", "5x Mythical Pet Chance", "Mutation Storm" },
	Golden = { "Everything has turned to gold!", "10x Coins", "5x Shiny Chance" },
	AdminAbuse = { "The admins have lost control.", "Random Extreme Buffs", "Admin Chaos" },
}

for id, lines in pairs(display) do
	local definition = definitions[id]
	definition.Description = lines[1]
	definition.DisplayEffects = { lines[2], lines[3] }
end

return definitions
