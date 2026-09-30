-- Run once in a fresh Studio CLIENT Command Bar, with at least 125 seconds
-- remaining in the production Break. This is local presentation injection;
-- it sends no remotes, changes no server state, and never moves the avatar.
-- Expected duration: about 112 seconds. Output prefix: AK_POLISH_EXT_.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Fresh Studio CLIENT required")

task.spawn(function()
	local state = game:GetService("ReplicatedStorage"):WaitForChild("WeatherState", 10)
	assert(state, "WeatherState missing")
	assert(state:GetAttribute("Phase") == "Break", "Start in a fresh production Break")
	assert((state:GetAttribute("BreakEndsAt") or 0) - workspace:GetServerTimeNow() >= 125, "Restart Play: need at least 125 seconds of Break remaining")
	assert(workspace:FindFirstChild("WeatherWorldEffects") == nil, "Wait for prior weather cleanup before running")
	local Players, Lighting = game:GetService("Players"), game:GetService("Lighting")
	local SoundService, HttpService = game:GetService("SoundService"), game:GetService("HttpService")
	local player, camera = Players.LocalPlayer, workspace.CurrentCamera
	assert(player and camera, "Local player/camera unavailable")
	local originalCamera = {CFrame = camera.CFrame, Focus = camera.Focus, Type = camera.CameraType}
	local originalQuality = player:GetAttribute("WeatherVFXQuality")
	local originalIntensity = player:GetAttribute("WeatherEventIntensity")
	local originalState = state:GetAttributes()
	local originalWind = workspace.GlobalWind
	local began, assertions, failures = os.clock(), 0, 0
	local connections, activeFrames = {}, nil
	local LIGHTING_PROPERTIES = {"Brightness", "ClockTime", "ExposureCompensation", "FogStart", "FogEnd", "FogColor", "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom"}
	local EFFECT_PROPERTIES = {
		Atmosphere = {"Density", "Color", "Decay", "Haze", "Glare", "Offset"},
		Clouds = {"Cover", "Density", "Color", "Enabled"},
		ColorCorrectionEffect = {"Brightness", "Contrast", "Saturation", "TintColor", "Enabled"},
		BloomEffect = {"Intensity", "Size", "Threshold", "Enabled"},
		SunRaysEffect = {"Intensity", "Spread", "Enabled"},
		BlurEffect = {"Size", "Enabled"},
		DepthOfFieldEffect = {"FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity", "Enabled"},
		Sky = {"MoonAngularSize"},
	}
	local originalLighting, originalEffects = {}, {}
	for _, property in ipairs(LIGHTING_PROPERTIES) do originalLighting[property] = Lighting[property] end
	for _, parent in ipairs({Lighting, workspace.Terrain}) do
		for _, object in ipairs(parent:GetChildren()) do
			local properties = EFFECT_PROPERTIES[object.ClassName]
			if properties then
				local saved = {Parent = parent, Properties = {}}
				for _, property in ipairs(properties) do saved.Properties[property] = object[property] end
				originalEffects[object] = saved
			end
		end
	end
	local function check(ok, message)
		assertions += 1
		if not ok then failures += 1 end
		print("AK_POLISH_EXT_" .. (ok and "PASS " or "FAIL ") .. message)
	end
	local function connect(signal, callback)
		local connection = signal:Connect(callback)
		table.insert(connections, connection)
		return connection
	end
	local function waitBounded(seconds)
		assert(os.clock() - began + seconds < 116, "116-second sampling deadline; stopping before production weather can change")
		task.wait(seconds)
	end
	local function phase(id)
		local now = workspace:GetServerTimeNow()
		state:SetAttribute("Phase", "Break")
		state:SetAttribute("EventId", id or "")
		state:SetAttribute("StartedAt", now)
		state:SetAttribute("EndsAt", now + (id and 420 or 300))
		state:SetAttribute("Phase", id and "Event" or "Break")
	end
	local function near(a, b)
		if typeof(a) == "number" then return math.abs(a - b) < 0.03 end
		if typeof(a) == "Color3" then return math.abs(a.R-b.R) < 0.003 and math.abs(a.G-b.G) < 0.003 and math.abs(a.B-b.B) < 0.003 end
		return a == b
	end
	local function baseline(id)
		local lightingOK, effectsOK = true, true
		for property, value in pairs(originalLighting) do lightingOK = lightingOK and near(Lighting[property], value) end
		for object, saved in pairs(originalEffects) do
			effectsOK = effectsOK and object.Parent == saved.Parent
			if object.Parent then
				for property, value in pairs(saved.Properties) do effectsOK = effectsOK and near(object[property], value) end
			end
		end
		for _, parent in ipairs({Lighting, workspace.Terrain}) do
			for _, object in ipairs(parent:GetChildren()) do
				if EFFECT_PROPERTIES[object.ClassName] and not originalEffects[object] then effectsOK = false end
			end
		end
		check(lightingOK, id .. " restores original Lighting properties")
		check(effectsOK, id .. " restores original effects/Sky and removes temporary effects")
		check((workspace.GlobalWind-originalWind).Magnitude < 0.05, id .. " restores original GlobalWind")
	end
	local function endEvent(id, observed)
		phase(nil)
		waitBounded(2.4)
		check(workspace:FindFirstChild("WeatherWorldEffects") == nil, id .. " removes world/meteor/environment/celestial containers")
		check(SoundService:FindFirstChild("AK_WeatherAudio") == nil, id .. " removes all weather audio after fade")
		if observed then
			local removed = true
			for object in pairs(observed) do removed = removed and object.Parent == nil end
			check(removed, id .. " destroys every observed temporary actor and voice")
		end
		baseline(id)
	end
	local function startEvent(id)
		phase(id)
		local start = os.clock()
		local runtime
		repeat
			waitBounded(0.03)
			runtime = workspace:FindFirstChild("WeatherWorldEffects")
		until (runtime and runtime:GetAttribute("EventId") == id) or os.clock()-start > 2
		check(runtime ~= nil and runtime:GetAttribute("EventId") == id, id .. " starts actual visual controller")
		assert(runtime and runtime:GetAttribute("EventId") == id, id .. " runtime missing")
		check(runtime:GetAttribute("QualityScale") == 1, id .. " uses High quality for budget checks")
		return runtime
	end
	local function sceneQueries(runtime, id)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		assert(root, "Player root missing during scene query")
		local query = RaycastParams.new()
		query.FilterType = Enum.RaycastFilterType.Exclude
		local excluded = {}
		for _, other in ipairs(Players:GetPlayers()) do if other.Character then table.insert(excluded, other.Character) end end
		query.FilterDescendantsInstances = excluded -- Deliberately do not exclude weather.
		query.RespectCanCollide = false
		local safe, hits = true, 0
		for _, offset in ipairs({Vector3.zero, Vector3.new(5,0,0), Vector3.new(-5,0,0), Vector3.new(0,0,5), Vector3.new(0,0,-5)}) do
			local hit = workspace:Raycast(root.Position + offset + Vector3.new(0, 40, 0), Vector3.new(0,-100,0), query)
			if hit then hits += 1; safe = safe and not hit.Instance:IsDescendantOf(runtime) end
		end
		check(safe and hits > 0, id .. " ordinary scene raycasts reach the map without hitting cosmetics")
	end
	connect(RunService.Heartbeat, function(dt)
		if activeFrames then
			activeFrames.frames += 1; activeFrames.seconds += dt
			activeFrames.maxDt = math.max(activeFrames.maxDt, dt)
			if dt > 1/30 then activeFrames.slowFrames += 1 end
		end
	end)
	local function observeTimed(id, duration)
		local runtime = startEvent(id)
		local environment = runtime:FindFirstChild("WeatherEnvironment")
		assert(environment, id .. " WeatherEnvironment missing")
		check(environment:GetAttribute("WorldSpace") == true, id .. " environment is world space")
		if id ~= "Thunderstorm" then check(runtime:FindFirstChild("MeteorShowerEffects") ~= nil, id .. " includes meteor combination") end
		local parts, sounds, emitters, allObserved = {}, {}, {}, {}
		local strikePositions, stages, stageHistory = {}, {}, {}
		local currentParts, currentSounds, peakParts, peakSounds, strikes, thunderVoices = 0, 0, 0, 0, 0, 0
		local safeParts, positionalAudio, fixedStrikes = true, true, true
		local rainOn, rainOff, snowOn, snowOff, correctCycle = false, false, false, false, true
		local lastStage
		local runConnections = {}
		local function add(object)
			if object:IsA("BasePart") and not parts[object] then
				parts[object] = true; allObserved[object] = true; currentParts += 1
				peakParts = math.max(peakParts, currentParts)
				safeParts = safeParts and object.Anchored and not object.CanCollide and not object.CanTouch and not object.CanQuery
				if object.Name == "WorldLightning" then
					strikes += 1
					-- Read after the builder has installed StrikePosition and BoltNodes.
					task.defer(function()
						if object.Parent then
							strikePositions[object] = object.Position
							fixedStrikes = fixedStrikes and object:GetAttribute("StrikePosition") == object.Position
							local bolts = 0
							for _, child in ipairs(object:GetChildren()) do if child:IsA("Beam") and child.Name == "LightningBolt" then bolts += 1 end end
							fixedStrikes = fixedStrikes and bolts >= 2
							print("AK_POLISH_EXT_ACTOR " .. id .. " WorldLightning " .. tostring(object.Position))
						end
					end)
				end
			elseif object:IsA("Sound") and not sounds[object] then
				sounds[object] = true; allObserved[object] = true; currentSounds += 1
				peakSounds = math.max(peakSounds, currentSounds)
				if object:IsDescendantOf(runtime) then
					local parent = object.Parent
					positionalAudio = positionalAudio and parent ~= nil and (parent:IsA("BasePart") or parent:IsA("Attachment")) and parent:IsDescendantOf(workspace)
					if object.Name == "ThunderStrike" or object.Name == "ThunderDistant" then thunderVoices += 1 end
				end
			elseif object:IsA("ParticleEmitter") then emitters[object] = true end
		end
		local function remove(object)
			if parts[object] then parts[object] = nil; currentParts -= 1 end
			if sounds[object] then sounds[object] = nil; currentSounds -= 1 end
			emitters[object] = nil
		end
		local audio = SoundService:FindFirstChild("AK_WeatherAudio")
		assert(audio, id .. " audio session missing")
		for _, container in ipairs({runtime, audio}) do
			table.insert(runConnections, connect(container.DescendantAdded, add))
			table.insert(runConnections, connect(container.DescendantRemoving, remove))
			for _, object in ipairs(container:GetDescendants()) do add(object) end
		end
		local frames = {frames=0, seconds=0, maxDt=0, slowFrames=0}
		activeFrames = frames
		print("AK_POLISH_EXT_FIRST " .. id .. " " .. HttpService:JSONEncode({parts=currentParts,sounds=currentSounds,observeSeconds=duration}))
		print("AK_POLISH_EXT_CAPTURE " .. id)
		local untilTime = os.clock() + duration
		while os.clock() < untilTime do
			assert(runtime.Parent and state:GetAttribute("EventId") == id, "Event changed externally during " .. id)
			local stage = environment:GetAttribute("CombinationStage")
			if stage ~= nil then
				stages[stage] = true
				if stage ~= lastStage then
					table.insert(stageHistory, stage); lastStage = stage
					print("AK_POLISH_EXT_STAGE " .. id .. " " .. tostring(stage))
				end
			end
			for emitter in pairs(emitters) do
				if emitter.Name == "RealityRain" then
					rainOn = rainOn or emitter.Enabled; rainOff = rainOff or not emitter.Enabled
					if stage ~= nil then correctCycle = correctCycle and emitter.Enabled == (stage == 0) end
				elseif emitter.Name == "RealitySnow" then
					snowOn = snowOn or emitter.Enabled; snowOff = snowOff or not emitter.Enabled
					if stage ~= nil then correctCycle = correctCycle and emitter.Enabled == (stage == 2) end
				end
			end
			for object, position in pairs(strikePositions) do if object.Parent then fixedStrikes = fixedStrikes and (object.Position-position).Magnitude < 0.01 end end
			waitBounded(math.min(0.15, math.max(0.001, untilTime-os.clock())))
		end
		activeFrames = nil
		check(peakParts <= 320 and peakSounds <= 11, id .. " peak budgets parts=" .. peakParts .. " sounds=" .. peakSounds)
		check(safeParts, id .. " every observed cosmetic is anchored/noncollidable/nontouchable/nonqueryable")
		check(positionalAudio, id .. " all world sounds have positional Workspace parents")
		if id == "Thunderstorm" then
			check(strikes >= 2 and fixedStrikes, "Thunderstorm produces at least two fixed world lightning strikes; observed=" .. strikes)
			check(thunderVoices >= 1, "Thunderstorm produces positional thunder sound instances; observed=" .. thunderVoices)
		else
			check(stages[0] and stages[1] and stages[2] and stages[3], id .. " visits all four CombinationStage values")
			check(rainOn and rainOff and snowOn and snowOff and correctCycle, id .. " rain/snow turn on and off at their matching stages")
		end
		sceneQueries(runtime, id)
		print("AK_POLISH_EXT_LAST " .. id .. " " .. HttpService:JSONEncode({parts=currentParts,sounds=currentSounds,peakParts=peakParts,peakSounds=peakSounds,strikes=strikes,thunderVoices=thunderVoices,stages=stageHistory,heartbeatFrames=frames.frames,heartbeatMeanHz=frames.frames/math.max(frames.seconds,0.001),maxHeartbeatSeconds=frames.maxDt,over33msFrames=frames.slowFrames}))
		endEvent(id, allObserved)
		for _, connection in ipairs(runConnections) do connection:Disconnect() end
	end
	local function checkCelestial(id, names)
		local runtime = startEvent(id)
		waitBounded(1.8)
		local anchors, billboardSizes = {}, {}
		for _, object in ipairs(runtime:GetDescendants()) do
			if object:IsA("BasePart") and typeof(object:GetAttribute("FixedWorldPosition")) == "Vector3" then anchors[object] = object.Position end
			if object:IsA("BillboardGui") then billboardSizes[object] = object.Size end
		end
		local eye = Vector3.new(-430, 25, 385)
		for _, name in ipairs(names) do
			local anchor = runtime:FindFirstChild(name, true)
			check(anchor ~= nil and anchor:IsA("BasePart") and anchors[anchor] ~= nil, id .. " fixed anchor " .. name .. " exists")
			assert(anchor and anchor:IsA("BasePart"), "Missing celestial " .. name)
			local target = anchor.Position
			if id == "Rainbow" then
				local apex = anchor:FindFirstChild("Top1")
				assert(apex and apex:IsA("Attachment"), "Rainbow arc apex missing")
				target = apex.WorldPosition
			else
				local billboard = anchor:FindFirstChildWhichIsA("BillboardGui")
				check(billboard ~= nil, name .. " uses a world BillboardGui")
				if billboard then
					local size = billboard.Size
					check(billboard.Adornee == anchor and not billboard.AlwaysOnTop and size.X.Scale > 0 and size.Y.Scale > 0 and size.X.Offset == 0 and size.Y.Offset == 0, name .. " billboard has stud dimensions, world adornee and scene occlusion")
					print("AK_POLISH_EXT_BILLBOARD " .. name .. " studs=" .. size.X.Scale .. "x" .. size.Y.Scale)
				end
			end
			camera.CFrame = CFrame.lookAt(eye, target)
			local projected, onScreen = camera:WorldToViewportPoint(target)
			check(onScreen and projected.Z > 0, name .. " projects into view when facing its fixed world location")
			print("AK_POLISH_EXT_CAPTURE " .. id .. " " .. name)
			waitBounded(0.08)
			camera.CFrame = CFrame.lookAt(eye, eye - (target-eye))
			local away, visibleAway = camera:WorldToViewportPoint(target)
			check(not visibleAway and away.Z < 0, name .. " leaves view when camera turns away")
		end
		for step = 0, 8 do
			camera.CFrame = CFrame.new(eye) * CFrame.Angles(0, step * math.pi/4, 0)
			waitBounded(0.025)
		end
		camera.CFrame = CFrame.lookAt(eye+Vector3.new(75,20,65), eye+Vector3.new(0,0,-1000))
		waitBounded(0.06)
		local fixed, sizesFixed, safe = true, true, true
		for anchor, position in pairs(anchors) do fixed = fixed and anchor.Parent ~= nil and (anchor.Position-position).Magnitude < 0.01 and (anchor.Position-anchor:GetAttribute("FixedWorldPosition")).Magnitude < 0.01 end
		for gui, size in pairs(billboardSizes) do sizesFixed = sizesFixed and gui.Parent ~= nil and gui.Size == size end
		for _, object in ipairs(runtime:GetDescendants()) do if object:IsA("BasePart") then safe = safe and object.Anchored and not object.CanCollide and not object.CanTouch and not object.CanQuery end end
		check(fixed and sizesFixed, id .. " centers and billboard stud sizes stay fixed through 360-degree camera rotation/translation")
		check(safe, id .. " celestial actors remain noninteractive")
		sceneQueries(runtime, id)
		endEvent(id)
	end
	local ok, err = xpcall(function()
		player:SetAttribute("WeatherVFXQuality", "High")
		player:SetAttribute("WeatherEventIntensity", 1)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(Vector3.new(-430,25,385), Vector3.new(-338,230,-400))
		print("AK_POLISH_EXT_BEGIN local presentation only; Heartbeat samples are diagnostic, not a device/server benchmark")
		observeTimed("Thunderstorm", 20)
		observeTimed("Chaos", 35)
		observeTimed("AdminAbuse", 35)
		checkCelestial("BloodMoon", {"BloodMoonAnchor"})
		checkCelestial("Rainbow", {"RainbowAnchor"})
		checkCelestial("Void", {"VoidPlanetAnchor", "VoidMoonAnchor"})
	end, debug.traceback)
	if not ok then check(false, tostring(err)) end
	activeFrames = nil
	for _, connection in ipairs(connections) do connection:Disconnect() end
	-- Finally path also runs after assertion/runtime failure. Let the controller
	-- restore its own world/Lighting/audio ownership before restoring saved state.
	phase(nil)
	task.wait(2.4)
	baseline("final restoration")
	check(workspace:FindFirstChild("WeatherWorldEffects") == nil and SoundService:FindFirstChild("AK_WeatherAudio") == nil, "final restoration leaves no weather world/audio containers")
	player:SetAttribute("WeatherVFXQuality", originalQuality)
	player:SetAttribute("WeatherEventIntensity", originalIntensity)
	if camera.Parent then camera.CameraType = originalCamera.Type; camera.CFrame = originalCamera.CFrame; camera.Focus = originalCamera.Focus end
	for _, key in ipairs({"EventId", "StartedAt", "EndsAt"}) do state:SetAttribute(key, originalState[key]) end
	state:SetAttribute("Phase", originalState.Phase)
	check(os.clock()-began < 120, "test and restoration finish within 120 seconds")
	print("AK_POLISH_EXT_DONE assertions=" .. assertions .. " failures=" .. failures .. " elapsed=" .. string.format("%.2f", os.clock()-began))
end)
