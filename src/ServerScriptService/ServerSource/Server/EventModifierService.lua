local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local EventDefinitions = require(ReplicatedStorage.Shared.EventDefinitions)

local EventModifierService = Knit.CreateService({ Name = "EventModifierService", Client = {} })
local WeatherEventService
local movement = {}
local coinHistory = {}
local lastCoinStateKey

-- The actual game has Common/Uncommon/Rare/Epic/Legendary/Mystic.
-- "Mythical" event text targets the existing Mystic rarity, not the Mythical biome.
local rarityBuffKey = {
	Common = "CommonPetMultiplier",
	Rare = "RarePetMultiplier",
	Legendary = "LegendaryPetMultiplier",
	Mystic = "MythicalPetMultiplier",
	Mythical = "MythicalPetMultiplier", Secret = "MythicalPetMultiplier",
}
local luckExponent = { Common = 0, Uncommon = 0.25, Rare = 0.5, Epic = 0.75, Legendary = 1, Mystic = 1.25 }

function EventModifierService:GetActiveBuffs()
	local current = WeatherEventService:GetCurrentState()
	if current.Phase ~= "Event" then return nil end
	local definition = EventDefinitions[current.EventId]
	return definition and definition.Buffs or nil
end

function EventModifierService:GetMultiplier(key)
	local buffs = self:GetActiveBuffs()
	local value = buffs and buffs[key]
	return type(value) == "number" and value > 0 and value < math.huge and value or 1
end

function EventModifierService:GetCoinMultiplier()
	return self:GetMultiplier("CoinMultiplier")
end

