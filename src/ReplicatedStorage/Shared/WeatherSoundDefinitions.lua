-- Weather presentation only. Empty IDs are intentional upload/permission slots.
-- Do not replace an empty slot with an invented Roblox asset ID.
local Definitions = {}

Definitions.Mix = {
	MasterVolume = 0.72,
	FadeIn = 1.5,
	FadeOut = 1.2,
	MaxLoops = 3,
	MaxOneShots = 8,
	MaxVoices = 11,
	MaxPendingCues = 12,
	UpdateInterval = 0.2,
}

Definitions.Assets = {
	-- These IDs were already configured in Animal Kingdom before this polish pass.
	ExistingRain = { SoundId = "rbxassetid://1516791621", Description = "Existing rain recording" },
	ExistingThunder = { SoundId = "rbxassetid://12222030", Description = "Existing thunder recording" },
	ExistingWind = { SoundId = "rbxassetid://8202539690", Description = "Existing wind recording" },
	ExistingEerieWind = { SoundId = "rbxassetid://9114228918", Description = "Existing eerie wind recording" },
	ExistingMeteor = { SoundId = "rbxassetid://9120705982", Description = "Existing meteor whoosh recording" },
	ExistingWaterSplash = { SoundId = "rbxasset://sounds/impact_water.mp3", Description = "Roblox built-in splash verified in the live character" },
}

local function slot(name, description, fallback)
	Definitions.Assets[name] = { SoundId = "", Description = description, Fallback = fallback }
end

