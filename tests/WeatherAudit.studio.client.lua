-- Run in the CLIENT Command Bar in a fresh Studio Play session during Break.
-- Local replicated-state injection exercises the shipped visual/UI controllers.
-- Server timing/queue/authorization are tested separately by the admin suite.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Studio client required")
task.spawn(function()
	local storage = game:GetService("ReplicatedStorage")
	local lighting = game:GetService("Lighting")
	local sounds = game:GetService("SoundService")
	local state = storage:WaitForChild("WeatherState")
	assert(state:GetAttribute("Phase") == "Break", "Start this test during the initial production Break")
	local definitions = require(storage.Shared.EventDefinitions)
	local savedState = state:GetAttributes()
	local camera = workspace.CurrentCamera
	local savedCamera, savedType, savedSubject = camera.CFrame, camera.CameraType, camera.CameraSubject
	local failures, tested = 0, 0
	local properties = {
		Lighting = { "Brightness", "ClockTime", "ExposureCompensation", "FogStart", "FogEnd", "FogColor", "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom" },
		Atmosphere = { "Density", "Color", "Decay", "Haze", "Glare", "Offset" },
		Clouds = { "Cover", "Density", "Color", "Enabled" },
		ColorCorrectionEffect = { "Brightness", "Contrast", "Saturation", "TintColor", "Enabled" },
		BloomEffect = { "Intensity", "Size", "Threshold", "Enabled" },
		SunRaysEffect = { "Intensity", "Spread", "Enabled" },
		BlurEffect = { "Size", "Enabled" },
		Sky = { "MoonAngularSize", "MoonTextureId" },
	}
	local baseline = {}
	local function capture(instance)
		local values = {}
		for _, name in ipairs(properties[instance.ClassName] or {}) do values[name] = instance[name] end
		baseline[instance] = values
	end
	capture(lighting)
	for _, object in ipairs(lighting:GetChildren()) do if properties[object.ClassName] then capture(object) end end
	for _, object in ipairs(workspace.Terrain:GetChildren()) do if object:IsA("Clouds") then capture(object) end end
	local function check(ok, description)
		if not ok then failures += 1 end
		print("AK_WEATHER_AUDIT " .. (ok and "PASS " or "FAIL ") .. description)
	end
	local function phase(id)
		local now = workspace:GetServerTimeNow()
		state:SetAttribute("EventId", id or "")
		state:SetAttribute("StartedAt", id and now or 0)
		state:SetAttribute("EndsAt", id and now + 420 or 0)
		state:SetAttribute("Phase", id and "Event" or "Break")
	end
	local function verifyRestored(id)
		check(workspace:FindFirstChild("WeatherWorldEffects") == nil, id .. " runtime destroyed")
		local soundCount = 0
		for _, object in ipairs(sounds:GetChildren()) do
			if string.sub(object.Name, 1, 10) == "AK_Weather" then soundCount += 1 end
		end
		check(soundCount == 0, id .. " weather sounds destroyed")
		local restored = true
		for instance, values in pairs(baseline) do
			for name, expected in pairs(values) do
				local actual = instance[name]
				local same = typeof(actual) == "number" and math.abs(actual - expected) < 0.0001 or actual == expected
				if not same then restored = false; warn(id .. " unrestored " .. instance.Name .. "." .. name) end
			end
		end
		for _, parent in ipairs({ lighting, workspace.Terrain }) do
			for _, object in ipairs(parent:GetChildren()) do
				if properties[object.ClassName] and not baseline[object] then restored = false end
			end
		end
		check(restored, id .. " Lighting/Atmosphere/Clouds/Sky restored")
	end
	local ok, err = pcall(function()
		camera.CameraType = Enum.CameraType.Scriptable
		local ids = {}
		for id in pairs(definitions) do table.insert(ids, id) end
		table.sort(ids)
		for _, id in ipairs(ids) do
			phase(id)
			task.wait(0.35)
			local runtime = workspace:FindFirstChild("WeatherWorldEffects")
			check(runtime ~= nil and runtime:GetAttribute("EventId") == id, id .. " applies")
			check(definitions[id].Duration == 420, id .. " metadata duration 420")
			local ui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("WeatherEventUI")
			local timer = ui and ui:FindFirstChild("Countdown", true)
			check(timer ~= nil and string.match(timer.Text, "Time Left: %d:%d%d") ~= nil, id .. " authoritative countdown visible")
			if runtime then
				local safe = true
				for _, object in ipairs(runtime:GetDescendants()) do
					if object:IsA("BasePart") and (not object.Anchored or object.CanCollide or object.CanTouch or object.CanQuery) then safe = false end
				end
				check(safe, id .. " effects anchored and noncolliding")
				local anchor = runtime:FindFirstChild(id .. "Anchor", true)
				if anchor then
					local fixed = anchor.CFrame
					camera.CFrame = CFrame.lookAt(Vector3.new(-338, 30, 248), anchor.Position)
					task.wait(0.1)
					local _, towards = camera:WorldToViewportPoint(anchor.Position)
					camera.CFrame *= CFrame.Angles(0, math.pi, 0)
					task.wait(0.1)
					local _, away = camera:WorldToViewportPoint(anchor.Position)
					camera.CFrame += Vector3.new(60, 0, 80)
					task.wait(0.1)
					check(anchor.CFrame == fixed and towards and not away, id .. " fixed world position across camera rotation/translation " .. tostring(anchor.Position))
				end
				if id == "Rainbow" then
					local beams = 0
					for _, object in ipairs(runtime:GetDescendants()) do if object:IsA("Beam") then beams += 1 end end
					check(beams == 14, "Rainbow smooth seven-color arch / 14 Beams")
				end
			end
			phase(nil)
			task.wait(2.2)
			verifyRestored(id)
			tested += 1
		end
		-- Rapid replacement must invalidate old tweens, particles, delayed bursts,
		-- sound cleanup and moon restore callbacks without touching the new event.
		for _, id in ipairs({ "Thunderstorm", "BloodMoon", "Rainbow", "MeteorShower", "Void" }) do
			phase(id)
			task.wait(0.12)
		end
		phase(nil)
		task.wait(2.3)
		verifyRestored("rapid replacement")
	end)
	if not ok then check(false, "runtime exception " .. tostring(err)) end
	phase(nil)
	task.wait(2.2)
	for name, value in pairs(savedState) do state:SetAttribute(name, value) end
	camera.CFrame, camera.CameraType, camera.CameraSubject = savedCamera, savedType, savedSubject
	print("AK_WEATHER_AUDIT_DONE events=" .. tested .. " failures=" .. failures)
end)
