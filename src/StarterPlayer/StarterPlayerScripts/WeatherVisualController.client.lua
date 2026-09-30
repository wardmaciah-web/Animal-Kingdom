local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local DEBUG_VISUALS = RunService:IsStudio()
local TRANSITION = 2
if DEBUG_VISUALS then print("[WeatherVisuals] Script starting") end
local state = ReplicatedStorage:WaitForChild("WeatherState")
local shared = ReplicatedStorage:WaitForChild("Shared")
local definitions = require(shared:WaitForChild("EventDefinitions"))
local meteorShowerEffects = require(shared:WaitForChild("MeteorShowerEffects"))
local spiritNightEffects = require(shared:WaitForChild("SpiritNightEffects"))
local celestialEffects = require(shared:WaitForChild("WeatherCelestialEffects"))
local environmentEffects = require(shared:WaitForChild("WeatherEnvironmentEffects"))
local weatherAudio = require(shared:WaitForChild("WeatherAudioController"))
local qualitySettings = require(shared:WaitForChild("WeatherVFXQuality"))

local function color(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Every event has its own lighting recipe. Particle and sky details are added below.
local presets = {
	SunnySkies = { clock = 13, brightness = 3.2, exposure = 0.16, fog = 100000, atmosphere = 0.1, tint = color(255, 244, 215), saturation = 0.16, bloom = 0.22, rays = 0.11, clouds = 0.06 },
	RainyDay = { clock = 15, brightness = 1.35, exposure = -0.18, fog = 530, atmosphere = 0.47, tint = color(173, 198, 225), saturation = -0.18, bloom = 0.08, rays = 0, clouds = 0.92, particles = "Rain" },
	Thunderstorm = { clock = 18, brightness = 1, exposure = -0.22, fog = 750, fogStart = 0, atmosphere = 0.42, tint = color(118, 145, 183), saturation = -0.32, bloom = 0.15, rays = 0, clouds = 1, particles = "HeavyRain", extraParticles = "WindStreaks", loop = "Lightning" },
	Snowfall = { clock = 11, brightness = 2.1, exposure = 0.02, fog = 440, fogStart = 0, atmosphere = 0.47, tint = color(188, 223, 255), saturation = -0.34, bloom = 0.26, rays = 0.02, clouds = 0.75, particles = "Snow" },
	Foggy = { clock = 10, brightness = 1.45, exposure = -0.1, fog = 190, fogStart = 25, atmosphere = 0.55, tint = color(167, 187, 203), saturation = -0.48, bloom = 0.03, blur = 2, rays = 0, clouds = 0.76 },
	Windy = { clock = 14, brightness = 2, exposure = -0.02, fog = 850, atmosphere = 0.32, tint = color(207, 226, 217), saturation = 0.02, bloom = 0.08, rays = 0.02, clouds = 0.8, particles = "Leaves", extraParticles = "WindStreaks", loop = "Wind" },
	Heatwave = { clock = 14, brightness = 3.35, exposure = 0.28, fog = 480, atmosphere = 0.4, tint = color(255, 206, 145), saturation = 0.19, bloom = 0.38, blur = 0.7, rays = 0.14, clouds = 0.04, particles = "Haze" },
	Aurora = { clock = 0, brightness = 1.1, exposure = -0.12, fog = 100000, atmosphere = 0.15, tint = color(164, 196, 244), saturation = 0.32, bloom = 0.5, rays = 0, clouds = 0.08, particles = "Stars", sky = "Aurora" },
	BloodMoon = { clock = 0, brightness = 0.7, exposure = -0.3, fog = 100000, fogStart = 0, atmosphere = 0.2, tint = color(211, 89, 103), saturation = 0.05, bloom = 0.3, rays = 0, clouds = 0.52, particles = "Ash", sky = "BloodMoon" },
	MeteorShower = { clock = 0, brightness = 1.05, exposure = -0.12, fog = 100000, atmosphere = 0.16, tint = color(159, 180, 237), saturation = 0.2, bloom = 0.45, rays = 0, clouds = 0.03, particles = "Stars", loop = "Meteors" },
	SpiritNight = { clock = 1, brightness = 1.1, exposure = -0.1, fog = 650, atmosphere = 0.30, tint = color(134, 219, 235), saturation = 0.24, bloom = 0.44, rays = 0, clouds = 0.25, particles = "SpiritMist", loop = "Spirits" },
	Rainbow = { clock = 14, brightness = 3.15, exposure = 0.16, fog = 100000, atmosphere = 0.06, tint = color(255, 240, 254), saturation = 0.4, bloom = 0.34, rays = 0.09, clouds = 0.12, particles = "Sparkles", sky = "Rainbow" },
	Chaos = { clock = 19, brightness = 2, exposure = 0.04, fog = 1200, atmosphere = 0.23, tint = color(255, 190, 230), saturation = 0.25, bloom = 0.5, rays = 0, clouds = 0.72, particles = "Chaos", loop = "Chaos" },
	Inverted = { clock = 22, brightness = 1.7, exposure = 0.1, fog = 900, atmosphere = 0.24, tint = color(173, 255, 219), saturation = -0.65, bloom = 0.4, rays = 0, clouds = 0.6, particles = "Inverted" },
	Nightmare = { clock = 0, brightness = 0.95, exposure = -0.22, fog = 380, atmosphere = 0.46, tint = color(166, 77, 127), saturation = -0.36, bloom = 0.25, rays = 0, clouds = 0.84, particles = "Ash", loop = "Nightmare" },
	Void = { clock = 0, brightness = 0.9, exposure = -0.2, fog = 100000, atmosphere = 0.16, tint = color(129, 85, 204), saturation = -0.18, bloom = 0.59, blur = 0, rays = 0, clouds = 0.12, particles = "Void", sky = "Void" },
	Golden = { clock = 16, brightness = 2.8, exposure = 0.13, fog = 1600, atmosphere = 0.18, tint = color(255, 229, 164), saturation = 0.18, bloom = 0.4, rays = 0.16, clouds = 0.1, particles = "Gold" },
	AdminAbuse = { clock = 19, brightness = 2.1, exposure = 0.06, fog = 100000, atmosphere = 0.13, tint = color(255, 198, 247), saturation = 0.38, bloom = 0.52, rays = 0.06, clouds = 0.58, particles = "Admin", loop = "Admin" },
}

-- WeatherState uses the canonical IDs in EventDefinitions. Accept the older
-- underscored spellings as input without changing the server's event contract.
local aliases = {
	Sunny_Skies = "SunnySkies", Rainy_Day = "RainyDay", Blood_Moon = "BloodMoon",
	Meteor_Shower = "MeteorShower", Spirit_Night = "SpiritNight", Admin_Abuse = "AdminAbuse",
}

local lightingProperties = { "Brightness", "ClockTime", "ExposureCompensation", "FogStart", "FogEnd", "FogColor", "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom" }
local effectProperties = {
	Atmosphere = { "Density", "Color", "Decay", "Haze", "Glare", "Offset" },
	Clouds = { "Cover", "Density", "Color", "Enabled" },
	ColorCorrectionEffect = { "Brightness", "Contrast", "Saturation", "TintColor", "Enabled" },
	BloomEffect = { "Intensity", "Size", "Threshold", "Enabled" },
	SunRaysEffect = { "Intensity", "Spread", "Enabled" },
	DepthOfFieldEffect = { "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity", "Enabled" },
	BlurEffect = { "Size", "Enabled" },
}
local originalWind = workspace.GlobalWind
local original = {}
for _, property in ipairs(lightingProperties) do original[property] = Lighting[property] end
-- The folder is a client-local index of managed effects. Roblox renders
-- Atmosphere/post effects under Lighting and Clouds under Terrain, so the live
-- instances cannot be placed inside this folder without disabling them.
local visualFolder = Lighting:FindFirstChild("AK_WeatherVisuals")
if not visualFolder then
	visualFolder = Instance.new("Folder")
	visualFolder.Name = "AK_WeatherVisuals"
	visualFolder.Parent = Lighting
end
local function indexEffect(className, effect)
	local reference = visualFolder:FindFirstChild(className)
	if not reference or not reference:IsA("ObjectValue") then
		reference = Instance.new("ObjectValue")
		reference.Name = className
		reference.Parent = visualFolder
	end
	reference.Value = effect
end
local effects = {}
local initialEffects = {}
local createdEffects = {}
local terrain = workspace.Terrain
local requiredEffects = { "Atmosphere", "ColorCorrectionEffect", "BloomEffect", "BlurEffect", "SunRaysEffect", "Clouds" }
local effectLabels = {
	ColorCorrectionEffect = "ColorCorrection", BloomEffect = "Bloom",
	BlurEffect = "Blur", SunRaysEffect = "SunRays",
}

local function ensureEffect(className, parent)
	local effect = effects[className]
	if effect and effect.Parent == parent then
		if DEBUG_VISUALS then print("[WeatherVisuals] " .. (effectLabels[className] or className) .. " ready") end
		return effect
	end
	effect = parent:FindFirstChildOfClass(className)
	if effect and not initialEffects[className] then
		local snapshot = {}
		for _, property in ipairs(effectProperties[className]) do snapshot[property] = effect[property] end
		initialEffects[className] = snapshot
		createdEffects[className] = nil
	end
	if not effect then
		local ok, result = pcall(Instance.new, className)
		if not ok then
			warn("[WeatherVisuals] Cannot create " .. className .. ": " .. tostring(result))
			return nil
		end
		effect = result
		effect.Name = "AK_Weather" .. className
		if effect:IsA("PostEffect") then effect.Enabled = false end
		if className == "Atmosphere" then
			effect.Density = 0
			effect.Haze = 0
			effect.Glare = 0
		elseif className == "Clouds" then
			effect.Cover = 0
			effect.Enabled = false
		end
		effect.Parent = parent
		createdEffects[className] = true
	end
	effects[className] = effect
	indexEffect(className, effect)
	if DEBUG_VISUALS then print("[WeatherVisuals] " .. (effectLabels[className] or className) .. " ready") end
	return effect
end

-- Capture the real map appearance before any weather instance is created.
for className, properties in pairs(effectProperties) do
	local parent = className == "Clouds" and terrain or Lighting
	local effect = parent:FindFirstChildOfClass(className)
	if effect then
		local snapshot = {}
		for _, property in ipairs(properties) do snapshot[property] = effect[property] end
		initialEffects[className] = snapshot
		effects[className] = effect
		indexEffect(className, effect)
	end
end

local generation = 0
local activeKey
local activeEventId
local runtime
local followConnection
local moduleCleanups = {}
local audioSession
local runningTweens = {}
local refreshQueued = false


local function trackTween(instance, properties, seconds)
	if not instance then
		warn("[WeatherVisuals] Cannot tween a missing visual instance")
		return nil
	end
	local ok, animation = pcall(TweenService.Create, TweenService, instance, TweenInfo.new(seconds or TRANSITION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), properties)
	if not ok then
		warn("[WeatherVisuals] Tween failed for " .. instance.Name .. ": " .. tostring(animation))
		-- Keep the preset visible even if a property cannot be tweened in Studio.
		for property, value in pairs(properties) do
			local setOk, setError = pcall(function() instance[property] = value end)
			if not setOk then warn("[WeatherVisuals] Cannot set " .. instance.Name .. "." .. property .. ": " .. tostring(setError)) end
		end
		return nil
	end
	table.insert(runningTweens, animation)
	animation.Completed:Connect(function()
		local index = table.find(runningTweens, animation)
		if index then table.remove(runningTweens, index) end
	end)
	animation:Play()
	return animation
end

local function cancelTweens()
	-- Cancel may fire Completed synchronously; swap the list first so its
	-- removal callback cannot skip every other active tween.
	local oldTweens = runningTweens
	runningTweens = {}
	for _, animation in ipairs(oldTweens) do animation:Cancel() end
end

local function restoreOriginal(token)
	trackTween(Lighting, original)
	trackTween(workspace, { GlobalWind = originalWind })
	for className, effect in pairs(effects) do
		local snapshot = initialEffects[className]
		if snapshot then
			local numericAndColor = {}
			for property, value in pairs(snapshot) do
				if property ~= "Enabled" then numericAndColor[property] = value end
			end
			trackTween(effect, numericAndColor)
			if snapshot.Enabled ~= nil then
				task.delay(TRANSITION, function()
					if token == generation then effect.Enabled = snapshot.Enabled end
				end)
			end
		else
			-- Newly created effects fade to neutral, then leave Lighting entirely.
			if className == "Atmosphere" then trackTween(effect, { Density = 0, Haze = 0, Glare = 0 }) end
			if className == "Clouds" then trackTween(effect, { Cover = 0 }) end
			if className == "ColorCorrectionEffect" then trackTween(effect, { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }) end
			if className == "BloomEffect" then trackTween(effect, { Intensity = 0 }) end
			if className == "SunRaysEffect" then trackTween(effect, { Intensity = 0 }) end
			if className == "BlurEffect" then trackTween(effect, { Size = 0 }) end
		end
	end
	task.delay(TRANSITION + 0.05, function()
		if token ~= generation then return end
		for className in pairs(createdEffects) do
			local effect = effects[className]
			if effect then effect:Destroy() end
			effects[className] = nil
			indexEffect(className, nil)
		end
	end)
end

local function ensureEffects()
	local ready = true
	for _, className in ipairs(requiredEffects) do
		local parent = className == "Clouds" and terrain or Lighting
		if not ensureEffect(className, parent) then ready = false end
	end
	return ready
end

local function clearEvent(restore)
	generation += 1
	for _, cleanup in ipairs(moduleCleanups) do cleanup() end
	table.clear(moduleCleanups)
	if audioSession then
		if restore then audioSession:StopAudio(1.2) else audioSession:CleanupAudio() end
		audioSession = nil
	end
	cancelTweens()
	if followConnection then followConnection:Disconnect(); followConnection = nil end
	if runtime then runtime:Destroy(); runtime = nil end
	if DEBUG_VISUALS and activeEventId then print("[WeatherVisuals] Clearing previous effects") end
	if DEBUG_VISUALS and activeEventId then print("[WeatherVisuals] Clearing " .. activeEventId) end
	if DEBUG_VISUALS and restore and activeEventId then print("[WeatherVisuals] Restoring defaults") end
	activeKey = nil
	activeEventId = nil
	if restore then restoreOriginal(generation) end
end

local function makePart(name, parent, size, tint, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = tint
	part.Transparency = transparency or 0
	part.Size = size
	part.Parent = parent
	return part
end

local particleStyles = {
	Rain = { rate = 380, speed = NumberRange.new(55, 70), life = NumberRange.new(0.7, 1), size = 0.95, squash = 2.5, color = color(192, 217, 247), spread = 7, acceleration = Vector3.new(3, -55, 0) },
	HeavyRain = { rate = 560, speed = NumberRange.new(75, 95), life = NumberRange.new(0.65, 0.95), size = 1.4, squash = 3, color = color(202, 224, 255), spread = 12, acceleration = Vector3.new(12, -75, 0) },
	Snow = { rate = 210, speed = NumberRange.new(14, 22), life = NumberRange.new(2.2, 3.4), size = 0.42, color = color(244, 250, 255), spread = 35, acceleration = Vector3.new(5, -4, 2) },
	Leaves = { rate = 95, speed = NumberRange.new(35, 55), life = NumberRange.new(1.1, 1.8), size = 0.43, color = color(167, 197, 105), spread = 20, direction = Enum.NormalId.Right, acceleration = Vector3.new(35, 1, 5) },
	WindStreaks = { rate = 105, speed = NumberRange.new(70, 105), life = NumberRange.new(0.55, 0.95), size = 0.38, squash = 2.8, color = color(212, 235, 246), spread = 12, direction = Enum.NormalId.Right, acceleration = Vector3.new(30, 0, 0) },
}

local function addParticles(styleName, rig, context)
	local style = particleStyles[styleName]
	if not style then return end
	local emitter = Instance.new("ParticleEmitter")
	local isRain = styleName == "Rain" or styleName == "HeavyRain"
	emitter.Name = styleName .. "Particles"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.EmissionDirection = style.direction or Enum.NormalId.Bottom
	emitter.Rate = style.rate * context.qualityScale * context.intensity
	emitter.Lifetime = style.life
	emitter.Speed = style.speed
	emitter.SpreadAngle = Vector2.new(style.spread, style.spread)
	emitter.Acceleration = style.acceleration
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, style.size, styleName == "Snow" and 0.2 or 0), NumberSequenceKeypoint.new(1, 0) })
	if isRain then
		-- Keep drops readable through the playable height; fade below the floor.
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, style.size), NumberSequenceKeypoint.new(0.7, style.size), NumberSequenceKeypoint.new(1, 0) })
	end
	if styleName == "Snow" or styleName == "Leaves" then
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-75, 75)
	end
	if style.squash then emitter.Squash = NumberSequence.new(style.squash) end
	if style.squash then emitter.Orientation = Enum.ParticleOrientation.VelocityParallel end
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(0.8, 0.22), NumberSequenceKeypoint.new(1, 1) })
	emitter.Color = ColorSequence.new(style.color)
	emitter.LightEmission = isRain and 0.3 or 0.55
	emitter.LightInfluence = isRain and 0 or 0.15
	emitter.LockedToPart = false
	emitter.Enabled = true
	emitter.Parent = rig
	if DEBUG_VISUALS then print("[WeatherVisuals] Created " .. styleName .. " effect; enabled=" .. tostring(emitter.Enabled) .. " rate=" .. tostring(emitter.Rate)) end