slot("DayAmbience", "Seamless peaceful daytime nature", "ExistingWind")
slot("Bird1", "Quiet daytime bird call variant 1")
slot("Bird2", "Quiet daytime bird call variant 2")
slot("WindGust1", "Broad wind gust variant 1", "ExistingWind")
slot("WindGust2", "Broad wind gust variant 2", "ExistingWind")
slot("LeafRustle", "Gentle foliage rustling loop")
slot("RainDistant", "Soft distant rain loop")
slot("RainSplash1", "Small water splash variant 1", "ExistingWaterSplash")
slot("RainSplash2", "Small water splash variant 2", "ExistingWaterSplash")
slot("RainDrip1", "Gentle rain drip texture")
slot("ThunderClose1", "Close thunder crack variant 1", "ExistingThunder")
slot("ThunderClose2", "Close thunder crack variant 2", "ExistingThunder")
slot("ThunderDistant1", "Long rolling distant thunder variant 1", "ExistingThunder")
slot("ThunderDistant2", "Long rolling distant thunder variant 2", "ExistingThunder")
slot("WinterWind", "Cold soft wind loop", "ExistingWind")
slot("WinterAmbience", "Quiet muffled winter ambience loop")
slot("FogDrone", "Quiet mysterious fog drone loop", "ExistingEerieWind")
slot("DistantForestCue", "Sparse mysterious distant forest sound")
slot("DryWind", "Dry airy desert wind loop", "ExistingWind")
slot("HeatInsects", "Subtle hot-weather insects loop")
slot("AuroraPad", "Beautiful airy aurora pad loop")
slot("CrystalChime1", "Soft crystalline chime variant 1")
slot("CrystalChime2", "Soft crystalline chime variant 2")
slot("MagicShimmer", "Soft magical shimmer loop")
slot("AirySweep", "Airy magical sweep")
slot("BloodMoonAmbience", "Low ominous blood moon drone loop", "ExistingEerieWind")
slot("BloodMoonPulse", "Soft low blood moon pulse")
slot("DarkMagic", "Quiet dark magical texture")
slot("BloodMoonStart", "Short ominous activation swell")
slot("NightHowl", "Rare distant atmospheric howl")
slot("MeteorSkyRumble", "Quiet distant sky rumble loop")
slot("MeteorWhooshSmall1", "Small fiery meteor whoosh variant 1", "ExistingMeteor")
slot("MeteorWhooshSmall2", "Small fiery meteor whoosh variant 2", "ExistingMeteor")
slot("MeteorWhooshLarge1", "Large fiery meteor whoosh variant 1", "ExistingMeteor")
slot("MeteorWhooshLarge2", "Large fiery meteor whoosh variant 2", "ExistingMeteor")
slot("MeteorImpactSmall1", "Small meteor rock impact variant 1", "ExistingThunder")
slot("MeteorImpactSmall2", "Small meteor rock impact variant 2", "ExistingThunder")
slot("MeteorImpactLarge1", "Large low-end meteor impact variant 1", "ExistingThunder")
slot("MeteorImpactLarge2", "Large low-end meteor impact variant 2", "ExistingThunder")
slot("RockDebris", "Short scattering stone debris")
slot("FireCrackle", "Short seamless crackling fire loop")
slot("FireBurst", "Brief rushing fire burst")
slot("SpiritAmbience", "Airy ghostly spirit ambience loop", "ExistingEerieWind")
slot("SpiritWhisper1", "Sparse indistinct spirit whisper variant 1")
slot("SpiritWhisper2", "Sparse indistinct spirit whisper variant 2")
slot("SpiritChime", "Soft nearby spirit orb chime")
slot("SpiritSweep", "Ghost passing/reversed airy sweep")
slot("RainbowAmbience", "Pleasant magical rainbow ambience loop")
slot("RainbowStart", "Brief happy rainbow activation shimmer")
slot("ChaosWarp", "Soft shifting chaotic ambience loop", "ExistingEerieWind")
slot("MagicZap1", "Soft magical zap variant 1")
slot("MagicZap2", "Soft magical zap variant 2")
slot("InvertedAmbience", "Reversed-feeling surreal ambience loop", "ExistingEerieWind")
slot("ReverseSweep", "Gentle backwards-feeling tonal sweep")
slot("NightmareDrone", "Dark distant nightmare drone loop", "ExistingEerieWind")
slot("NightmarePulse", "Subtle heartbeat-like pulse")
slot("NightmareStinger", "Rare quiet distant nightmare stinger")
slot("VoidAmbience", "Deep cosmic space ambience loop", "ExistingEerieWind")
slot("CosmicRumble", "Gentle broad cosmic low rumble loop")
slot("CosmicEnergy1", "Purple cosmic energy crack variant 1")
slot("CosmicEnergy2", "Purple cosmic energy crack variant 2")
slot("CosmicTone", "Distant planet/space tonal swell")
slot("VoidStart", "Short cosmic opening swell")
slot("GoldenAmbience", "Warm treasure-like magical ambience loop")
slot("GoldenChime1", "Soft valuable golden chime variant 1")
slot("GoldenChime2", "Soft valuable golden chime variant 2")
slot("GoldenStart", "Short rewarding golden activation swell")
slot("AdminRealityBreak", "Short large reality-breaking activation cue")
slot("EventEnd", "Short gentle neutral weather exit cue")

-- Equalizers vary tone without large pitch shifts. Low/Mid/High are decibels.
Definitions.Tones = {
	Natural = { Low = -2, Mid = 0, High = -1 },
	Soft = { Low = -4, Mid = -3, High = -5 },
	Cold = { Low = -6, Mid = -2, High = 1 },
	Dry = { Low = -7, Mid = 0, High = -1 },
	Distant = { Low = 1, Mid = -3, High = -8 },
	Ominous = { Low = 2, Mid = -3, High = -9 },
	Dream = { Low = -4, Mid = -2, High = -5 },
	Cosmic = { Low = 2, Mid = -4, High = -8 },
	Bright = { Low = -5, Mid = -1, High = 1 },
	Warped = { Low = -2, Mid = -7, High = -2 },
}

local function layer(name, asset, volume, category, tone, cycle)
	return { Name = name, Assets = { asset }, Volume = volume, Category = category or "Ambience", Tone = tone or "Natural", Cycle = cycle }