local function recordCoinState()
	local current = WeatherEventService:GetCurrentState()
	local key = current.Phase == "Event" and (current.EventId .. ":" .. tostring(current.StartedAt)) or "Break"
	if key == lastCoinStateKey then return end
	lastCoinStateKey = key
	local at = current.Phase == "Event" and current.StartedAt or workspace:GetServerTimeNow()
	local previous = coinHistory[#coinHistory]
	if previous then at = math.max(at, previous.At) end
	table.insert(coinHistory, { At = at, Multiplier = EventModifierService:GetCoinMultiplier() })
	-- Online accrual is frequent; retain one boundary before the last day.
	local cutoff = at - 86_400
	while #coinHistory > 2 and coinHistory[2].At < cutoff do table.remove(coinHistory, 1) end
end

function EventModifierService:GetCoinWeightedSeconds(startedAt, endedAt)
	if type(startedAt) ~= "number" or type(endedAt) ~= "number" or endedAt <= startedAt then return 0 end
	recordCoinState()
	local weighted = 0
	local cursor = endedAt
	for index = #coinHistory, 1, -1 do
		local entry = coinHistory[index]
		if cursor > entry.At then
			local segmentStart = math.max(startedAt, entry.At)
			weighted += (cursor - segmentStart) * entry.Multiplier
			cursor = segmentStart
		end
		if cursor <= startedAt then break end
	end
	-- A timestamp predating the retained online history receives only base income.
	if cursor > startedAt then weighted += cursor - startedAt end
	return weighted
end

function EventModifierService:GetPetLuckMultiplier()
	return self:GetMultiplier("PetLuckMultiplier")
end

function EventModifierService:GetGlobalLuckMultiplier()
	return self:GetMultiplier("GlobalLuckMultiplier")
end

function EventModifierService:GetRarityMultiplier(rarity)
	local key = rarityBuffKey[rarity]
	return key and self:GetMultiplier(key) or 1
end

function EventModifierService:GetPetTypeMultiplier(typeName)
	-- Available for a future mixed-biome pet pool. Current shakeables contain
	-- only pets from their own biome, so applying this during their roll would
	-- multiply every candidate equally and have no actual effect.
	if typeName == "Desert" then return self:GetMultiplier("DesertPetMultiplier") end
	return 1
end

function EventModifierService:GetPetRollWeight(pet, baseWeight)
	if not pet or type(baseWeight) ~= "number" or baseWeight <= 0 then return 0 end
	local rarity = pet.Rarity
	local luck = self:GetPetLuckMultiplier() * self:GetGlobalLuckMultiplier()
	local weight = baseWeight * self:GetRarityMultiplier(rarity) * (luck ^ (luckExponent[rarity] or 0))
	return weight
end

function EventModifierService:GetMutationMultiplier()
	return self:GetMultiplier("MutationMultiplier")
end

function EventModifierService:GetMutationWeight(mutationId, baseWeight)
	if type(baseWeight) ~= "number" or baseWeight <= 0 then return 0 end
	return mutationId == "Normal" and baseWeight or baseWeight * self:GetMutationMultiplier()
end

function EventModifierService:GetShinyMultiplier()
	return self:GetMultiplier("ShinyMultiplier")
end

function EventModifierService:GetPetXPMultiplier()
	return self:GetMultiplier("PetXPMultiplier")
end

function EventModifierService:GetMovementMultiplier(_player)
	return Knit.GetService("ModifierService"):Get(_player, "WalkSpeed")
end

local function applyMovement(player)
	local record = movement[player]
	if not record or not record.Humanoid or not record.Humanoid.Parent then return end
	local multiplier = EventModifierService:GetMovementMultiplier(player)
	local target = record.BaseSpeed * multiplier
	record.ExpectedSpeed = target
	-- Humanoid stores a float32; comparing it exactly with a Luau double can
	-- mistake our own rounded write for a new base and compound the multiplier.
	if math.abs(record.Humanoid.WalkSpeed - target) > math.max(.0001, math.abs(target) * .000001) then
		record.ApplyingSpeed = true
		record.Humanoid.WalkSpeed = target
		record.ApplyingSpeed = false
	end
	record.ExpectedSpeed = record.Humanoid.WalkSpeed
end

local function attachCharacter(player, character)
	local record = movement[player]
	if not record then return end
	if record.SpeedConnection then record.SpeedConnection:Disconnect(); record.SpeedConnection = nil end
	record.Humanoid = nil
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or movement[player] ~= record or player.Character ~= character then return end
	record.Humanoid = humanoid
	record.BaseSpeed = humanoid.WalkSpeed
	record.ExpectedSpeed = nil
	record.SpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if record.ApplyingSpeed or (record.ExpectedSpeed and math.abs(humanoid.WalkSpeed - record.ExpectedSpeed) < .0001) then return end
		-- An unrelated server speed change becomes the new base, then weather applies once.
		record.BaseSpeed = humanoid.WalkSpeed
		applyMovement(player)
	end)
	applyMovement(player)
end

local function watchPlayer(player)
	if movement[player] then return end
	local record = {}
	movement[player] = record
	record.CharacterConnection = player.CharacterAdded:Connect(function(character)
		task.spawn(attachCharacter, player, character)
	end)
	if player.Character then task.spawn(attachCharacter, player, player.Character) end
end

function EventModifierService:RefreshMovement(player) applyMovement(player) end

function EventModifierService:KnitInit()
	WeatherEventService = Knit.GetService("WeatherEventService")
end

function EventModifierService:KnitStart()
	local state = ReplicatedStorage:WaitForChild("WeatherState")
	state.AttributeChanged:Connect(function(attribute)
		if attribute == "Phase" or attribute == "EventId" or attribute == "StartedAt" then
			recordCoinState()
			for player in pairs(movement) do applyMovement(player) end
		end
	end)
	recordCoinState()
	Players.PlayerAdded:Connect(watchPlayer)
	Players.PlayerRemoving:Connect(function(player)
		local record = movement[player]
		if not record then return end
		if record.CharacterConnection then record.CharacterConnection:Disconnect() end
		if record.SpeedConnection then record.SpeedConnection:Disconnect() end
		movement[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end
end

return EventModifierService