end

local function applyEvent(eventId, key)
	local preset = presets[eventId]
	if not preset or not definitions[eventId] then return end
	clearEvent(false)
	if not ensureEffects() then
		warn("[WeatherVisuals] Preset " .. eventId .. " skipped: required visual effect missing")
		return
	end
	activeKey = key
	activeEventId = eventId
	local token = generation
	if DEBUG_VISUALS then print("[WeatherVisuals] Applying preset: " .. eventId) end
	runtime = Instance.new("Folder")
	runtime.Name = "WeatherWorldEffects"
	runtime:SetAttribute("EventId", eventId)
	runtime.Parent = workspace
	local context = qualitySettings.Resolve()
	context.effects = effects
	runtime:SetAttribute("QualityScale", context.qualityScale)
	runtime:SetAttribute("EventIntensity", context.intensity)
	local startedAt = state:GetAttribute("StartedAt")
	local windSpeed = ({SunnySkies=5,RainyDay=13,Thunderstorm=35,Snowfall=10,Foggy=3,Windy=45,Heatwave=8,Chaos=22,AdminAbuse=30})[eventId] or 5
	trackTween(workspace, { GlobalWind = Vector3.new(windSpeed, 0, windSpeed * 0.25) })
	audioSession = weatherAudio.Start(eventId, startedAt, runtime)
	context.audio = audioSession
	-- Nearby precipitation uses fixed world cells selected by character location.
	-- Turning/tilting the camera never translates or rotates an environmental VFX.
	local updatePrecipitation
	local precipitation = { RainyDay = {"Rain"}, Thunderstorm = {"HeavyRain", "WindStreaks"}, Snowfall = {"Snow"}, Windy = {"Leaves", "WindStreaks"} }
	if precipitation[eventId] then
		local rig = makePart("WeatherEmitterRig", runtime, Vector3.new(76, 2, 76), Color3.new(1,1,1), 1)
		for _, name in ipairs(precipitation[eventId]) do addParticles(name, rig, context) end
		updatePrecipitation = function()
			local player = Players.LocalPlayer
			local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and rig.Parent then
				local p = root.Position
				rig.Position = Vector3.new(math.floor(p.X / 24 + 0.5) * 24, math.floor(p.Y / 12) * 12 + 28, math.floor(p.Z / 24 + 0.5) * 24)
			end
		end
		updatePrecipitation()
	end
	-- One bounded presentation tick for moving clouds and subtle supplemental
	-- pulses. Never moves an environmental object from the camera transform.
	local motionElapsed = 0
	local appliedAt = os.clock()
	followConnection = RunService.Heartbeat:Connect(function(delta)
		motionElapsed += delta
		if motionElapsed < 0.2 then return end
		motionElapsed = 0
		if updatePrecipitation then updatePrecipitation() end
		if os.clock() - appliedAt < TRANSITION then return end
		local age = workspace:GetServerTimeNow() - startedAt
		local gust = 1 + math.sin(age * 0.5) * ((eventId == "Windy" or eventId == "Thunderstorm") and 0.25 or 0.1)
		workspace.GlobalWind = Vector3.new(windSpeed * gust, 0, windSpeed * 0.25)
		if eventId == "Chaos" or eventId == "AdminAbuse" then
			effects.ColorCorrectionEffect.TintColor = Color3.fromHSV((age * 0.025) % 1, eventId == "AdminAbuse" and 0.23 or 0.3, 1)
		elseif eventId == "BloodMoon" then
			Lighting.Brightness = preset.brightness + math.sin(age * 0.5) * 0.06
		elseif eventId == "Nightmare" then
			effects.ColorCorrectionEffect.Brightness = -0.015 * (0.5 + math.sin(age * 0.36) * 0.5)
		elseif eventId == "Heatwave" then
			effects.BlurEffect.Size = 0.55 + math.sin(age * 0.7) * 0.18
		end
	end)
	local tint = preset.tint
	trackTween(Lighting, {
		ClockTime = preset.clock, Brightness = preset.brightness,
		ExposureCompensation = preset.exposure, FogStart = preset.fogStart or math.min(25, preset.fog * 0.1), FogEnd = preset.fog,
		FogColor = tint, Ambient = tint:Lerp(color(85, 92, 111), 0.65),
		OutdoorAmbient = tint:Lerp(color(136, 142, 157), 0.5),
		ColorShift_Top = tint:Lerp(Color3.new(0, 0, 0), 0.72),
		ColorShift_Bottom = tint:Lerp(Color3.new(0, 0, 0), 0.84),
	})
	trackTween(effects.Atmosphere, { Density = preset.atmosphere, Color = tint, Decay = tint:Lerp(color(69, 73, 102), 0.6), Haze = preset.atmosphere * 4, Glare = 0.12 })
	trackTween(effects.Clouds, { Cover = preset.clouds, Density = math.clamp(preset.clouds * 0.8, 0, 1), Color = tint })
	effects.Clouds.Enabled = true
	local correction = effects.ColorCorrectionEffect
	correction.Enabled = true
	trackTween(correction, { Brightness = 0, TintColor = tint, Saturation = preset.saturation, Contrast = (eventId == "Nightmare" or eventId == "BloodMoon" or eventId == "Inverted") and 0.23 or 0.08 })
	local bloom = effects.BloomEffect
	bloom.Enabled = true
	trackTween(bloom, { Intensity = preset.bloom, Size = 24, Threshold = 1.15 })
	local rays = effects.SunRaysEffect
	rays.Enabled = preset.rays > 0
	if rays.Enabled then trackTween(rays, { Intensity = preset.rays, Spread = 0.75 }) end
	local blur = effects.BlurEffect
	blur.Enabled = (preset.blur or 0) > 0
	if blur.Enabled then trackTween(blur, { Size = preset.blur }) end
	if DEBUG_VISUALS then
		print("[WeatherVisuals] FogStart: " .. tostring(preset.fogStart or math.min(25, preset.fog * 0.1)) .. " FogEnd: " .. tostring(preset.fog))
		print("[WeatherVisuals] ClockTime: " .. tostring(preset.clock))
		print("[WeatherVisuals] Atmosphere Density: " .. tostring(preset.atmosphere))
		task.delay(TRANSITION + 0.05, function()
			if token ~= generation then return end
			print("[WeatherVisuals] Applied values: FogStart=" .. tostring(Lighting.FogStart)
				.. " FogEnd=" .. tostring(Lighting.FogEnd)
				.. " ClockTime=" .. tostring(Lighting.ClockTime)
				.. " Atmosphere Density=" .. tostring(effects.Atmosphere.Density))
		end)
	end
	local function isCurrent() return token == generation and runtime ~= nil end
	table.insert(moduleCleanups, celestialEffects.Start(runtime, eventId, startedAt, isCurrent, context))
	table.insert(moduleCleanups, environmentEffects.Start(runtime, eventId, startedAt, isCurrent, context))
	if eventId == "MeteorShower" or eventId == "Chaos" or eventId == "AdminAbuse" then
		context.meteorMode = eventId
		table.insert(moduleCleanups, meteorShowerEffects.Start(runtime, startedAt, isCurrent, context))
	elseif eventId == "SpiritNight" then
		table.insert(moduleCleanups, spiritNightEffects.Start(runtime, startedAt, isCurrent, context))
	end
