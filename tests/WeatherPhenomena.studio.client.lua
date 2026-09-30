-- CLIENT Command Bar, fresh Studio Play session during the production Break.
-- Exercises the real controllers for about 50 seconds without changing server weather.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Studio client required")
task.spawn(function()
	local state = game:GetService("ReplicatedStorage"):WaitForChild("WeatherState")
	assert(state:GetAttribute("Phase") == "Break", "Run during the initial production Break")
	local savedState = state:GetAttributes()
	local camera = workspace.CurrentCamera
	local savedCamera, savedType, savedSubject = camera.CFrame, camera.CameraType, camera.CameraSubject
	local failures, assertions = 0, 0
	local connections = {}
	local function check(ok, message)
		assertions += 1
		if not ok then failures += 1 end
		print("AK_PHENOMENA " .. (ok and "PASS " or "FAIL ") .. message)
	end
	local function phase(id)
		local now = workspace:GetServerTimeNow()
		state:SetAttribute("EventId", id or "")
		state:SetAttribute("StartedAt", id and now or 0)
		state:SetAttribute("EndsAt", id and now + 420 or 0)
		state:SetAttribute("Phase", id and "Event" or "Break")
		return now
	end
	local function waitFor(callback, seconds)
		local deadline = os.clock() + seconds
		repeat
			local value = callback()
			if value then return value end
			task.wait(0.05)
		until os.clock() >= deadline
		return nil
	end
	local function safeEffects(folder)
		for _, object in ipairs(folder:GetDescendants()) do
			if object:IsA("BasePart") and (not object.Anchored or object.CanCollide or object.CanTouch or object.CanQuery) then return false end
		end
		return true
	end
	-- One bounded map scan captures real authored floors, including plot floors.
	local floorProperties = { "CFrame", "Size", "Anchored", "CanCollide", "CanTouch", "CanQuery", "Transparency", "Color", "Material" }
	local floors = {}
	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("BasePart") and (object.Name:match("Floor$") or object.Name == "Platform"
			or object.Name == "AnimalKingdomConcreteGround" or object.Name == "TownPlaza") then
			local snapshot = { Parent = object.Parent }
			for _, property in ipairs(floorProperties) do snapshot[property] = object[property] end
			floors[object] = snapshot
		end
	end
	local function floorsUnchanged()
		for object, snapshot in pairs(floors) do
			for property, value in pairs(snapshot) do
				if object[property] ~= value then
					warn("AK_PHENOMENA changed authored floor: " .. object.Name .. "." .. property)
					return false
				end
			end
		end
		return next(floors) ~= nil
	end
	local ok, err = pcall(function()
		camera.CameraType = Enum.CameraType.Scriptable
		local ground = workspace:FindFirstChild("AnimalKingdomConcreteGround") or workspace:FindFirstChild("GrassFloor")
		local center = ground and ground.Position or Vector3.new(-338, 8, 248)
		camera.CFrame = CFrame.lookAt(center + Vector3.new(0, 25, 130), center + Vector3.new(0, 140, -260))
		local startedAt = phase("MeteorShower")
		local meteorFolder = waitFor(function()
			local runtime = workspace:FindFirstChild("WeatherWorldEffects")
			return runtime and runtime:FindFirstChild("MeteorShowerEffects")
		end, 3)
		assert(meteorFolder, "MeteorShowerEffects did not start")
		check(meteorFolder:GetAttribute("ImpactLifetime") == 30, "impact lifetime configured to 30 seconds")
		local launches, bigLaunches, trajectorySamples, fastSamples = 0, 0, 0, 0
		local function observe(object)
			if not object.Parent or not object:IsA("BasePart") or (object.Name ~= "Meteor" and object.Name ~= "LargeMeteor") then return end
			if object.Name == "Meteor" then launches += 1 else bigLaunches += 1 end
			local from, to = object:GetAttribute("StartPosition"), object:GetAttribute("TargetPosition")
			if typeof(from) ~= "Vector3" or typeof(to) ~= "Vector3" then
				check(false, "meteor missing world trajectory metadata")
				return
			end
			local oldPosition, oldTime = object.Position, workspace:GetServerTimeNow()
			task.delay(0.15, function()
				if not object.Parent then return end
				local direction = to - from
				local progress = (object.Position - from):Dot(direction) / direction:Dot(direction)
				local error = (object.Position - (from + direction * progress)).Magnitude
				if error < 0.5 and progress >= -0.01 and progress <= 1.01 then trajectorySamples += 1 end
				local elapsed = workspace:GetServerTimeNow() - oldTime
				if object.Name == "Meteor" and elapsed > 0 and (object.Position - oldPosition).Magnitude / elapsed > 250 then fastSamples += 1 end
			end)
		end
		for _, child in ipairs(meteorFolder:GetChildren()) do observe(child) end
		table.insert(connections, meteorFolder.ChildAdded:Connect(function(object) task.defer(observe, object) end))
		camera.CFrame *= CFrame.Angles(0, math.pi, 0)
		camera.CFrame += Vector3.new(120, 0, 70)
		task.wait(4)
		check(launches >= 12, "frequent flying meteors: " .. launches .. " observed in four seconds")
		check(trajectorySamples >= 8 and fastSamples >= 8, "fast meteors follow world trajectories after camera rotation/translation")
		local impact = waitFor(function() return meteorFolder:FindFirstChild("MeteorImpact") end, math.max(0.1, 16 - (workspace:GetServerTimeNow() - startedAt)))
		check(impact ~= nil, "large ground impact appears within 16 seconds")
		assert(impact, "No valid ground impact available to verify lifetime")
		check(bigLaunches >= 1, "large meteor visibly flies before its impact")
		local impactAt, expiresAt = impact:GetAttribute("ImpactAt"), impact:GetAttribute("ExpiresAt")
		check(type(impactAt) == "number" and expiresAt - impactAt == 30, "impact server-clock deadline is exactly 30 seconds")
		local scorch = assert(impact:FindFirstChild("ScorchedGround"), "Impact missing visible scorch")
		check(impact:FindFirstChild("CraterRubble") ~= nil and impact:FindFirstChild("GroundCrack") ~= nil, "impact has rubble and ground cracks")
		local fixedScorch = scorch.CFrame
		camera.CFrame *= CFrame.Angles(0, math.pi, 0)
		camera.CFrame += Vector3.new(-210, 5, -130)
		local maxFlights, maxImpacts, prematureRemoval = 0, 0, false
		while workspace:GetServerTimeNow() < expiresAt + 0.3 do
			local flying, craters = 0, 0
			for _, child in ipairs(meteorFolder:GetChildren()) do
				if child.Name == "Meteor" or child.Name == "LargeMeteor" then flying += 1 end
				if child.Name == "MeteorImpact" then craters += 1 end
			end
			maxFlights, maxImpacts = math.max(maxFlights, flying), math.max(maxImpacts, craters)
			if not impact.Parent and workspace:GetServerTimeNow() < expiresAt - 0.1 then prematureRemoval = true end
			if impact.Parent then assert(scorch.CFrame == fixedScorch, "Ground impact followed the camera") end
			task.wait(0.1)
		end
		check(not prematureRemoval and not impact.Parent, "individual impact persists then cleans itself after 30 seconds")
		check(maxFlights <= 18 and maxImpacts <= 3, "bounded effects: peak flights=" .. maxFlights .. ", impacts=" .. maxImpacts)
		check(safeEffects(meteorFolder), "meteor/rubble/crack effects anchored and noncolliding")
		check(floorsUnchanged(), "impacts preserve authored floor geometry and collision")
		phase(nil)
		task.wait(2.3)
		check(not meteorFolder.Parent and workspace:FindFirstChild("WeatherWorldEffects") == nil, "ending MeteorShower removes all remaining flights and impact scars")

		phase("SpiritNight")
		local spiritFolder = waitFor(function()
			local runtime = workspace:FindFirstChild("WeatherWorldEffects")
			return runtime and runtime:FindFirstChild("SpiritNightWorld")
		end, 3)
		assert(spiritFolder, "SpiritNightWorld did not start")
		task.wait(1)
		local ghosts, recognizable, particleRate = {}, true, 0
		for _, object in ipairs(spiritFolder:GetChildren()) do
			if object:IsA("Model") then
				table.insert(ghosts, object)
				for _, name in ipairs({ "SheetBody", "RoundHead", "LeftEye", "RightEye", "LittleMouth" }) do
					local feature = object:FindFirstChild(name)
					if not feature or not feature:IsA("BasePart") or feature.Transparency >= 0.95 then recognizable = false end
				end
			end
		end
		for _, object in ipairs(spiritFolder:GetDescendants()) do
			if object:IsA("ParticleEmitter") and object.Enabled then particleRate += object.Rate end
		end
		check(#ghosts > 0 and #ghosts <= 12 and spiritFolder:GetAttribute("GhostLimit") == 12, "recognizable ghost crowd is present and bounded: " .. #ghosts)
		check(recognizable, "ghosts have visible sheet bodies, round heads, paired eyes and mouths")
		check(particleRate > 0 and particleRate <= 132, "spirit wisps/fireflies active with bounded aggregate rate: " .. particleRate)
		check(safeEffects(spiritFolder), "ghosts and spirit effects anchored and noncolliding")
		local ghost = assert(ghosts[1], "No ghost path to verify")
		local pathCenter, previousPivot = ghost:GetAttribute("WorldPathCenter"), ghost:GetPivot()
		camera.CFrame *= CFrame.Angles(0, math.pi, 0)
		camera.CFrame += Vector3.new(160, 10, 0)
		task.wait(1)
		check(ghost.Parent and ghost:GetAttribute("WorldPathCenter") == pathCenter
			and (ghost:GetPivot().Position - pathCenter).Magnitude < 20
			and (ghost:GetPivot().Position - previousPivot.Position).Magnitude > 0.1,
			"ghost animates around its fixed world path when camera moves")
		phase(nil)
		task.wait(2.3)
		check(not spiritFolder.Parent and workspace:FindFirstChild("WeatherWorldEffects") == nil, "ending SpiritNight removes every ghost and emitter")
		check(floorsUnchanged(), "both phenomena leave map geometry and collision unchanged")
	end)
	if not ok then check(false, "runtime exception: " .. tostring(err)) end
	for _, connection in ipairs(connections) do connection:Disconnect() end
	phase(nil)
	task.wait(2.3)
	for name, value in pairs(savedState) do state:SetAttribute(name, value) end
	camera.CFrame, camera.CameraType, camera.CameraSubject = savedCamera, savedType, savedSubject
	print("AK_PHENOMENA_DONE assertions=" .. assertions .. " failures=" .. failures)
end)
