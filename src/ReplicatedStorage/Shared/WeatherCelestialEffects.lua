-- Distant, cosmetic world objects. Anchors never depend on a camera or player.
-- Shared server time drives movement so every client sees the same sky region.
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Celestial = {}
local WHITE = Color3.new(1, 1, 1)
local WORLD_CENTER = Vector3.new(-338, 8, 248)
local ANIMATION_STEP = 1 / 15
local POSITIONS = {
	BloodMoon = Vector3.new(-6338, 8008, -23752),
	Rainbow = Vector3.new(-500, 60, -2200),
	Aurora = Vector3.new(-500, 850, -1700),
	VoidPlanet = Vector3.new(-3600, 1700, -7000),
	VoidMoon = Vector3.new(1300, 2600, -9200),
	AdminPlanet = Vector3.new(-1850, 2000, -4700),
}

local function part(parent, name, position, size, tint, transparency)
	local object = Instance.new("Part")
	object.Name = name
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.CastShadow = false
	object.Material = Enum.Material.Neon
	object.Color = tint or WHITE
	object.Transparency = transparency or 0
	object.Size = size or Vector3.one
	object.Position = position
	object.Parent = parent
	return object
end

local function anchor(parent, name, position)
	local object = part(parent, name, position, Vector3.one, WHITE, 1)
	object:SetAttribute("FixedWorldPosition", position)
	return object
end

local function attachment(parent, name, position, tangent)
	local object = Instance.new("Attachment")
	object.Name = name
	object.Position = position
	object.Axis = tangent or Vector3.xAxis
	object.Parent = parent
	return object
end

local function beam(parent, name, from, to, tint, width, curve)
	local object = Instance.new("Beam")
	object.Name = name
	object.Attachment0 = from
	object.Attachment1 = to
	object.Color = ColorSequence.new(tint)
	object.Width0 = width
	object.Width1 = width
	object.CurveSize0 = curve or 0
	object.CurveSize1 = curve or 0
	object.Segments = 24
	-- Facing the viewer affects ribbon thickness, never its anchored world path.
	object.FaceCamera = true
	object.LightEmission = 1
	object.LightInfluence = 0
	object.Transparency = NumberSequence.new(0.22)
	object.Parent = parent
	return object
end

local function circle(parent, name, size, position, tint, transparency)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.fromScale(size, size)
	frame.Position = position
	frame.BackgroundColor3 = tint
	frame.BackgroundTransparency = transparency or 0
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	return frame
end

local function softEmitter(parent, name, tint, size, rate)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(9, 13)
	emitter.Speed = NumberRange.new(12, 24)
	emitter.SpreadAngle = Vector2.new(160, 160)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-3, 3)
	emitter.Color = ColorSequence.new(tint)
	emitter.LightEmission = 0.65
	emitter.LightInfluence = 0
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.7), NumberSequenceKeypoint.new(1, size) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.86), NumberSequenceKeypoint.new(0.65, 0.9), NumberSequenceKeypoint.new(1, 1) })
	emitter.LockedToPart = false
	emitter.Parent = parent
	return emitter
end

local function addStars(parent, quality, tint, seed)
	local stars = {}
	local rng = Random.new(seed)
	local count = math.floor(8 + 24 * quality) -- 32 High / 16 Low; fewer for Moon/Spirit.
	for index = 1, count do
		local azimuth = rng:NextNumber(0, math.pi * 2)
		local elevation = rng:NextNumber(0.23, 1.15)
		local distance = rng:NextNumber(4800, 7200)
		local position = WORLD_CENTER + Vector3.new(math.cos(azimuth) * math.cos(elevation), math.sin(elevation), math.sin(azimuth) * math.cos(elevation)) * distance
		local star = anchor(parent, "WorldStar", position)
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "WorldStarGlint"
		billboard.Adornee = star
		local size = rng:NextNumber(24, 38)
		billboard.Size = UDim2.fromScale(size, size)
		billboard.AlwaysOnTop = false
		billboard.LightInfluence = 0
		billboard.Brightness = 1.5
		billboard.MaxDistance = 0
		billboard.Parent = star
		local color = tint:Lerp(WHITE, rng:NextNumber(0.1, 0.8))
		local halo = circle(billboard, "StarHalo", 1, UDim2.fromScale(0.5, 0.5), color, 0.82)
		local glint = circle(billboard, "StarCore", 0.65, UDim2.fromScale(0.5, 0.5), color, 0.1)
		stars[index] = { glint = glint, halo = halo, phase = rng:NextNumber(0, 6.28) }
	end
	return stars
