--!strict
-- Garden expedition tuning. Single source of truth for server + client preview.
local Garden = {}

Garden.MaxActive = 3
Garden.Currency = "GardenHarvest"

Garden.Durations = {
	SproutRun = { Id = "SproutRun", DisplayName = "Sprout Run", Seconds = 60, Label = "1 min" },
	GardenShift = { Id = "GardenShift", DisplayName = "Garden Shift", Seconds = 300, Label = "5 min" },
	GrandHarvest = { Id = "GrandHarvest", DisplayName = "Grand Harvest", Seconds = 900, Label = "15 min" },
}
Garden.DurationOrder = { "SproutRun", "GardenShift", "GrandHarvest" }

Garden.TripDisplay = {
 SproutRun = { Tagline = "Quick expedition", BaseLabel = "Low", BestFor = "fast farming" },
 GardenShift = { Tagline = "Balanced expedition", BaseLabel = "Medium", BestFor = "steady harvest" },
 GrandHarvest = { Tagline = "Long expedition", BaseLabel = "High", BestFor = "big hauls" },
}

Garden.RealmCenter = Vector3.new(2000, 30, 2000)

Garden.RarityMultiplier = {
	Common = 1,
	Uncommon = 1.5,
	Rare = 2.2,
	Epic = 3.2,
	Legendary = 5,
	Mythical = 8,
	Secret = 12,
}

Garden.CropNames = { "Carrot", "Tomato", "Pumpkin", "Starberry", "Moonmelon" }

Garden.Cosmetics = {
	FlowerCrown = { Id = "FlowerCrown", DisplayName = "Flower Crown", Cost = 40, Description = "A ring of garden blooms." },
	StrawberryHat = { Id = "StrawberryHat", DisplayName = "Strawberry Hat", Cost = 90, Description = "Freshly picked berry cap." },
	LeafyAura = { Id = "LeafyAura", DisplayName = "Leafy Aura", Cost = 150, Description = "Swirling garden leaves." },
	GoldenBloom = { Id = "GoldenBloom", DisplayName = "Golden Bloom", Cost = 300, Description = "A radiant golden harvest glow." },
	RainbowSprout = { Id = "RainbowSprout", DisplayName = "Rainbow Sprout", Cost = 500, Description = "The garden's rarest shimmer." },
}
Garden.CosmeticOrder = { "FlowerCrown", "StrawberryHat", "LeafyAura", "GoldenBloom", "RainbowSprout" }

function Garden.RarityMult(rarity: string): number
	return Garden.RarityMultiplier[rarity] or 1
end

function Garden.LevelMult(level: number): number
	return 1 + (math.max(1, level) - 1) * 0.03
end

-- Longer expeditions and higher rarity pets earn more. Deterministic preview.
function Garden.Estimate(rarity: string, level: number, mutationPower: number, shiny: boolean, prismatic: boolean, seconds: number): number
	local base = math.max(1, seconds) / 60 * 8
	local total = base * Garden.RarityMult(rarity) * Garden.LevelMult(level or 1) * (mutationPower or 1)
	if shiny then total *= 1.5 end
	if prismatic then total *= 2 end
	return math.max(1, math.floor(total))
end

-- Crop weights apply once per authoritative harvest event.
Garden.Crops = {
 Carrot={Weight=40,Rarity="Common",Icon="🥕",Color=Color3.fromRGB(242,135,49),Regrow=5},
 Tomato={Weight=30,Rarity="Common",Icon="🍅",Color=Color3.fromRGB(226,73,72),Regrow=5},
 Pumpkin={Weight=18,Rarity="Uncommon",Icon="🎃",Color=Color3.fromRGB(226,147,55),Regrow=8},
 Starberry={Weight=9,Rarity="Rare",Icon="★",Color=Color3.fromRGB(231,119,170),Regrow=11},
 Moonmelon={Weight=3,Rarity="Very Rare",Icon="☾",Color=Color3.fromRGB(143,208,202),Regrow=14},
}
Garden.CycleSeconds=6
Garden.UpgradePrices={150,300,600,1000,1600}
Garden.UpgradeOrder={"KeenNose","QuickForager","BountifulBeds","RareCropAlmanac","HarvestSatchel"}
Garden.Upgrades={
 KeenNose={DisplayName="Keen Nose",Description="+4 studs of visual forage range. Current beds are already in range; no extra rewards.",Unit="studs",Base=24,Step=4},
 QuickForager={DisplayName="Quick Forager",Description="+5% crop cycle speed per level; Harvest/minute is unchanged.",Unit="%",Base=0,Step=5},
 BountifulBeds={DisplayName="Bountiful Beds",Description="+5% crop quantity per level",Unit="%",Base=0,Step=5},
 RareCropAlmanac={DisplayName="Rare Crop Almanac",Description="+4% rare crop weighting per level",Unit="%",Base=0,Step=4},
 HarvestSatchel={DisplayName="Harvest Satchel",Description="+5% Harvest per level",Unit="%",Base=0,Step=5},
}
Garden.SupplyOrder={"LuckySprout","GoldenClover","ForagerTea","BountifulBrew","SwiftPaws","StarberryScent","MoonmelonCharm","GardenXPTreat"}
Garden.Supplies={
 LuckySprout={DisplayName="Lucky Sprout Potion",Cost=60,Seconds=600,Stat="Luck",Bonus=.2,Description="+20% rare crop luck"},
 GoldenClover={DisplayName="Golden Clover Tonic",Cost=180,Seconds=600,Stat="Luck",Bonus=.4,Description="+40% rare crop luck"},
 ForagerTea={DisplayName="Forager's Tea",Cost=80,Seconds=600,Stat="Yield",Bonus=.25,Description="+25% crop quantity"},
 BountifulBrew={DisplayName="Bountiful Brew",Cost=220,Seconds=600,Stat="Yield",Bonus=.5,Description="+50% crop quantity"},
 SwiftPaws={DisplayName="Swift Paws Elixir",Cost=100,Seconds=600,Stat="Speed",Bonus=.25,Description="+25% forage speed"},
 StarberryScent={DisplayName="Starberry Scent",Cost=140,Seconds=600,Stat="Starberry",Bonus=.75,Description="+75% Starberry weighting"},
 MoonmelonCharm={DisplayName="Moonmelon Charm",Cost=300,Seconds=600,Stat="Moonmelon",Bonus=1,Description="+100% Moonmelon weighting"},
 GardenXPTreat={DisplayName="Garden XP Treat",Cost=120,Seconds=900,Stat="XP",Bonus=.25,Description="+25% Garden pet XP"},
}
return table.freeze(Garden)
