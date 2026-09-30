-- Client-only, cosmetic visitors for Spirit Night. Ghost paths belong to the
-- world; the viewer position only chooses which nearby paths are rendered.
-- Every client evaluates the same path from the authoritative event start.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SpiritNightEffects = {}
local MAX_GHOSTS = 12
local UPDATE_STEP = 1 / 30
local SELECTION_STEP = 2
local PARTICLES_PER_GHOST = 11 -- 132/s maximum, plus the existing weather mist.
local BIOMES = {
	"Meadow", "Forest", "Jungle", "Desert", "Snow", "Volcano", "Ocean",
	"AncientRuins", "MagicalForest", "Sky", "Prehistoric", "Mythical",
}

local function viewerPosition()
	local player = Players.LocalPlayer
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then return root.Position end
	local camera = workspace.CurrentCamera
	return camera and camera.CFrame.Position or Vector3.new(-338, 15, 248)
end

local function part(model, name, size, offset, tint, transparency, material)
	local value = Instance.new("Part")
	value.Name = name
	value.Shape = Enum.PartType.Ball
	value.Size = size
	value.CFrame = offset
	value.Color = tint
	value.Material = material or Enum.Material.Neon
	value.Transparency = transparency
	value.Anchored = true
	value.CanCollide = false
	value.CanTouch = false
	value.CanQuery = false
	value.CastShadow = false
	value.Parent = model
	return value
end