end

local function addRainbow(parent)
	local object = anchor(parent, "RainbowAnchor", POSITIONS.Rainbow)
	local colors = { Color3.fromRGB(255, 90, 103), Color3.fromRGB(255, 177, 80), Color3.fromRGB(255, 237, 104), Color3.fromRGB(114, 227, 147), Color3.fromRGB(110, 188, 255), Color3.fromRGB(114, 123, 243), Color3.fromRGB(186, 132, 255) }
	for index, tint in ipairs(colors) do
		local radius = 1204 - (index - 1) * 24.64
		local curve = radius * 0.5522847498
		local left = attachment(object, "Left" .. index, Vector3.new(-radius, 0, 0), Vector3.yAxis)
		local top = attachment(object, "Top" .. index, Vector3.new(0, radius, 0), Vector3.xAxis)
		local right = attachment(object, "Right" .. index, Vector3.new(radius, 0, 0), -Vector3.yAxis)
		for _, arc in ipairs({ beam(object, "RainbowArc", left, top, tint, 24.08, curve), beam(object, "RainbowArc", top, right, tint, 24.08, curve) }) do
			arc.Segments = 64
			arc.LightEmission = 0
			arc.Transparency = NumberSequence.new(0.15)
		end
	end
	return object
end

local function addBloodMoon(parent)
	local object = anchor(parent, "BloodMoonAnchor", POSITIONS.BloodMoon)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BloodMoonDisc"
	billboard.Adornee = object
	-- Scale components are studs, not pixels. The disc naturally leaves the view
	-- when the player turns away and remains occluded by intervening geometry.
	billboard.Size = UDim2.fromScale(5600, 5600)
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 0
	billboard.Brightness = 1.5
	billboard.MaxDistance = 0
	billboard.Parent = object
	local halos = {}
	for index = 1, 5 do
		local halo = circle(billboard, "RedCorona" .. index, 1 - (index - 1) * 0.034, UDim2.fromScale(0.5, 0.5), Color3.fromRGB(249, 44, 40), 0.96 - index * 0.009)
		halos[index] = halo
	end
	local face = circle(billboard, "MoonFace", 0.79, UDim2.fromScale(0.5, 0.5), Color3.fromRGB(255, 133, 102))
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 213, 153)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(239, 90, 70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(93, 16, 35)) })
	gradient.Rotation = 32
	gradient.Parent = face
	for index, crater in ipairs({ {0.3, 0.31, 0.2}, {0.66, 0.28, 0.13}, {0.59, 0.64, 0.23}, {0.28, 0.65, 0.11}, {0.77, 0.49, 0.09}, {0.46, 0.43, 0.12}, {0.39, 0.79, 0.065}, {0.73, 0.72, 0.08}, {0.47, 0.19, 0.065} }) do
		local rim = circle(face, "CraterRim" .. index, crater[3], UDim2.fromScale(crater[1], crater[2]), Color3.fromRGB(255, 173, 119), 0.7)
		circle(rim, "CraterBasin", 0.84, UDim2.fromScale(0.54, 0.49), Color3.fromRGB(89, 22, 34), 0.42)
	end
	return halos
end

local function addAurora(parent, quality)
	local object = anchor(parent, "AuroraAnchor", POSITIONS.Aurora)
	local ribbons = {}
	local colors = { Color3.fromRGB(73, 255, 179), Color3.fromRGB(73, 225, 255), Color3.fromRGB(128, 159, 255), Color3.fromRGB(201, 118, 255), Color3.fromRGB(116, 255, 204) }
	local count = quality < 0.55 and 3 or 5
	for row = 1, count do
		-- A continuous cubic strip has no interior endpoint seam. A faint wider
		-- second strip softens its edge without transparent geometry stacks.
		local from = attachment(object, "AuroraStart", Vector3.new(-1500, row * 75, row * 95), Vector3.xAxis)
		local to = attachment(object, "AuroraEnd", Vector3.new(1500, row * 75, row * 95), Vector3.xAxis)
		local bands = {}
		for layer = 1, 2 do
			local ribbon = beam(object, layer == 1 and "AuroraRibbon" or "AuroraGlow", from, to, colors[row], layer == 1 and 125 or 235, 1100)
			ribbon.Segments = 64
			ribbon.Color = ColorSequence.new(colors[row], colors[row % #colors + 1])
			ribbon.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, layer == 1 and 0.57 or 0.95),
				NumberSequenceKeypoint.new(0.5, layer == 1 and 0.35 or 0.88),
				NumberSequenceKeypoint.new(0.8, layer == 1 and 0.57 or 0.95),
				NumberSequenceKeypoint.new(1, 1),
			})
			bands[layer] = ribbon
		end
		ribbons[row] = { points = {from, to}, beams = bands }
	end
	return ribbons
