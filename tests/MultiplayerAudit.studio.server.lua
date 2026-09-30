-- Optional read-only observer for a REAL Studio Start Server + two clients test.
-- Run on the server, then reset one client, leave, and rejoin. No fake Players,
-- profile writes, remote invocations, or ownership changes are made here.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning(), "Run on a Studio test server")
local server = game:GetService("ServerScriptService")
local Locator = require(server.PlotLocator)
local Status = require(server.AdminCommandCenter.PlotStatus)
local tracked, connections = {}, {}
local maxPlayers, releases, respawns, failures = 0, 0, 0, 0
local active = true
local function report(ok, message)
	if not ok then failures += 1 end
	print("[MultiplayerAudit] " .. (ok and "PASS " or "FAIL ") .. message)
end
local function snapshot()
	local owners = {}
	local roster = Players:GetPlayers()
	maxPlayers = math.max(maxPlayers, #roster)
	for _, plot in ipairs(Locator.getPlots()) do
		if plot:GetAttribute("Claimed") == true then
			local id = plot:GetAttribute("OwnerUserId")
			if owners[id] then report(false, "duplicate ownership: " .. tostring(id)) end
			owners[id] = plot
		end
	end
	return owners
end
local function checkSpawn(player, character, isRespawn)
	local deadline = os.clock() + 12
	local plot
	repeat
		if not active or player.Parent ~= Players or player.Character ~= character then return end
		plot = Status.GetPlayerPlot(player)
		if plot and character:FindFirstChild("HumanoidRootPart") then break end
		task.wait(0.2)
	until os.clock() >= deadline
	if not plot then report(false, player.Name .. " has no plot after join"); return end
	-- Allow the production CharacterAdded placement to complete.
	task.wait(0.5)
	if not active or player.Parent ~= Players or player.Character ~= character then return end
	local prior = tracked[player]
	tracked[player] = plot
	if isRespawn then
		respawns += 1
		report(not prior or prior == plot, player.Name .. " retained plot on respawn")
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local marker = Status.GetSpawn(plot)
	report(root ~= nil and marker ~= nil and (root.Position - marker.Position).Magnitude < 18,
		player.Name .. " landed near assigned " .. plot.Name)
	snapshot()
end
local function watch(player)
	local seenCharacter = player.Character ~= nil
	table.insert(connections, player.CharacterAdded:Connect(function(character)
		local isRespawn = seenCharacter
		seenCharacter = true
		task.spawn(checkSpawn, player, character, isRespawn)
	end))
	if player.Character then task.spawn(checkSpawn, player, player.Character, false) end
end
table.insert(connections, Players.PlayerAdded:Connect(watch))
table.insert(connections, Players.PlayerRemoving:Connect(function(player)
	local plot = tracked[player]
	tracked[player] = nil
	task.delay(0.5, function()
		if not active or not plot then return end
		releases += 1
		report(plot:GetAttribute("Claimed") ~= true or plot:GetAttribute("OwnerUserId") ~= player.UserId,
			player.Name .. " released " .. plot.Name .. " on departure")
		snapshot()
	end)
end))
for _, player in ipairs(Players:GetPlayers()) do watch(player) end
snapshot()
print("[MultiplayerAudit] Observer active for 5 minutes; connect two actual clients, reset one, leave and rejoin")
task.delay(300, function()
	active = false
	for _, connection in ipairs(connections) do connection:Disconnect() end
	print(string.format("[MultiplayerAudit] Summary: max actual clients=%d, observed releases=%d, respawns=%d, failures=%d", maxPlayers, releases, respawns, failures))
	if maxPlayers < 2 or releases == 0 or respawns == 0 then
		warn("[MultiplayerAudit] INCOMPLETE: the required real-client actions were not all observed")
	end
end)
