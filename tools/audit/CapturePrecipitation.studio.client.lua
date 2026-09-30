-- Studio client capture aid. Temporary local presentation; restores player/state.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient())
task.spawn(function()
	local state = game.ReplicatedStorage.WeatherState
	assert(state:GetAttribute("Phase") == "Break", "Start during Break")
	local camera, player = workspace.CurrentCamera, game.Players.LocalPlayer
	local root = player.Character.HumanoidRootPart
	local original = {State=state:GetAttributes(), Camera=camera.CFrame, Type=camera.CameraType, Root=root.CFrame}
	local function phase(id)
		state:SetAttribute("Phase", "Break")
		state:SetAttribute("EventId", id or "")
		state:SetAttribute("StartedAt", workspace:GetServerTimeNow())
		state:SetAttribute("EndsAt", workspace:GetServerTimeNow()+420)
		state:SetAttribute("Phase", id and "Event" or "Break")
	end
	local ok, err = pcall(function()
		root.CFrame=CFrame.new(-470,13,395)
		camera.CameraType=Enum.CameraType.Scriptable
		camera.CFrame=CFrame.lookAt(Vector3.new(-470,18,405),Vector3.new(-470,18,250))
		for _,id in ipairs({"RainyDay","Thunderstorm"}) do
			phase(id)
			task.wait(3)
			print("AK_POLISH_CAPTURE "..id.."PlayerView")
			task.wait(4)
			phase(nil)
			task.wait(2.3)
		end
	end)
	phase(nil)
	task.wait(2.3)
	for key,value in pairs(original.State) do state:SetAttribute(key,value) end
	root.CFrame=original.Root
	camera.CFrame=original.Camera
	camera.CameraType=original.Type
	print("AK_POLISH_DONE precipitation capture "..tostring(ok).." "..tostring(err))
end)