end

local function planetBillboard(object, name, diameter)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = name
	billboard.Adornee = object
	billboard.Size = UDim2.fromScale(diameter, diameter)
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 0
	billboard.Brightness = 1.25
	billboard.MaxDistance = 0
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Global
	billboard.Parent = object
	return billboard
end

local function addPlanet(parent, name, position, diameter, tint, secondary, ringed)
	local object = anchor(parent, name .. "Anchor", position)
	-- Far physical spheres disappear at some Studio rendering settings. The
	-- tested moon-style billboard is world sized and anchored at the SAME
	-- distant coordinates, with normal building/terrain occlusion.
	local billboard = planetBillboard(object, name .. "Disc", diameter * 1.85)
	local glow = circle(billboard, "PlanetAtmosphere", 0.6, UDim2.fromScale(0.5, 0.5), secondary, 0.9)
	glow.ZIndex = 1
	local body = circle(billboard, name .. "Body", 1 / 1.85, UDim2.fromScale(0.5, 0.5), WHITE)
	body.ZIndex = 2
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, secondary:Lerp(WHITE, 0.42)),
		ColorSequenceKeypoint.new(0.35, secondary),
		ColorSequenceKeypoint.new(0.67, tint),
		ColorSequenceKeypoint.new(1, tint:Lerp(Color3.new(0.01, 0.01, 0.035), 0.78)),
	})
	gradient.Rotation = 32
	gradient.Parent = body
	for index = 1, 4 do
		local band = circle(body, ringed and "CloudBand" or "MoonCrater", ringed and 0.35 or (0.1 + index * 0.023), UDim2.fromScale(0.36 + (index % 2) * 0.18, 0.22 + index * 0.13), tint:Lerp(secondary, 0.45), 0.64)
		if ringed then band.Size = UDim2.fromScale(0.48, 0.065); band.Rotation = -15 end
		band.ZIndex = 3
	end
	local ringRoot
	if ringed then
		ringRoot = Instance.new("Frame")
		ringRoot.Name = "PlanetRings"
		ringRoot.Size = UDim2.fromScale(1, 1)
		ringRoot.AnchorPoint = Vector2.new(0.5, 0.5)
		ringRoot.Position = UDim2.fromScale(0.5, 0.5)
		ringRoot.BackgroundTransparency = 1
		ringRoot.Parent = billboard
		-- Ring segments are lightweight UI quads, split behind/in front of the
		-- shaded disc. They stay inside this world-space billboard, never UI.
		for band = 1, 2 do
			local radiusX = band == 1 and 0.445 or 0.485
			local radiusY = band == 1 and 0.15 or 0.175
			for index = 0, 31 do
				local angle = index / 32 * math.pi * 2
				local segment = Instance.new("Frame")
				segment.Name = "PlanetRingSegment"
				segment.AnchorPoint = Vector2.new(0.5, 0.5)
				segment.Position = UDim2.fromScale(0.5 + math.cos(angle) * radiusX, 0.5 + math.sin(angle) * radiusY)
				local length = math.sqrt((math.sin(angle) * radiusX) ^ 2 + (math.cos(angle) * radiusY) ^ 2) * math.pi / 16 * 1.06
				segment.Size = UDim2.fromScale(length, band == 1 and 0.014 or 0.007)
				segment.Rotation = math.deg(math.atan2(math.cos(angle) * radiusY, -math.sin(angle) * radiusX))
				segment.BackgroundColor3 = secondary:Lerp(WHITE, band * 0.19)
				segment.BackgroundTransparency = band == 1 and 0.22 or 0.45
				segment.BorderSizePixel = 0
				segment.ZIndex = math.sin(angle) >= 0 and 4 or 1
				segment.Parent = ringRoot
			end
		end
	end
	local satellite = anchor(object, "OrbitingMoon", position)
	-- Its path is deliberately orbital, so only the main celestial anchor has
	-- a FixedWorldPosition invariant.
	satellite:SetAttribute("FixedWorldPosition", nil)
	local satelliteBillboard = planetBillboard(satellite, "OrbitingMoonDisc", diameter * 0.14)
	local satelliteFace = circle(satelliteBillboard, "MoonFace", 0.9, UDim2.fromScale(0.5, 0.5), WHITE)
	local satelliteGradient = Instance.new("UIGradient")
	satelliteGradient.Color = ColorSequence.new(secondary:Lerp(WHITE, 0.55), tint)
	satelliteGradient.Rotation = 35
	satelliteGradient.Parent = satelliteFace
	return { anchor = object, position = position, body = body, glow = glow, satellite = satellite, size = diameter, tint = tint, ringRoot = ringRoot, gradient = gradient }
