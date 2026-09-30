-- Cosmetic weather accents. Cells and strikes are anchored in the world; the
-- player only chooses which fixed cells are rendered. No map part is modified.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Environment = {}
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local BIOMES = {"Meadow", "Forest", "Jungle", "Desert", "Snow", "Volcano", "Ocean", "AncientRuins", "MagicalForest", "Sky", "Prehistoric", "Mythical"}
local PALETTE = {Color3.fromRGB(255, 93, 126), Color3.fromRGB(255, 212, 91), Color3.fromRGB(117, 255, 166), Color3.fromRGB(91, 204, 255), Color3.fromRGB(196, 128, 255)}

local function part(parent, name, size, position, color, transparency)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.Position = position
	p.Color = color or Color3.new(1, 1, 1); p.Transparency = transparency or 1
	p.Material = Enum.Material.Neon
	p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = false
	p.Parent = parent
	return p
end

local function particle(parent, name, color, rate, size, lifetime, speed, smoky)
	local e = Instance.new("ParticleEmitter")
	e.Name = name; e.Texture = smoky and SMOKE or SPARK
	e.Color = typeof(color) == "ColorSequence" and color or ColorSequence.new(color)
	e.Rate = rate; e.Lifetime = NumberRange.new(lifetime * 0.7, lifetime)
	e.Speed = NumberRange.new(speed * 0.4, speed)
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size * 0.45), NumberSequenceKeypoint.new(0.25, size), NumberSequenceKeypoint.new(1, size * (smoky and 1.7 or 0))})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, smoky and 0.89 or 0.28), NumberSequenceKeypoint.new(0.75, smoky and 0.93 or 0.5), NumberSequenceKeypoint.new(1, 1)})
	e.LightEmission = smoky and 0.15 or 0.8; e.LightInfluence = smoky and 0.35 or 0
	e.Rotation = NumberRange.new(-180, 180); e.RotSpeed = NumberRange.new(-20, 20)
	e.SpreadAngle = Vector2.new(70, 70); e.LockedToPart = false
	e.Parent = parent
	return e
end

local function focusPosition()
	local player = Players.LocalPlayer
	local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root and root.Position or Vector3.new(-338, 12, 248)
end