local function emitter(parent, name, rate, smoke, tint)
	local value = Instance.new("ParticleEmitter")
	value.Name = name
	value.Texture = smoke and "rbxasset://textures/particles/smoke_main.dds"
		or "rbxasset://textures/particles/sparkles_main.dds"
	value.Rate = rate
	value.Lifetime = smoke and NumberRange.new(1.4, 2.2) or NumberRange.new(2, 3.2)
	value.Speed = smoke and NumberRange.new(0.4, 1.1) or NumberRange.new(1.2, 3)
	value.Acceleration = Vector3.new(0, smoke and 0.7 or 1.4, 0)
	value.SpreadAngle = Vector2.new(160, 160)
	value.Rotation = NumberRange.new(0, 360)
	value.RotSpeed = NumberRange.new(-35, 35)
	value.LightEmission = 0.8
	value.LightInfluence = 0
	value.LockedToPart = false
	value.Color = ColorSequence.new(tint, Color3.fromRGB(177, 144, 255))
	value.Size = smoke and NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.3),
		NumberSequenceKeypoint.new(1, 4),
	}) or NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 0.24),
		NumberSequenceKeypoint.new(1, 0),
	})
	value.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, smoke and 0.78 or 0.16),
		NumberSequenceKeypoint.new(0.7, smoke and 0.9 or 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	value.Parent = parent
	return value
end

local function worldPaths(startedAt)
	local paths = {}
	local ground = workspace:FindFirstChild("AnimalKingdomConcreteGround")
	local supports = {}
	if ground and ground:IsA("BasePart") then table.insert(supports, ground) end
	local town = workspace:FindFirstChild("TownPlaza")
	if town and town:IsA("BasePart") then table.insert(supports, town) end
	for _, name in ipairs(BIOMES) do
		local biome = workspace:FindFirstChild(name)
		local floor = biome and biome:FindFirstChild(name .. "Floor")
		if floor and floor:IsA("BasePart") then table.insert(supports, floor) end
	end
	-- The source-only development map has a different footprint from the
	-- authored place. Use its actual floor rather than spawning off the map.
	if #supports == 0 then
		local floor = workspace:FindFirstChild("GrassFloor")
		if floor and floor:IsA("BasePart") then
			ground = floor
			table.insert(supports, floor)
		end
	end
	if #supports == 0 then return paths end
	ground = ground or supports[1]
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances = supports
	ray.IgnoreWater = true
	local seed = math.floor(startedAt * 1000) % 2147483647
	local random = Random.new(seed)
	local halfX = math.max(0, ground.Size.X * 0.5 - 55)
	local halfZ = math.max(0, ground.Size.Z * 0.5 - 55)
	-- A fixed 85-stud lattice keeps paths available across Town, plots, and
	-- every biome without scanning Workspace or creating a whole-map crowd.
	for x = -halfX, halfX, 85 do
		for z = -halfZ, halfZ, 85 do
			local world = ground.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
			local hit = workspace:Raycast(world + Vector3.new(0, 300, 0), Vector3.new(0, -600, 0), ray)
			if hit then
				table.insert(paths, {
					id = #paths + 1,
					center = hit.Position + Vector3.new(0, random:NextNumber(6, 10), 0),
					radius = random:NextNumber(8, 17),
					phase = random:NextNumber(0, math.pi * 2),
					speed = random:NextNumber(0.14, 0.25),
					scale = random:NextNumber(1.1, 1.55),
					tint = Color3.fromRGB(random:NextInteger(162, 202), 245, 255),
				})
			end
		end
	end
	return paths
end

local function makeGhost(folder, path, now, density)
	local model = Instance.new("Model")
	model.Name = "FloatingGhost_" .. path.id
	model:SetAttribute("WorldPathCenter", path.center)
	local scale = path.scale
	local parts = {}
	local function add(name, size, position, transparency, face)
		local value = part(model, name, size * scale, CFrame.new(position * scale),
			face and Color3.fromRGB(20, 35, 55) or path.tint,
			transparency, face and Enum.Material.SmoothPlastic or Enum.Material.Neon)
		table.insert(parts, { value = value, transparency = transparency })
		return value
	end
	local body = add("SheetBody", Vector3.new(2.25, 2.7, 1.65), Vector3.new(0, -0.15, 0), 0.3)
	add("RoundHead", Vector3.new(2.55, 2.25, 1.85), Vector3.new(0, 1.1, 0), 0.2)
	add("LeftWisp", Vector3.new(0.85, 1.65, 0.95), Vector3.new(-0.7, -1.55, 0.12), 0.4)
	add("CenterWisp", Vector3.new(0.9, 2, 1), Vector3.new(0, -1.65, 0.2), 0.4)
	add("RightWisp", Vector3.new(0.85, 1.65, 0.95), Vector3.new(0.7, -1.55, 0.12), 0.4)
	add("LeftEye", Vector3.new(0.3, 0.48, 0.18), Vector3.new(-0.48, 1.3, -0.88), 0.08, true)
	add("RightEye", Vector3.new(0.3, 0.48, 0.18), Vector3.new(0.48, 1.3, -0.88), 0.08, true)
	add("LittleMouth", Vector3.new(0.25, 0.34, 0.14), Vector3.new(0, 0.7, -0.92), 0.1, true)
	model.WorldPivot = CFrame.new()
	emitter(body, "SpiritWisps", 5 * density, true, path.tint)
	local sparkles = emitter(body, "WanderingFireflies", (PARTICLES_PER_GHOST - 5) * density, false, path.tint)
	-- Fade in after positioning; nothing flashes at the origin on creation.
	for _, entry in ipairs(parts) do entry.value.Transparency = 1 end
	model:PivotTo(CFrame.new(path.center))
	model.Parent = folder
	sparkles:Emit(8)
	return { model = model, path = path, parts = parts, bornAt = now, fading = true }
end

function SpiritNightEffects.Start(runtime, startedAt, isCurrent, context)
	context = context or {}
	local quality = context.qualityScale or 1
	local density = quality * (context.intensity or 1)
	local ghostLimit = math.max(4, math.floor(MAX_GHOSTS * quality))
	local nextSpiritAudio = 0
	local spiritAudioCount = 0
	local folder = Instance.new("Folder")
	folder.Name = "SpiritNightWorld"
	folder:SetAttribute("GhostLimit", ghostLimit)
	folder:SetAttribute("MaximumParticleRate", ghostLimit * PARTICLES_PER_GHOST * density)
	folder.Parent = runtime
	local paths = worldPaths(startedAt)
	local ghosts = {}
	local heartbeat
	local destroying
	local stopped = false
	local elapsed = 0
	local selectionElapsed = SELECTION_STEP

	local function cleanup()
		if stopped then return end
		stopped = true
		if heartbeat then heartbeat:Disconnect() end
		if destroying then destroying:Disconnect() end
		table.clear(ghosts)
		folder:Destroy()
	end

	local function selectNearby(now)
		local viewer = viewerPosition()
		local ranked = {}
		for _, path in ipairs(paths) do
			-- Hysteresis prevents churn when standing between two paths.
			local distance = (path.center - viewer).Magnitude
			table.insert(ranked, { path = path, score = distance - (ghosts[path.id] and 18 or 0) })
		end
		table.sort(ranked, function(a, b) return a.score < b.score end)
		local selected = {}
		for i = 1, math.min(ghostLimit, #ranked) do
			if ranked[i].score < 340 then selected[ranked[i].path.id] = ranked[i].path end
		end
		for id, ghost in pairs(ghosts) do
			if not selected[id] then
				ghost.model:Destroy()
				ghosts[id] = nil
			end
		end
		for id, path in pairs(selected) do
			if not ghosts[id] then ghosts[id] = makeGhost(folder, path, now, density) end
		end
	end

	destroying = runtime.Destroying:Connect(cleanup)
	heartbeat = RunService.Heartbeat:Connect(function(delta)
		if stopped then return end
		if not runtime.Parent or not folder.Parent or not isCurrent() then
			cleanup()
			return
		end
		elapsed += delta
		selectionElapsed += delta
		if elapsed < UPDATE_STEP then return end
		elapsed %= UPDATE_STEP
		local now = workspace:GetServerTimeNow()
		if selectionElapsed >= SELECTION_STEP then
			selectionElapsed = 0
			selectNearby(now)
		end
		local age = math.max(0, now - startedAt)
		-- Sound timing uses logical world paths even at Low visual quality.
		if context.audio and now >= nextSpiritAudio then
			nextSpiritAudio = now + 11
			local viewer, nearest, distance = viewerPosition(), nil, 220
			for _, path in ipairs(paths) do
				local d = (path.center - viewer).Magnitude
				if d < distance then nearest = path; distance = d end
			end
			if nearest then
				spiritAudioCount += 1
				local theta = nearest.phase + age * nearest.speed
				local spiritPosition = nearest.center + Vector3.new(math.cos(theta)*nearest.radius, math.sin(age*1.3+nearest.phase)*1.15, math.sin(theta)*nearest.radius*0.7)
				context.audio:PlayCue("SpiritPass", spiritPosition)
				if spiritAudioCount % 3 == 0 then context.audio:PlayCue("SpiritWhisper", spiritPosition) end
			end
		end
		for _, ghost in pairs(ghosts) do
			local path = ghost.path
			local theta = path.phase + age * path.speed
			local position = path.center + Vector3.new(
				math.cos(theta) * path.radius,
				math.sin(age * 1.3 + path.phase) * 1.15,
				math.sin(theta) * path.radius * 0.7)
			local direction = Vector3.new(-math.sin(theta), 0, math.cos(theta) * 0.7)
			ghost.model:PivotTo(CFrame.lookAt(position, position + direction)
				* CFrame.Angles(0, 0, math.sin(age * 0.9 + path.phase) * 0.09))
			if ghost.fading then
				local alpha = math.clamp((now - ghost.bornAt) / 0.65, 0, 1)
				for _, entry in ipairs(ghost.parts) do
					entry.value.Transparency = 1 - (1 - entry.transparency) * alpha
				end
				ghost.fading = alpha < 1
			end
		end
	end)
	return cleanup
end

return SpiritNightEffects