end

local function refreshFromState()
	local phase = state:GetAttribute("Phase")
	if phase == "Break" then
		if activeKey then clearEvent(true) end
		return
	end
	if phase ~= "Event" then
		if activeKey then clearEvent(true) end
		return
	end
	local id = state:GetAttribute("EventId")
	if type(id) == "string" then id = aliases[id] or id end
	local startedAt = state:GetAttribute("StartedAt")
	local endsAt = state:GetAttribute("EndsAt")
	if type(id) ~= "string" or not definitions[id] or not presets[id]
		or type(startedAt) ~= "number" or type(endsAt) ~= "number"
		or startedAt <= 0 or endsAt <= startedAt or endsAt <= workspace:GetServerTimeNow() then
		if type(id) == "string" and id ~= "" and not definitions[id] and DEBUG_VISUALS then
			warn("[WeatherVisuals] Unknown event: " .. id)
		end
		if activeKey then clearEvent(true) end
		return
	end
	local key = id .. ":" .. tostring(startedAt)
	if key ~= activeKey then applyEvent(id, key) end
end

state.AttributeChanged:Connect(function(attribute)
	if attribute ~= "Phase" and attribute ~= "EventId" and attribute ~= "StartedAt" and attribute ~= "EndsAt" then return end
	if refreshQueued then return end
	refreshQueued = true
	task.defer(function()
		refreshQueued = false
		refreshFromState()
	end)
end)
refreshFromState()
if DEBUG_VISUALS then print("[WeatherVisuals] Initialized") end