function Environment.Start(runtime, eventId, startedAt, isCurrent, context)
	context = context or {}
	local scale = math.clamp((context.qualityScale or 1) * (context.intensity or 1), 0.15, 1)
	local cellLimit = math.clamp(math.floor(6 * scale + 0.5), 2, 6)
	local seed = math.floor(startedAt * 1000) % 2147483647
	local folder = Instance.new("Folder"); folder.Name = "WeatherEnvironment"; folder.Parent = runtime
	folder:SetAttribute("CellLimit", cellLimit); folder:SetAttribute("UpdateHz", 20)
	folder:SetAttribute("WorldSpace", true); folder:SetAttribute("EventId", eventId)
	local cells, bursts = {}, {}
	local connection, destroying, flashEffect
	local live = true
	local nextCells, lastAction, flashUntil = 0, -1, 0
	local worldGround = workspace:FindFirstChild("AnimalKingdomConcreteGround") or workspace:FindFirstChild("GrassFloor")
	if worldGround and not worldGround:IsA("BasePart") then worldGround = nil end
	local center = worldGround and worldGround.Position or Vector3.new(-338, 8, 248)
	local extent = worldGround and worldGround.Size * 0.5 or Vector3.new(650, 1, 650)
	local surfaces = {}
	if worldGround then table.insert(surfaces, worldGround) end
	for _, id in ipairs(BIOMES) do
		local root = workspace:FindFirstChild(id)
		local floor = root and root:FindFirstChild(id .. "Floor")
		if floor and floor:IsA("BasePart") then table.insert(surfaces, floor) end
	end
	if #surfaces == 0 then table.insert(surfaces, workspace.Terrain) end
	local surfaceQuery = RaycastParams.new()
	surfaceQuery.FilterType = Enum.RaycastFilterType.Include; surfaceQuery.FilterDescendantsInstances = surfaces
	surfaceQuery.RespectCanCollide = true
	local clearQuery = RaycastParams.new(); clearQuery.FilterType = Enum.RaycastFilterType.Exclude
	clearQuery.RespectCanCollide = true
	local floorCache = {}
	local function grounded(x, z, open)
		if math.abs(x - center.X) > extent.X - 35 or math.abs(z - center.Z) > extent.Z - 35 then return nil end
		local hit = workspace:Raycast(Vector3.new(x, center.Y + 1400, z), Vector3.new(0, -1800, 0), surfaceQuery)
		if not hit or hit.Normal.Y < 0.9 then return nil end
		if open then
			local excluded = {runtime}
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character then table.insert(excluded, player.Character) end
			end
			clearQuery.FilterDescendantsInstances = excluded
			local top = workspace:Raycast(hit.Position + Vector3.new(0, 180, 0), Vector3.new(0, -184, 0), clearQuery)
			if not top or not table.find(surfaces, top.Instance) then return nil end
		end
		return hit.Position
	end
	local function randomFor(index, salt)
		return Random.new((seed + index * 104729 + salt) % 2147483647)
	end
	local function cue(name, position, options)
		if context.audio then context.audio:PlayCue(name, position, options) end
	end
	local function cleanup()
		if not live then return end
		live = false
		if connection then connection:Disconnect() end
		if destroying then destroying:Disconnect() end
		if flashEffect then flashEffect:Destroy() end
		table.clear(cells); table.clear(bursts)
		folder:Destroy()
	end
	destroying = runtime.Destroying:Connect(cleanup)

	local function addEmitter(cell, name, color, rate, size, life, speed, smoky, acceleration)
		local e = particle(cell.anchor, name, color, rate * scale, size, life, speed, smoky)
		e.Acceleration = acceleration or Vector3.new(2, 0.2, 1)
		table.insert(cell.emitters, {emitter = e, rate = e.Rate})
		return e
	end
	local function mist(cell, name, color, amount, size)
		return addEmitter(cell, name, color, amount, size or 18, 6, 2.5, true, Vector3.new(2.2, 0, 0.8))
	end
	local function orb(cell, index, color, geometric, eyes)
		local r = randomFor(index, cell.key * 241)
		local offset = Vector3.new(r:NextNumber(-28, 28), r:NextNumber(4, 11), r:NextNumber(-28, 28))
		local p = part(cell.anchor, eyes and "DistantEyes" or (geometric and "InvertedGeometry" or "DriftingOrb"), Vector3.one * (eyes and 0.8 or r:NextNumber(0.65, 1.25)), cell.position + offset, color, 0.15)
		if not geometric then p.Shape = Enum.PartType.Ball end
		local entry = {part = p, origin = cell.position + offset, phase = r:NextNumber(0, 6), eyes = eyes, alpha = 0.15}
		if eyes then
			local right = p:Clone(); right.Name = "SecondEye"; right.Parent = cell.anchor
			entry.second = right
		end
		table.insert(cell.orbs, entry)
	end
	local function goldenRay(cell, index)
		local lower = Instance.new("Attachment"); lower.Name = "GoldenRayFoot"
		lower.Position = Vector3.new(index * 17 - 25, 0, 14 - index * 12); lower.Parent = cell.anchor
		local upper = Instance.new("Attachment"); upper.Name = "GoldenRayCrown"
		upper.Position = lower.Position + Vector3.new(13, 44, -7); upper.Parent = cell.anchor
		local beam = Instance.new("Beam"); beam.Name = "SoftGoldenRay"
		beam.Attachment0 = lower; beam.Attachment1 = upper; beam.Width0 = 1.8; beam.Width1 = 0.45
		beam.Color = ColorSequence.new(Color3.fromRGB(255, 226, 139)); beam.LightEmission = 0.7
		beam.FaceCamera = true; beam.Segments = 1
		beam.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.9), NumberSequenceKeypoint.new(0.8, 0.96), NumberSequenceKeypoint.new(1, 1)})
		beam.Parent = cell.anchor
	end
	local function makeCell(key, position)
		local cell = {key = key, position = position, emitters = {}, orbs = {}}
		cell.anchor = part(folder, "WorldCell_" .. key, Vector3.new(100, 0.4, 100), position + Vector3.new(0, 2.4, 0))
		cell.anchor:SetAttribute("WorldOrigin", position)
		if eventId == "SunnySkies" then
			addEmitter(cell, "SunlitPollen", Color3.fromRGB(255, 243, 174), 1.2, 0.26, 6, 0.65, false)
			addEmitter(cell, "SoftPetals", Color3.fromRGB(255, 199, 216), 0.3, 0.38, 5, 1.4, false, Vector3.new(2, 0.1, 0))
		elseif eventId == "RainyDay" or eventId == "Thunderstorm" then
			mist(cell, "RainGroundMist", Color3.fromRGB(162, 186, 205), eventId == "Thunderstorm" and 1.9 or 1.1, 14)
			local splash = addEmitter(cell, "RainSplashes", Color3.fromRGB(186, 221, 241), eventId == "Thunderstorm" and 9 or 5, 0.55, 0.4, 7, false, Vector3.new(0, -28, 0))
			splash.EmissionDirection = Enum.NormalId.Top; splash.SpreadAngle = Vector2.new(50, 50)
			cell.anchor.Position = position + Vector3.new(0, 0.22, 0)
		elseif eventId == "Snowfall" then
			mist(cell, "WinterGroundMist", Color3.fromRGB(207, 231, 251), 1.2, 18)
			addEmitter(cell, "DriftingSnowGust", Color3.fromRGB(238, 249, 255), 3.5, 0.45, 4, 6, false, Vector3.new(4, -0.2, 1))
		elseif eventId == "Foggy" then
			mist(cell, "RollingLowFog", Color3.fromRGB(170, 185, 184), 2.4, 28)
			mist(cell, "LongMistWisps", Color3.fromRGB(147, 167, 167), 0.7, 38)
		elseif eventId == "Windy" then
			mist(cell, "WindblownDust", Color3.fromRGB(183, 165, 119), 1.2, 8)
			local debris = addEmitter(cell, "LeafGlints", Color3.fromRGB(134, 177, 91), 3, 0.35, 2.8, 14, false, Vector3.new(16, 1, 3))
			debris.RotSpeed = NumberRange.new(70, 170)
		elseif eventId == "Heatwave" then
			mist(cell, "DryDust", Color3.fromRGB(232, 193, 120), 0.75, 15)
			local shimmer = mist(cell, "HorizonShimmer", Color3.fromRGB(255, 227, 174), 0.8, 24)
			shimmer.Acceleration = Vector3.new(0.4, 2.2, 0)
		elseif eventId == "Aurora" then
			addEmitter(cell, "AuroraGroundGlints", ColorSequence.new(Color3.fromRGB(137, 255, 216), Color3.fromRGB(198, 151, 255)), 1.8, 0.4, 5, 1.8, false)
		elseif eventId == "BloodMoon" then
			addEmitter(cell, "BloodEmbers", Color3.fromRGB(246, 51, 55), 2.1, 0.4, 5, 2.1, false, Vector3.new(0.8, 1.5, 0))
			mist(cell, "CrimsonShadowWisps", Color3.fromRGB(72, 12, 27), 0.9, 20)
		elseif eventId == "MeteorShower" then
			addEmitter(cell, "SettlingMeteorCinders", Color3.fromRGB(255, 184, 110), 0.8, 0.35, 3.5, 1.2, false, Vector3.new(1, -0.2, 0))
		elseif eventId == "SpiritNight" then
			mist(cell, "SpiritGroundMist", ColorSequence.new(Color3.fromRGB(65, 219, 185), Color3.fromRGB(157, 112, 234)), 1.5, 20)
			addEmitter(cell, "LostSoulGlints", Color3.fromRGB(153, 245, 236), 1.8, 0.5, 5, 2, false)
		elseif eventId == "Rainbow" then
			addEmitter(cell, "RainbowGlitter", ColorSequence.new({ColorSequenceKeypoint.new(0, PALETTE[1]), ColorSequenceKeypoint.new(0.3, PALETTE[2]), ColorSequenceKeypoint.new(0.6, PALETTE[3]), ColorSequenceKeypoint.new(1, PALETTE[5])}), 2.5, 0.4, 5, 1.7, false)
		elseif eventId == "Chaos" or eventId == "AdminAbuse" then
			addEmitter(cell, "RealitySparks", ColorSequence.new(PALETTE[1], PALETTE[4]), eventId == "AdminAbuse" and 4 or 2.5, 0.75, 3, 3, false)
			for i = 1, eventId == "AdminAbuse" and 3 or 2 do orb(cell, i, PALETTE[(key + i) % #PALETTE + 1], false) end
			local precipitation = part(cell.anchor, "RealityPrecipitationVolume", Vector3.new(80, 1, 80), position + Vector3.new(0, 28, 0))
			precipitation:SetAttribute("WorldOrigin", position + Vector3.new(0, 28, 0))
			local rain = addEmitter(cell, "RealityRain", Color3.fromRGB(143, 204, 255), 7, 0.45, 1.5, 15, false, Vector3.new(0, -24, 0))
			rain.Parent = precipitation; rain.EmissionDirection = Enum.NormalId.Bottom
			rain.SpreadAngle = Vector2.new(10, 10)
			rain.Enabled = false
			local snow = addEmitter(cell, "RealitySnow", Color3.new(1, 1, 1), 4, 0.7, 3, 3, false, Vector3.new(5, -1.5, 0))
			snow.Parent = precipitation; snow.EmissionDirection = Enum.NormalId.Bottom
			snow.SpreadAngle = Vector2.new(25, 25)
			snow.Enabled = false
		elseif eventId == "Inverted" then
			addEmitter(cell, "InvertedWhiteFlecks", Color3.new(1, 1, 1), 1.4, 0.7, 4, 1, false, Vector3.new(0, 2, 0))
			local black = addEmitter(cell, "InvertedBlackFlecks", Color3.new(0, 0, 0), 1.4, 0.7, 4, 1, false, Vector3.new(0, -1, 0))
			black.LightEmission = 0
			for i = 1, 3 do orb(cell, i, i % 2 == 0 and Color3.new(1, 1, 1) or Color3.fromRGB(8, 6, 16), true) end
		elseif eventId == "Nightmare" then
			mist(cell, "CrawlingShadowMist", Color3.fromRGB(28, 9, 38), 1.3, 24)
			addEmitter(cell, "BlackAsh", Color3.fromRGB(25, 11, 32), 1.7, 0.8, 4, 2, false)
			orb(cell, 1, Color3.fromRGB(243, 62, 86), false, true)
		elseif eventId == "Void" then
			mist(cell, "GroundNebula", Color3.fromRGB(106, 46, 175), 1.3, 22)
			addEmitter(cell, "CosmicDust", Color3.fromRGB(187, 127, 255), 2.3, 0.5, 6, 2.5, false)
			for i = 1, 2 do orb(cell, i, Color3.fromRGB(169, 97, 255), false) end
		elseif eventId == "Golden" then
			addEmitter(cell, "GoldenDust", ColorSequence.new(Color3.fromRGB(255, 219, 104), Color3.fromRGB(255, 248, 202)), 3, 0.48, 5.5, 1.4, false)
			mist(cell, "WarmGoldHaze", Color3.fromRGB(255, 219, 113), 0.35, 16)
			for i = 1, scale > 0.55 and 2 or 1 do goldenRay(cell, i) end
		end
		return cell
	end
	local function selectCells(now)
		local focus = focusPosition()
		local gx, gz = math.floor((focus.X - center.X) / 110 + 0.5), math.floor((focus.Z - center.Z) / 110 + 0.5)
		local candidates = {}
		for dx = -2, 2 do
			for dz = -2, 2 do
				local x, z = gx + dx, gz + dz
				local key = (x + 32) * 128 + z + 32
				local cached = floorCache[key]
				if cached == nil then
					cached = grounded(center.X + x * 110, center.Z + z * 110, true) or false
					floorCache[key] = cached
				end
				if cached then
					local distance = (Vector3.new(focus.X, cached.Y, focus.Z) - cached).Magnitude
					if cells[key] then distance -= 25 end -- hysteresis prevents boundary flicker
					table.insert(candidates, {key = key, position = cached, distance = distance})
				end
			end
		end
		table.sort(candidates, function(a, b) return a.distance < b.distance end)
		local wanted = {}
		for i = 1, math.min(cellLimit, #candidates) do wanted[candidates[i].key] = candidates[i].position end
		for key, cell in pairs(cells) do
			if not wanted[key] then cell.anchor:Destroy(); cells[key] = nil end
		end
		for key, position in pairs(wanted) do if not cells[key] then cells[key] = makeCell(key, position) end end
		local activeCells = 0
		for _ in pairs(cells) do activeCells += 1 end
		folder:SetAttribute("ActiveCells", activeCells)
		nextCells = now + 2
	end

	local function safeStrike(index)
		local r = randomFor(index, 8631)
		for _ = 1, 12 do
			local position = grounded(center.X + r:NextNumber(-extent.X + 55, extent.X - 55), center.Z + r:NextNumber(-extent.Z + 55, extent.Z - 55), true)
			if position then
				local safe = true
				for _, player in ipairs(Players:GetPlayers()) do
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if root and (root.Position - position).Magnitude < 45 then safe = false; break end
				end
				if safe then return position end
			end
		end
		return nil
	end
	local function burst(position, color, now, fire, ring)
		if #bursts >= 4 then return end
		local anchor = part(folder, fire and "HarmlessFireBurst" or "MagicStarBurst", Vector3.one, position + Vector3.new(0, 0.3, 0))
		local sparks = particle(anchor, "BurstSparks", color, 0, fire and 1.4 or 0.8, 1.6, fire and 28 or 14, false)
		sparks.Acceleration = Vector3.new(0, -14, 0); sparks:Emit(math.floor(32 * scale))
		local smoke = particle(anchor, fire and "FireSteam" or "MagicMist", fire and Color3.fromRGB(154, 131, 110) or color, 0, 7, 3.5, 8, true)
		smoke.Acceleration = Vector3.new(0, 4, 0); smoke:Emit(math.floor(12 * scale))
		if fire then
			local flame = particle(anchor, "FlameBurst", ColorSequence.new(Color3.fromRGB(255, 232, 134), Color3.fromRGB(255, 79, 31)), 0, 4, 1.1, 12, false)
			flame.Texture = "rbxasset://textures/particles/fire_main.dds"
			flame.Acceleration = Vector3.new(0, 12, 0); flame:Emit(math.floor(24 * scale))
		end
		local light = Instance.new("PointLight"); light.Color = color; light.Range = fire and 35 or 20; light.Brightness = 1.3; light.Parent = anchor
		local rings = {}
		if ring then
			for i = 1, 10 do
				local p = part(anchor, "CosmeticShockwave", Vector3.new(1, 0.12, 0.3), position, color, 0.3)
				table.insert(rings, {part = p, angle = i / 10 * math.pi * 2})
			end
		end
		table.insert(bursts, {part = anchor, at = now, light = light, rings = rings, position = position, lifetime = 4})
		if fire then cue("FireBurst", position) end
	end
	local function lightning(index, now, color, energy)
		if #bursts >= 4 then return end
		local position = safeStrike(index)
		if not position then return end
		local r = randomFor(index, 451)
		local anchor = part(folder, energy and "WorldEnergyStrike" or "WorldLightning", Vector3.one, position)
		anchor:SetAttribute("StrikePosition", position)
		local previous
		local beamList = {}
		for i = 0, 8 do
			local a = Instance.new("Attachment"); a.Name = "BoltNode" .. i
			a.Position = i == 8 and Vector3.zero or Vector3.new(r:NextNumber(-24, 24), (8 - i) * 66, r:NextNumber(-24, 24))
			a.Parent = anchor
			if previous then
				local beam = Instance.new("Beam"); beam.Name = "LightningBolt"
				beam.Attachment0 = previous; beam.Attachment1 = a
				beam.Color = ColorSequence.new(color); beam.Width0 = 2.4; beam.Width1 = 1.9
				beam.LightEmission = 1; beam.LightInfluence = 0; beam.FaceCamera = true; beam.Segments = 1
				beam.Transparency = NumberSequence.new(0); beam.Parent = anchor
				table.insert(beamList, beam)
			end
			previous = a
		end
		table.insert(bursts, {part = anchor, at = now, beams = beamList, lifetime = 0.75})
		burst(position, color, now, false, true)
		if not flashEffect then
			flashEffect = Instance.new("ColorCorrectionEffect"); flashEffect.Name = "AK_WeatherLightningFlash"
			flashEffect:SetAttribute("WeatherTemporary", true); flashEffect.Parent = Lighting
		end
		flashEffect.TintColor = Color3.new(1, 1, 1):Lerp(color, 0.12)
		flashEffect.Brightness = eventId == "Nightmare" and 0.075 or 0.15
		flashUntil = now + 0.32
		local distance = (focusPosition() - position).Magnitude
		-- The audio controller owns the speed-of-sound delay, so it is applied once.
		cue(energy and "EnergyStrike" or (distance > 650 and "ThunderDistant" or "ThunderStrike"), position)
	end
	local function nearbyPosition(index)
		local ordered = {}
		for _, cell in pairs(cells) do table.insert(ordered, cell) end
		table.sort(ordered, function(a, b) return a.key < b.key end)
		if #ordered == 0 then return nil end
		return ordered[index % #ordered + 1].position
	end
	local interval = ({Thunderstorm = 8.5, Windy = 7, Snowfall = 10, Heatwave = 13, BloodMoon = 12, Aurora = 13, Rainbow = 11, Golden = 7, SpiritNight = 13, Chaos = 5, AdminAbuse = 3.7, Nightmare = 16, Void = 12, RainyDay = 15, Inverted = 13})[eventId] or 18
	local function action(index, now)
		local position = nearbyPosition(index)
		if eventId == "Thunderstorm" then lightning(index, now, Color3.fromRGB(190, 219, 255), false)
		elseif eventId == "Nightmare" then lightning(index, now, Color3.fromRGB(245, 71, 101), false)
		elseif eventId == "Void" then lightning(index, now, Color3.fromRGB(174, 108, 255), true)
		elseif eventId == "Chaos" or eventId == "AdminAbuse" then
			local stage = index % 4
			folder:SetAttribute("CombinationStage", stage)
			if stage == 0 then lightning(index, now, PALETTE[index % #PALETTE + 1], false)
			elseif stage == 1 then local target = safeStrike(index); if target then burst(target, Color3.fromRGB(255, 160, 69), now, true, true) end
			elseif stage == 2 and position then burst(position, PALETTE[index % #PALETTE + 1], now, false, true); cue("MagicBurst", position)
			elseif stage == 3 then lightning(index, now, Color3.fromRGB(183, 121, 255), true) end
		elseif position and (eventId == "Windy" or eventId == "Snowfall" or eventId == "Heatwave") then
			folder:SetAttribute("GustAt", now); cue("WindGust", position)
			for _, cell in pairs(cells) do
				for _, entry in ipairs(cell.emitters) do entry.emitter:Emit(math.floor(8 * scale)) end
			end
		elseif position and (eventId == "Golden" or eventId == "Rainbow" or eventId == "Aurora") then
			local color = eventId == "Golden" and Color3.fromRGB(255, 221, 126) or (eventId == "Aurora" and Color3.fromRGB(151, 255, 219) or PALETTE[index % #PALETTE + 1])
			burst(position + Vector3.new(0, 5, 0), color, now, false, false)
			cue(eventId == "Golden" and "StarBurst" or "MagicBurst", position)
		elseif position and eventId == "RainyDay" then cue("WaterSplash", position)
		elseif position and eventId == "Inverted" then
			burst(position + Vector3.new(0, 5, 0), Color3.fromRGB(175, 245, 223), now, false, false)
			cue("MagicZap", position)
		end
	end

	local function update()
		if not live or runtime.Parent == nil or not isCurrent() then cleanup(); return end
		local now = workspace:GetServerTimeNow()
		local elapsed = math.max(0, now - startedAt)
		if now >= nextCells then selectCells(now) end
		local index = math.floor((elapsed - 2) / interval)
		if index >= 0 and index > lastAction then
			lastAction = index
			-- Do not replay an old burst when a late join occurs between action slots.
			if (elapsed - 2) % interval < 1 then action(index, now) end
		end
		local stage = math.max(0, lastAction) % 4
		for _, cell in pairs(cells) do
			for _, entry in ipairs(cell.orbs) do
				local phase = elapsed * 0.42 + entry.phase
				local position = entry.origin + Vector3.new(math.sin(phase) * 5, math.cos(phase * 1.7) * 1.2, math.cos(phase) * 5)
				entry.part.CFrame = CFrame.new(position) * CFrame.Angles(phase, phase * 0.7, phase * 0.4)
				entry.part.Transparency = entry.eyes and (0.2 + 0.6 * (math.sin(phase * 0.5) * 0.5 + 0.5)) or (0.14 + 0.1 * math.sin(phase))
				if entry.second then entry.second.Position = position + Vector3.new(1.8, 0, 0); entry.second.Transparency = entry.part.Transparency end
			end
			for _, entry in ipairs(cell.emitters) do
				local emitter = entry.emitter
				if emitter.Name == "RealityRain" then emitter.Enabled = stage == 0
				elseif emitter.Name == "RealitySnow" then emitter.Enabled = stage == 2
				elseif eventId == "BloodMoon" then emitter.Rate = entry.rate * (0.82 + math.sin(elapsed * 0.7) * 0.18) end
			end
		end
		for i = #bursts, 1, -1 do
			local b = bursts[i]; local age = now - b.at
			if age >= b.lifetime then b.part:Destroy(); table.remove(bursts, i)
			else
				if b.light then b.light.Brightness = 1.3 * math.max(0, 1 - age / 1.2) end
				if b.beams then
					local transparency = age < 0.1 and 0 or (age < 0.16 and 0.8 or math.clamp((age - 0.16) / 0.59, 0, 1))
					for _, beam in ipairs(b.beams) do beam.Transparency = NumberSequence.new(transparency) end
				end
				if b.rings then
					local alpha = math.clamp(age / 0.9, 0, 1)
					local radius = 2 + alpha * 20
					for _, ring in ipairs(b.rings) do
						ring.part.Size = Vector3.new(radius * 0.64, 0.12, 0.3)
						ring.part.CFrame = CFrame.new(b.position + Vector3.new(math.cos(ring.angle) * radius, 0.2, math.sin(ring.angle) * radius)) * CFrame.Angles(0, -ring.angle + math.pi / 2, 0)
						ring.part.Transparency = 0.3 + alpha * 0.7
					end
				end
			end
		end
		if flashEffect then flashEffect.Brightness = math.max(0, (flashUntil - now) / 0.32) * (eventId == "Nightmare" and 0.075 or 0.15) end
		folder:SetAttribute("ActiveBursts", #bursts)
	end
	update()
	local accumulator = 0
	if live then connection = RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator >= 1 / 20 then accumulator = 0; update() end
	end) end
	return cleanup
end

return Environment