end
local function cue(assets, volume, category, minimum, maximum, duration, cooldown, tone)
	return { Assets = assets, Volume = volume, Category = category, MinDistance = minimum,
		MaxDistance = maximum, Duration = duration or 10, Cooldown = cooldown or 1, Tone = tone or "Natural" }
end

Definitions.Cues = {
	ThunderStrike = cue({ "ThunderClose1", "ThunderClose2" }, 0.56, "WorldSFX", 130, 1900, 12, 2.5),
	ThunderDistant = cue({ "ThunderDistant1", "ThunderDistant2" }, 0.34, "WorldSFX", 180, 2600, 14, 4, "Distant"),
	MeteorFlybySmall = cue({ "MeteorWhooshSmall1", "MeteorWhooshSmall2" }, 0.24, "WorldSFX", 70, 1300, 7, 0.8),
	MeteorFlybyLarge = cue({ "MeteorWhooshLarge1", "MeteorWhooshLarge2" }, 0.4, "WorldSFX", 160, 2200, 12, 3, "Distant"),
	MeteorImpactSmall = cue({ "MeteorImpactSmall1", "MeteorImpactSmall2" }, 0.36, "ImpactSFX", 95, 1400, 9, 0.8, "Distant"),
	MeteorImpactLarge = cue({ "MeteorImpactLarge1", "MeteorImpactLarge2" }, 0.62, "ImpactSFX", 230, 2900, 14, 3, "Cosmic"),
	RockDebris = cue({ "RockDebris" }, 0.14, "ImpactSFX", 20, 300, 4, 1),
	FireBurst = cue({ "FireBurst" }, 0.2, "ImpactSFX", 45, 650, 5, 2),
	FireCrackle = cue({ "FireCrackle" }, 0.1, "ImpactSFX", 20, 230, 6, 2),
	WindGust = cue({ "WindGust1", "WindGust2" }, 0.17, "WeatherLoops", 70, 900, 6, 4),
	SpiritPass = cue({ "SpiritSweep", "SpiritChime" }, 0.15, "MagicalSFX", 22, 250, 5, 3, "Dream"),
	SpiritWhisper = cue({ "SpiritWhisper1", "SpiritWhisper2" }, 0.055, "MagicalSFX", 16, 190, 5, 15),
	MagicBurst = cue({ "CrystalChime1", "CrystalChime2" }, 0.11, "MagicalSFX", 25, 420, 6, 3, "Bright"),
	MagicZap = cue({ "MagicZap1", "MagicZap2" }, 0.16, "MagicalSFX", 50, 850, 6, 2),
	EnergyStrike = cue({ "CosmicEnergy1", "CosmicEnergy2" }, 0.2, "CelestialSFX", 130, 2100, 9, 3, "Cosmic"),
	StarBurst = cue({ "GoldenChime1", "GoldenChime2" }, 0.13, "MagicalSFX", 30, 480, 6, 3, "Bright"),
	WaterSplash = cue({ "RainSplash1", "RainSplash2" }, 0.07, "WorldSFX", 14, 150, 3, 2),
	Bird = cue({ "Bird1", "Bird2" }, 0.085, "Ambience", nil, nil, 6, 15),
	RainDrip = cue({ "RainDrip1" }, 0.055, "Ambience", nil, nil, 5, 12),
	ForestDistant = cue({ "DistantForestCue" }, 0.07, "Ambience", nil, nil, 8, 18, "Distant"),
	AirySweep = cue({ "AirySweep" }, 0.09, "CelestialSFX", nil, nil, 8, 15, "Dream"),
	BloodPulse = cue({ "BloodMoonPulse" }, 0.12, "CelestialSFX", nil, nil, 8, 18, "Ominous"),
	DarkMagic = cue({ "DarkMagic", "NightHowl" }, 0.085, "Ambience", nil, nil, 9, 24, "Distant"),
	ReverseSweep = cue({ "ReverseSweep" }, 0.11, "Ambience", nil, nil, 8, 14, "Warped"),
	NightmarePulse = cue({ "NightmarePulse", "NightmareStinger" }, 0.1, "Ambience", nil, nil, 8, 18, "Ominous"),
	CosmicTone = cue({ "CosmicTone" }, 0.12, "CelestialSFX", nil, nil, 10, 22, "Cosmic"),
	BloodMoonStart = cue({ "BloodMoonStart" }, 0.2, "TransitionSFX", nil, nil, 6, 0, "Ominous"),
	RainbowStart = cue({ "RainbowStart" }, 0.17, "TransitionSFX", nil, nil, 5, 0, "Bright"),
	VoidStart = cue({ "VoidStart" }, 0.19, "TransitionSFX", nil, nil, 7, 0, "Cosmic"),
	GoldenStart = cue({ "GoldenStart" }, 0.17, "TransitionSFX", nil, nil, 5, 0, "Bright"),
	AdminStart = cue({ "AdminRealityBreak" }, 0.22, "TransitionSFX", nil, nil, 6, 0),
	End = cue({ "EventEnd" }, 0.085, "TransitionSFX", nil, nil, 2, 0, "Soft"),
}
Definitions.Cues.FireCrackle.Repeat = true -- Bounded six-second after-impact texture.
Definitions.Cues.MeteorImpactSmall.Followups = { "RockDebris", "FireCrackle" }
Definitions.Cues.MeteorImpactLarge.Followups = { "RockDebris", "FireBurst", "FireCrackle" }

