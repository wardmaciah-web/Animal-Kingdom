-- Client-local weather mixer. Server weather state remains entirely unchanged.
-- Positional cues are called by the VFX that actually produced them.
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Definitions = require(script.Parent:WaitForChild("WeatherSoundDefinitions"))

local Audio = {}
local Session = {}
Session.__index = Session
local activeSession
local missingReported = {}
local unavailableAssets = {}

local function cycleEnabled(elapsed, cycle)
	-- {period, active duration, offset, active during the initial lead-in}.
	-- WeatherEnvironmentEffects starts its four-stage sequence after two seconds.
	if elapsed < cycle[3] then return cycle[4] == true end
	return (elapsed - cycle[3]) % cycle[1] < cycle[2]
end

local function folder(name, parent)
	local object = Instance.new("Folder")
	object.Name = name
	object.Parent = parent
	return object
end

local function assetFor(names, random)
	local candidates = {}
	local used = {}
	for _, name in ipairs(names or {}) do
		local visited = {}
		local resolved = name
		while resolved and not visited[resolved] do
			visited[resolved] = true
			local asset = Definitions.Assets[resolved]
			if not asset then break end
			if asset.SoundId ~= "" then
				if not unavailableAssets[asset.SoundId] and not used[asset.SoundId] then
					used[asset.SoundId] = true
					table.insert(candidates, { Name = resolved, Id = asset.SoundId, Requested = name })
				end
				break
			end
			resolved = asset.Fallback
		end
	end
	if #candidates == 0 then return nil end
	return candidates[random:NextInteger(1, #candidates)]
end

local function positionOf(target)
	if typeof(target) == "Vector3" then return target end
	if typeof(target) == "Instance" and target:IsA("BasePart") and target.Parent then return target.Position end
	if typeof(target) == "Instance" and target:IsA("Attachment") and target.Parent then return target.WorldPosition end
	return nil
end

local function toneFor(sound, name)
	local recipe = Definitions.Tones[name]
	if not recipe then return end
	local equalizer = Instance.new("EqualizerSoundEffect")
	equalizer.Name = "WeatherTone"
	equalizer.LowGain = recipe.Low
	equalizer.MidGain = recipe.Mid
	equalizer.HighGain = recipe.High
	equalizer.Parent = sound
end

function Session:_fade(voice, volume, seconds)
	if voice.Tween then voice.Tween:Cancel(); voice.Tween = nil end
	if not voice.Sound.Parent then return end
	if seconds <= 0 then voice.Sound.Volume = volume; return end
	voice.Tween = TweenService:Create(voice.Sound, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Volume = volume })
	voice.Tween:Play()
end

function Session:_release(voice)
	if voice.Released then return end
	voice.Released = true
	if voice.Connection then voice.Connection:Disconnect(); voice.Connection = nil end
	if voice.Tween then voice.Tween:Cancel(); voice.Tween = nil end
	self.Voices[voice] = nil
	if voice.IsLayer then
		self.LoopCount = math.max(0, self.LoopCount - 1)
		self.LoopIds[voice.AssetId] = nil
	else
		self.OneShotCount = math.max(0, self.OneShotCount - 1)
	end
	voice.Sound:Stop()
	voice.Sound:Destroy()
	if voice.Anchor then voice.Anchor:Destroy() end
end

function Session:_voice(asset, recipe, target, options, isLayer)
	if self.Dead or (self.Stopping and not options.ExitCue) then return nil end
	if self.LoopCount + self.OneShotCount >= Definitions.Mix.MaxVoices then return nil end
	if isLayer then
		if self.LoopCount >= Definitions.Mix.MaxLoops or self.LoopIds[asset.Id] then return nil end
	elseif self.OneShotCount >= Definitions.Mix.MaxOneShots then
		return nil
	end
	local category = recipe.Category or "Ambience"
	local anchor
	local parent = self.Categories[category]
	local position = positionOf(target)
	-- Never turn an invalid positional sound into a centered global sound.
	if recipe.MinDistance and not position then return nil end
	if position then
		if typeof(target) == "Instance" then
			parent = target
		else
			anchor = Instance.new("Part")
			anchor.Name = options.Name or "WeatherSoundAnchor"
			anchor.Anchored = true
			anchor.CanCollide = false
			anchor.CanTouch = false
			anchor.CanQuery = false
			anchor.CastShadow = false
			anchor.Transparency = 1
			anchor.Size = Vector3.new(0.1, 0.1, 0.1)
			anchor.Position = position
			anchor:SetAttribute("AudioCategory", category)
			anchor.Parent = self.WorldCategories[category]
			parent = anchor
		end
	end
	local sound = Instance.new("Sound")
	sound.Name = options.Name or recipe.Name or asset.Requested
	sound.SoundId = asset.Id
	sound.SoundGroup = self.MixGroup
	sound.Volume = 0
	sound.Looped = isLayer or recipe.Repeat == true
	sound.PlaybackSpeed = isLayer and 1 or self.Random:NextNumber(0.94, 1.06)
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = recipe.MinDistance or 20
	sound.RollOffMaxDistance = recipe.MaxDistance or 450
	sound:SetAttribute("WeatherEventId", self.EventId)
	sound:SetAttribute("AudioCategory", category)
	sound:SetAttribute("RequestedAsset", asset.Requested)
	sound:SetAttribute("ResolvedAsset", asset.Name)
	toneFor(sound, recipe.Tone)
	sound.Parent = parent
	local now = os.clock()
	local volume = math.clamp((recipe.Volume or 0.1) * (options.VolumeScale or 1), 0, 0.7)
	local voice = {
		Sound = sound, Anchor = anchor, IsLayer = isLayer, AssetId = asset.Id,
		TargetVolume = volume, Birth = now, Recipe = recipe, CheckedLoad = false,
		Expires = not isLayer and now + math.clamp(options.Duration or recipe.Duration or 12, 0.2, 20) or nil,
	}
	self.Voices[voice] = true
	if isLayer then
		self.LoopCount += 1
		self.LoopIds[asset.Id] = true
	else
		self.OneShotCount += 1
	end
	voice.Connection = sound.Ended:Connect(function() self:_release(voice) end)
	sound:Play()
	local initialVolume = volume
	if isLayer and recipe.Cycle then
		local cycle = recipe.Cycle
		local elapsed = math.max(0, workspace:GetServerTimeNow() - self.StartedAt)
			voice.CycleOn = cycleEnabled(elapsed, cycle)
		initialVolume = voice.CycleOn and volume or 0
	end
	self:_fade(voice, initialVolume, isLayer and Definitions.Mix.FadeIn or 0.06)
	return sound
end

function Session:_play(cueName, target, options)
	local recipe = Definitions.Cues[cueName]
	if not recipe then return nil end
	local asset = assetFor(recipe.Assets, self.Random)
	if not asset then return nil end
	options.Name = cueName
	local sound = self:_voice(asset, recipe, target, options, false)
	if sound and recipe.Followups then
		for _, nextCue in ipairs(recipe.Followups) do
			self:PlayCue(nextCue, target, { Delay = 0.08, VolumeScale = options.VolumeScale or 1 })
		end
	end
	return sound
end

-- Supported cue names are in WeatherSoundDefinitions.Cues. A Vector3 creates
-- a fixed anchor; a BasePart/Attachment attaches the sound to that moving VFX.
-- Options: VolumeScale (0..safe mix cap), Duration (<=20), Delay (seconds).
function Session:PlayCue(cueName, target, options)
	if self.Dead or self.Stopping then return nil end
	local recipe = Definitions.Cues[cueName]
	if not recipe then return nil end
	if not assetFor(recipe.Assets, self.Random) then return nil end
	options = table.clone(options or {})
	local now = os.clock()
	if now < (self.Cooldowns[cueName] or 0) then return nil end
	local position = positionOf(target)
	if recipe.MinDistance and not position then return nil end
	local delay = options.Delay or 0
	if options.Delay == nil and (cueName == "ThunderStrike" or cueName == "ThunderDistant") and position then
		local camera = workspace.CurrentCamera
		-- Camera is read only to approximate the listener's acoustic distance.
		-- No world audio or world visual object is positioned from this camera.
		if camera then delay = math.clamp((camera.CFrame.Position - position).Magnitude / 1100, 0.05, 2.5) end
	end
	if delay > 0 then
		if #self.Pending >= Definitions.Mix.MaxPendingCues then return nil end
		self.Cooldowns[cueName] = now + (recipe.Cooldown or 1)
		table.insert(self.Pending, { At = now + math.min(delay, 5), Cue = cueName, Target = target, Options = options })
		return nil
	end
	local sound = self:_play(cueName, target, options)
	if sound then self.Cooldowns[cueName] = now + (recipe.Cooldown or 1) end
	return sound
end

function Session:_update()
	if self.Dead then return end
	local now = os.clock()
	if self.Stopping then
		if now >= self.StopAt then self:CleanupAudio() end
		return
	end
	if not self.Runtime.Parent then self:CleanupAudio(); return end
	for i = #self.Pending, 1, -1 do
		local pending = self.Pending[i]
		if now >= pending.At then
			table.remove(self.Pending, i)
			self:_play(pending.Cue, pending.Target, pending.Options)
		end
	end
	local elapsed = math.max(0, workspace:GetServerTimeNow() - self.StartedAt)
	local release = {}
	for voice in pairs(self.Voices) do
		if not voice.Sound.Parent or (voice.Expires and now >= voice.Expires) then
			table.insert(release, voice)
		else
			if not voice.CheckedLoad and now - voice.Birth > 8 then
				voice.CheckedLoad = true
				if not voice.Sound.IsLoaded then
					if not unavailableAssets[voice.AssetId] and RunService:IsStudio() then
						warn("[WeatherAudio] Unavailable audio skipped: " .. voice.AssetId .. ". Assign an experience-permitted asset in WeatherSoundDefinitions.")
					end
					unavailableAssets[voice.AssetId] = true
					table.insert(release, voice)
				end
			end
			local cycle = voice.IsLayer and voice.Recipe.Cycle
			if cycle then
				local on = cycleEnabled(elapsed, cycle)
				if on ~= voice.CycleOn then
					voice.CycleOn = on
					self:_fade(voice, on and voice.TargetVolume or 0, 1.8)
				end
			end
		end
	end
	for _, voice in ipairs(release) do self:_release(voice) end
	if now >= self.NextAmbient then
		local cues = self.Profile.AmbientCues
		if cues and #cues > 0 then self:PlayCue(cues[self.Random:NextInteger(1, #cues)]) end
		local interval = self.Profile.AmbientInterval or { 18, 32 }
		self.NextAmbient = now + self.Random:NextNumber(interval[1], interval[2])
	end
end

function Session:StopAudio(fadeSeconds)
	if self.Dead or self.Stopping then return end
	local fade = math.clamp(fadeSeconds or Definitions.Mix.FadeOut, 0, 3)
	self.Stopping = true
	self.Pending = {}
	self.StopAt = os.clock() + fade
	if fade <= 0 then self:CleanupAudio(); return end
	for voice in pairs(self.Voices) do self:_fade(voice, 0, fade) end
	-- This optional exit cue is owned by this session and removed at the same
	-- deadline. Starting the next event immediately clears this whole session.
	self:_play("End", nil, { ExitCue = true, Duration = fade, VolumeScale = 0.65 })
end

function Session:CleanupAudio()
	if self.Dead then return end
	self.Dead = true
	self.Stopping = true
	self.Pending = {}
	if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
	local voices = {}
	for voice in pairs(self.Voices) do table.insert(voices, voice) end
	for _, voice in ipairs(voices) do self:_release(voice) end
	self.WorldFolder:Destroy()
	self.Root:Destroy()
	if activeSession == self then activeSession = nil end
end

function Session:GetStats()
	return { Loops = self.LoopCount, OneShots = self.OneShotCount, Pending = #self.Pending,
		Dead = self.Dead, Stopping = self.Stopping == true, EventId = self.EventId }
end

function Audio.Start(eventId, startedAt, runtime)
	assert(RunService:IsClient(), "WeatherAudioController is client presentation only")
	assert(typeof(runtime) == "Instance", "Weather audio requires the current event runtime container")
	if activeSession then activeSession:CleanupAudio() end
	local stale = SoundService:FindFirstChild("AK_WeatherAudio")
	if stale then stale:Destroy() end
	local self = setmetatable({}, Session)
	self.EventId = eventId
	self.StartedAt = type(startedAt) == "number" and startedAt > 0 and startedAt or workspace:GetServerTimeNow()
	self.Profile = Definitions.Events[eventId] or { Layers = {} }
	self.Runtime = runtime
	self.Random = Random.new()
	self.Root = folder("AK_WeatherAudio", SoundService)
	self.Root:SetAttribute("WeatherEventId", eventId)
	self.Root:SetAttribute("StartedAt", self.StartedAt)
	self.EventFolder = folder(eventId, self.Root)
	self.WorldFolder = folder("EventAudio", runtime)
	self.MixGroup = Instance.new("SoundGroup")
	self.MixGroup.Name = "WeatherMix"
	self.MixGroup.Volume = Definitions.Mix.MasterVolume
	self.MixGroup.Parent = self.Root
	self.Categories = {}
	self.WorldCategories = {}
	for _, category in ipairs(Definitions.Categories) do
		self.Categories[category] = folder(category, self.EventFolder)
		self.WorldCategories[category] = folder(category, self.WorldFolder)
	end
	self.Voices = {}
	self.LoopIds = {}
	self.Pending = {}
	self.Cooldowns = {}
	self.LoopCount = 0
	self.OneShotCount = 0
	self.NextAmbient = os.clock() + self.Random:NextNumber(12, 20)
	activeSession = self
	for _, recipe in ipairs(self.Profile.Layers) do
		local asset = assetFor(recipe.Assets, self.Random)
		if asset then self:_voice(asset, recipe, nil, {}, true) end
	end
	if self.Profile.StartCue then self:PlayCue(self.Profile.StartCue) end
	if RunService:IsStudio() and not missingReported[eventId] then
		missingReported[eventId] = true
		local missing = Definitions.GetMissingAssets()
		if #missing > 0 then
			print("[WeatherAudio] " .. eventId .. ": configured mix active; " .. #missing .. " upload slots remain unassigned. See WeatherSoundDefinitions / AUDIO-MANIFEST.md.")
		end
	end
	local accumulator = 0
	self.Connection = RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < Definitions.Mix.UpdateInterval then return end
		accumulator = 0
		self:_update()
	end)
	return self
end

Audio.StartAudio = Audio.Start
Audio.Definitions = Definitions
return Audio
