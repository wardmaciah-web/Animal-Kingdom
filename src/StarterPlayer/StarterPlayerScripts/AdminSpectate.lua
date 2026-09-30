local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Ownership=require(game.ReplicatedStorage.Shared.Gameplay.CameraOwnership)
local Spectate = {}
Spectate.__index = Spectate

function Spectate.new(onStopped)
	local self = setmetatable({connections={}, generation=0, onStopped=onStopped}, Spectate)
	player.CharacterAdded:Connect(function() self:Stop(true, true) end)
	return self
end

function Spectate:Stop(restore, notify)
	if not self.active then return end
	self.active = false
	self.generation += 1
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	self.connections = {}
 if self.cameraToken then Ownership.Release(self.cameraToken);self.cameraToken=nil end
	self.onStopped(notify)
end

function Spectate:Start(userId, position)
	self:Stop(true, false)
	self.active = true
	self.generation += 1
	local generation = self.generation
	local target = Players:GetPlayerByUserId(userId)
	if not target then self:Stop(true,true); return end
	task.spawn(function()
		if workspace.StreamingEnabled and typeof(position) == "Vector3" then
			pcall(player.RequestStreamAroundAsync, player, position, 5)
		end
		local deadline = os.clock() + 8
		local humanoid
		repeat
			if generation ~= self.generation then return end
			local character = target.Character
			humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then break end
			task.wait(0.1)
		until os.clock() >= deadline or target.Parent ~= Players
		if not humanoid or humanoid.Health <= 0 then self:Stop(true,true); return end
		-- Give the Phase 1 Close response time to restore its own camera first.
		task.defer(function()
			if generation ~= self.generation then return end
   self.cameraToken=Ownership.Acquire("AdminSpectate",function(camera)
    if camera then camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=humanoid end
   end,function()self:Stop(false,true)end)
			table.insert(self.connections, humanoid.Died:Connect(function() self:Stop(true,true) end))
			table.insert(self.connections, target.CharacterRemoving:Connect(function() self:Stop(true,true) end))
			table.insert(self.connections, Players.PlayerRemoving:Connect(function(leaving) if leaving == target then self:Stop(true,true) end end))
		end)
	end)
end

return Spectate