-- World cues are triggered by actual VFX, never by a disconnected sound timer.
-- AmbientCues are deliberately sparse non-local texture, not fake impacts.
Definitions.Events = {
	SunnySkies = { Layers = { layer("Daytime", "DayAmbience", 0.095, nil, "Soft"), layer("Foliage", "LeafRustle", 0.055) }, AmbientCues = { "Bird" }, AmbientInterval = { 18, 34 } },
	RainyDay = { Layers = { layer("ModerateRain", "ExistingRain", 0.32, "WeatherLoops", "Soft"), layer("DistantRain", "RainDistant", 0.09, "WeatherLoops", "Distant"), layer("Breeze", "ExistingWind", 0.065, nil, "Soft") }, AmbientCues = { "RainDrip" }, AmbientInterval = { 14, 25 } },
	Thunderstorm = { Layers = { layer("HeavyRain", "ExistingRain", 0.43, "WeatherLoops"), layer("StormWind", "ExistingWind", 0.19, "WeatherLoops", "Distant"), layer("RainImpacts", "RainDistant", 0.12, "WeatherLoops") } },
	Snowfall = { Layers = { layer("WinterWind", "WinterWind", 0.13, "WeatherLoops", "Cold"), layer("QuietSnow", "WinterAmbience", 0.075, nil, "Soft") } },
	Foggy = { Layers = { layer("FogDrone", "FogDrone", 0.10, nil, "Distant"), layer("LowWind", "ExistingWind", 0.055, nil, "Soft") }, AmbientCues = { "ForestDistant" }, AmbientInterval = { 24, 43 } },
	Windy = { Layers = { layer("Wind", "ExistingWind", 0.28, "WeatherLoops"), layer("Rustle", "LeafRustle", 0.13, "WeatherLoops") } },
	Heatwave = { Layers = { layer("DryWind", "DryWind", 0.11, nil, "Dry"), layer("HeatInsects", "HeatInsects", 0.085) } },
	Aurora = { Layers = { layer("AuroraPad", "AuroraPad", 0.15, nil, "Dream"), layer("Shimmer", "MagicShimmer", 0.06, "MagicalSFX", "Bright"), layer("NightAir", "ExistingWind", 0.055, nil, "Soft") }, AmbientCues = { "AirySweep" }, AmbientInterval = { 21, 36 }, StartCue = "AirySweep" },
	BloodMoon = { Layers = { layer("MoonDrone", "BloodMoonAmbience", 0.22, nil, "Ominous"), layer("EerieAir", "ExistingWind", 0.065, nil, "Distant") }, AmbientCues = { "BloodPulse", "DarkMagic" }, AmbientInterval = { 22, 38 }, StartCue = "BloodMoonStart" },
	MeteorShower = { Layers = { layer("SkyRumble", "MeteorSkyRumble", 0.12, nil, "Distant"), layer("NightAir", "ExistingWind", 0.085, nil, "Cold") } },
	SpiritNight = { Layers = { layer("SpiritBed", "SpiritAmbience", 0.17, nil, "Dream"), layer("Air", "ExistingWind", 0.055, nil, "Soft"), layer("Shimmer", "MagicShimmer", 0.055, "MagicalSFX") } },
	Rainbow = { Layers = { layer("RainbowBed", "RainbowAmbience", 0.14, nil, "Bright"), layer("Glitter", "MagicShimmer", 0.045, "MagicalSFX", "Bright"), layer("Breeze", "ExistingWind", 0.06, nil, "Soft") }, StartCue = "RainbowStart" },
	-- Match the VFX's four five-second stages: rain/lightning, fire, snow/magic, energy.
	Chaos = { Layers = { layer("Warp", "ChaosWarp", 0.13, nil, "Warped"), layer("RainCycle", "ExistingRain", 0.12, "WeatherLoops", "Soft", { 20, 5, 2, true }), layer("WindCycle", "ExistingWind", 0.12, "WeatherLoops", "Cold", { 20, 5, 12 }) }, AmbientCues = { "ReverseSweep" }, AmbientInterval = { 18, 29 } },
	Inverted = { Layers = { layer("InvertedBed", "InvertedAmbience", 0.15, nil, "Warped"), layer("WrongAir", "ExistingWind", 0.07, nil, "Cold") }, AmbientCues = { "ReverseSweep" }, AmbientInterval = { 17, 29 }, StartCue = "ReverseSweep" },
	Nightmare = { Layers = { layer("NightmareBed", "NightmareDrone", 0.20, nil, "Ominous"), layer("ColdAir", "ExistingWind", 0.09, nil, "Distant") }, AmbientCues = { "NightmarePulse" }, AmbientInterval = { 23, 39 } },
	Void = { Layers = { layer("VoidBed", "VoidAmbience", 0.19, nil, "Cosmic"), layer("CosmicRumble", "CosmicRumble", 0.11, "CelestialSFX", "Cosmic"), layer("SpaceDust", "MagicShimmer", 0.04, "CelestialSFX", "Dream") }, AmbientCues = { "CosmicTone" }, AmbientInterval = { 25, 42 }, StartCue = "VoidStart" },
	Golden = { Layers = { layer("GoldenBed", "GoldenAmbience", 0.13, nil, "Bright"), layer("GoldShimmer", "MagicShimmer", 0.065, "MagicalSFX", "Bright"), layer("WarmAir", "ExistingWind", 0.055, nil, "Soft") }, StartCue = "GoldenStart" },
	-- Same sequence at 3.7 seconds per stage; cosmic rumble accompanies energy stage 3.
	AdminAbuse = { Layers = { layer("RealityWarp", "ChaosWarp", 0.14, nil, "Warped"), layer("RainCycle", "ExistingRain", 0.18, "WeatherLoops", "Natural", { 14.8, 3.7, 2, true }), layer("CosmicCycle", "CosmicRumble", 0.13, "CelestialSFX", "Cosmic", { 14.8, 3.7, 13.1 }) }, AmbientCues = { "ReverseSweep", "CosmicTone" }, AmbientInterval = { 15, 25 }, StartCue = "AdminStart" },
}

Definitions.Categories = { "Ambience", "WeatherLoops", "WorldSFX", "ImpactSFX", "MagicalSFX", "CelestialSFX", "TransitionSFX" }

function Definitions.GetMissingAssets()
	local missing = {}
	for name, asset in pairs(Definitions.Assets) do
		if asset.SoundId == "" then table.insert(missing, name) end
	end
	table.sort(missing)
	return missing
end

return Definitions