end

local function addAdminBeams(parent)
	local object = anchor(parent, "RealityPrismAnchor", Vector3.new(-450, 1200, -3000))
	local beams = {}
	for index = 1, 3 do
		local from = attachment(object, "PrismStart", Vector3.new(-1250, index * 130, index * 95), Vector3.new(1, 0.65, 0).Unit)
		local to = attachment(object, "PrismEnd", Vector3.new(1250, index * 100, index * 95), Vector3.new(1, -0.65, 0).Unit)
		beams[index] = beam(object, "RealityBeam", from, to, Color3.fromHSV(index / 3, 0.6, 1), 28, 800)
		beams[index].Transparency = NumberSequence.new(0.58)
	end
	return beams
end

function Celestial.Start(runtime, eventId, startedAt, isCurrent, context)
	context = context or {}
	local quality = math.clamp(context.qualityScale or 1, 0.35, 1)
	local intensity = math.clamp(context.intensity or 1, 0.35, 1)
	local supported = eventId == "BloodMoon" or eventId == "Rainbow" or eventId == "Aurora" or eventId == "Void" or eventId == "AdminAbuse" or eventId == "MeteorShower" or eventId == "SpiritNight"
	if not supported then return function() end end
	local folder = Instance.new("Folder")
	folder.Name = "CelestialEffects"
	folder:SetAttribute("WorldSpace", true)
	folder:SetAttribute("QualityScale", quality)
	folder:SetAttribute("AnimationHz", 15)
	folder.Parent = runtime
	local stars, halos, ribbons, adminBeams = {}, {}, {}, {}
	local planets = {}
	local moonSnapshots = {}
	local connection, destroyConnection, skyConnection
	local cleaned = false
	local function hideNormalMoon(sky)
		if sky:IsA("Sky") then
			moonSnapshots[sky] = sky.MoonAngularSize
			sky.MoonAngularSize = 0
		end
	end
	local function cleanup()
		if cleaned then return end
		cleaned = true
		if connection then connection:Disconnect() end
		if destroyConnection then destroyConnection:Disconnect() end
		if skyConnection then skyConnection:Disconnect() end
		for sky, size in pairs(moonSnapshots) do
			if sky.Parent then sky.MoonAngularSize = size end
		end
		folder:Destroy()
	end

	if eventId == "BloodMoon" then
		halos = addBloodMoon(folder)
		stars = addStars(folder, quality * 0.4, Color3.fromRGB(244, 152, 143), 7259)
		for _, sky in ipairs(Lighting:GetChildren()) do hideNormalMoon(sky) end
		skyConnection = Lighting.ChildAdded:Connect(hideNormalMoon)
	elseif eventId == "Rainbow" then
		addRainbow(folder)
	elseif eventId == "Aurora" then
		ribbons = addAurora(folder, quality)
		stars = addStars(folder, quality, Color3.fromRGB(149, 219, 255), 7311)
	elseif eventId == "Void" or eventId == "AdminAbuse" then
		local admin = eventId == "AdminAbuse"
		stars = addStars(folder, quality, Color3.fromRGB(199, 158, 255), 7369)
		planets[1] = addPlanet(folder, admin and "AdminPlanet" or "VoidPlanet", admin and POSITIONS.AdminPlanet or POSITIONS.VoidPlanet, admin and 680 or 930, Color3.fromRGB(79, 40, 150), Color3.fromRGB(183, 115, 255), true)
		if not admin then
			planets[2] = addPlanet(folder, "VoidMoon", POSITIONS.VoidMoon, 820, Color3.fromRGB(67, 98, 162), Color3.fromRGB(134, 215, 252), false)
		else
			addRainbow(folder)
			adminBeams = addAdminBeams(folder)
		end
		for index = 1, quality < 0.55 and 1 or 2 do
			local nebula = part(folder, "NebulaAnchor", Vector3.new(-2800 + index * 1600, 2650, -7500), Vector3.new(1600, 350, 200), WHITE, 1)
			nebula:SetAttribute("FixedWorldPosition", nebula.Position)
			softEmitter(nebula, "CosmicNebula", index == 1 and Color3.fromRGB(169, 70, 237) or Color3.fromRGB(66, 130, 226), 850, 2.5 * quality * intensity)
		end
	elseif eventId == "MeteorShower" then
		stars = addStars(folder, quality, Color3.fromRGB(192, 218, 255), 7411)
	elseif eventId == "SpiritNight" then
		stars = addStars(folder, quality * 0.55, Color3.fromRGB(177, 243, 233), 7507)
	end

	local function update(now)
		local elapsed = math.max(0, now - startedAt)
		for _, star in ipairs(stars) do
			local pulse = 0.5 + 0.5 * math.sin(elapsed * 0.63 + star.phase)
			star.glint.BackgroundTransparency = 0.12 + 0.28 * pulse
			star.halo.BackgroundTransparency = 0.78 + 0.14 * pulse
		end
		for index, halo in ipairs(halos) do
			halo.BackgroundTransparency = math.clamp(0.96 - index * 0.009 + math.sin(elapsed * 0.38) * 0.018 * intensity, 0, 1)
		end
		for row, ribbon in ipairs(ribbons) do
			local phase = elapsed * 0.2 + row * 0.72
			ribbon.points[1].Position = Vector3.new(-1500, row * 75 + math.sin(phase) * 65, row * 95)
			ribbon.points[2].Position = Vector3.new(1500, row * 75 + math.cos(phase) * 65, row * 95 + 80)
			ribbon.points[1].Axis = Vector3.new(1, math.sin(phase * 0.8 + row) * 0.85, 0.08).Unit
			ribbon.points[2].Axis = Vector3.new(1, math.cos(phase * 0.8 + row) * 0.85, -0.08).Unit
			for layer, band in ipairs(ribbon.beams) do
				local width = layer == 1 and 125 or 235
				band.Width0 = width + math.sin(phase) * 25
				band.Width1 = width + math.cos(phase) * 25
				band.CurveSize0 = 1050 + math.sin(phase * 0.6) * 180
				band.CurveSize1 = 1050 + math.cos(phase * 0.6) * 180
			end
		end
		for index, planet in ipairs(planets) do
			local angle = elapsed * 0.028 + index * 1.7
			local orbit = Vector3.new(math.cos(angle) * planet.size * 0.92, math.sin(angle) * planet.size * 0.34, math.sin(angle) * planet.size * 0.6)
			planet.satellite.Position = planet.position + orbit
			planet.glow.BackgroundTransparency = 0.91 + math.sin(elapsed * 0.35 + index) * 0.025
			planet.gradient.Rotation = 32 + math.sin(elapsed * 0.04) * 16
			if planet.ringRoot then planet.ringRoot.Rotation = -22 + math.sin(elapsed * 0.025 + index) * 9 end
			if eventId == "AdminAbuse" then planet.body.BackgroundColor3 = Color3.fromHSV((elapsed * 0.025 + index * 0.2) % 1, 0.28, 1) end
		end
		for index, prism in ipairs(adminBeams) do
			prism.Color = ColorSequence.new(Color3.fromHSV((elapsed * 0.04 + index / 3) % 1, 0.64, 1))
			prism.CurveSize0 = 800 + math.sin(elapsed * 0.3 + index) * 220
			prism.CurveSize1 = 800 + math.cos(elapsed * 0.3 + index) * 220
		end
	end

	update(workspace:GetServerTimeNow())
	if #stars > 0 or #halos > 0 or #ribbons > 0 or #planets > 0 or #adminBeams > 0 then
		local accumulated = 0
		connection = RunService.Heartbeat:Connect(function(delta)
			if not runtime.Parent or not isCurrent() then cleanup() return end
			accumulated += delta
			if accumulated < ANIMATION_STEP then return end
			accumulated %= ANIMATION_STEP
			update(workspace:GetServerTimeNow())
		end)
	end
	destroyConnection = runtime.Destroying:Connect(cleanup)
	return cleanup
end

return Celestial
