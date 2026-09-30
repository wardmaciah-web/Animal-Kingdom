local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Database = require(ReplicatedStorage.SharedSource.Datas.NumNomDatabase)
local Guard = require(script.Parent.Parent.Utilities.GameplayGuard)

local NumNomService = Knit.CreateService({ Name = "NumNomService", Client = {} })
local DataService
local CurrencyService
local activeById = {}
local random = Random.new()
local biomeSpacing = 160
local biomeSlots = {
	Vector2.new(-1.5, -1.5), Vector2.new(-0.5, -1.5), Vector2.new(0.5, -1.5), Vector2.new(1.5, -1.5),
	Vector2.new(1.5, -0.5), Vector2.new(1.5, 0.5), Vector2.new(1.5, 1.5), Vector2.new(0.5, 1.5),
	Vector2.new(-0.5, 1.5), Vector2.new(-1.5, 1.5), Vector2.new(-1.5, 0.5), Vector2.new(-1.5, -0.5),
}

function NumNomService:Collect(player, instance)
	if not Guard.RateLimit(player, "NumNom", 0.75) or not Guard.IsNear(player, instance, 16) then return false end
	local id = instance:GetAttribute("NumNomId")
	local definition = type(id) == "string" and Database[id]
	local data = DataService:Get(player)
	if not definition or not data or not data.UnlockedBiomes[definition.Biome] then return false end
	local index = table.clone(data.NumNomIndex)
	local firstDiscovery = not index[id]
	index[id] = (index[id] or 0) + 1
	DataService:Set(player, "NumNomIndex", index)
	CurrencyService:Add(player, "FriendshipTokens", definition.FriendshipTokens)
	if firstDiscovery then
		local decorations = table.clone(data.UnlockedDecorations)
		decorations[definition.UnlockId] = true
		DataService:Set(player, "UnlockedDecorations", decorations)
	end
	activeById[instance] = nil
	instance:Destroy()
	return true
end

function NumNomService:SpawnOne()
	local totalWeight = 0
	for _, candidate in pairs(Database) do totalWeight += candidate.SpawnWeight end
	local roll = random:NextInteger(1, totalWeight)
	local definition
	for _, candidate in pairs(Database) do
		roll -= candidate.SpawnWeight
		if roll <= 0 then definition = candidate break end
	end
	if not definition then return end
	local runtime = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Runtime")
	if not runtime then return end
	local object = Instance.new("Part")
	object.Name = definition.NumNomId
	object.Shape = Enum.PartType.Ball
	object.Size = Vector3.new(2.5, 2.5, 2.5)
	object.Anchored = true
	local blockout = workspace.World:FindFirstChild("BiomeBlockout")
	local biomeModel = blockout and blockout:FindFirstChild(definition.Biome)
	local platform = biomeModel and biomeModel:FindFirstChild("Platform")
	if platform then
		object.Position = platform.Position + Vector3.new(
			random:NextNumber(-platform.Size.X * 0.4, platform.Size.X * 0.4),
			3,
			random:NextNumber(-platform.Size.Z * 0.4, platform.Size.Z * 0.4)
		)
	else
		local biomeIndex = 1
		for index, biome in ipairs(require(ReplicatedStorage.SharedSource.Datas.AnimalKingdomConfig).Biomes) do
			if biome.Id == definition.Biome then biomeIndex = index break end
		end
		local slot = biomeSlots[biomeIndex]
		object.Position = Vector3.new(
			slot.X * biomeSpacing + random:NextNumber(-60, 60),
			2,
			slot.Y * biomeSpacing + random:NextNumber(-60, 60)
		)
	end
	object.Color = Color3.fromRGB(255, 153, 204)
	object:SetAttribute("NumNomId", definition.NumNomId)
	object:SetAttribute("BiomeId", definition.Biome)
	object.Parent = runtime
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Befriend"
	prompt.ObjectText = definition.Name
	prompt.MaxActivationDistance = 12
	prompt.Parent = object
	prompt.Triggered:Connect(function(player) self:Collect(player, object) end)
	activeById[object] = true
end

function NumNomService:KnitStart()
	-- The authored map replaces the old blockout coordinates. Do not populate
	-- future gameplay with prototype spheres unless a developer opts in.
	for _, biome in ipairs(require(ReplicatedStorage.SharedSource.Datas.AnimalKingdomConfig).Biomes) do
		local region = workspace:FindFirstChild(biome.Id)
		local floor = region and region:FindFirstChild(biome.Id .. "Floor")
		if floor and floor:IsA("BasePart") and workspace:GetAttribute("AK_EnableLegacyGameplayScaffold") ~= true then
			print("[NumNomService] Prototype world spawns disabled for authored map")
			return
		end
	end
	task.spawn(function()
		while true do
			task.wait(5)
			local count = 0
			for object in pairs(activeById) do if object.Parent then count += 1 else activeById[object] = nil end end
			if count < math.max(12, #Players:GetPlayers() * 6) then self:SpawnOne() end
		end
	end)
end

function NumNomService:KnitInit()
	DataService = Knit.GetService("PlayerDataService")
	CurrencyService = Knit.GetService("CurrencyService")
end

return NumNomService
