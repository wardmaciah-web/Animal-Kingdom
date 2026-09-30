-- Run in the SERVER Command Bar during a fresh Studio Play session.
-- Moves one test player through the existing safe-landing code, then restores
-- their starting area. Does not change saved data, ownership, or authorization.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
assert(game:GetService("RunService"):IsRunning(), "Start a Studio Play session first")
local PlotLocator = require(ServerScriptService.PlotLocator)
local PlotStatus = require(ServerScriptService.AdminCommandCenter.PlotStatus)
local Teleports = require(ServerScriptService.AdminCommandCenter.Teleports)
local Profiles = require(ServerScriptService.ServerSource.Server.ProfileService)
local Admin = require(ServerScriptService.ServerSource.Server.WeatherAdminService)
local player = assert(Players:GetPlayers()[1], "No test player is connected")
local character = assert(player.Character, "Wait for the character to spawn")
local root = assert(character:FindFirstChild("HumanoidRootPart"), "Wait for the character root")
local original = root.CFrame
local failures = {}
local function check(name, passed, detail)
	print("[SystemAudit] " .. (passed and "PASS " or "FAIL ") .. name .. (detail and " | " .. tostring(detail) or ""))
	if not passed then table.insert(failures, name) end
end
local plots = PlotLocator.getPlots()
check("real plot floors discovered", #plots > 0, #plots)
local seen = {}
for _, plot in ipairs(plots) do
	local claimed = plot:GetAttribute("Claimed") == true
	local owner = plot:GetAttribute("OwnerUserId")
	check("ownership " .. plot.Name, not claimed or (type(owner) == "number" and not seen[owner]), owner)
	if claimed then seen[owner] = true end
	local spawn = PlotStatus.GetSpawn(plot)
	local ok, reason = false, "spawn missing"
	if spawn then ok, reason = Teleports.Near(player, spawn.CFrame) end
	check("safe plot landing " .. plot.Name, ok, reason)
	if ok then
		check("plot landing clears velocity " .. plot.Name, root.AssemblyLinearVelocity.Magnitude < 0.01)
	end
end
check("player owns one real plot", PlotStatus.GetPlayerPlot(player, plots) ~= nil, player:GetAttribute("PlotId"))
local loaded = Profiles.Profiles[player]
check("profile loaded", loaded ~= nil)
if loaded then
	check("ProfileStore session active", loaded:IsActive())
	check("profile data reconciled", type(loaded.Data.UnlockedBiomes) == "table" and loaded.Data.UnlockedBiomes.Meadow == true)
end
local points = workspace:FindFirstChild("AK_AdminCameraPoints")
local definitions = require(ReplicatedStorage.Shared.AdminCameraDefinitions)
for _, definition in ipairs(definitions) do
	local point = points and points:FindFirstChild(definition.Id)
	check("camera point " .. definition.Id, point ~= nil and point:IsA("BasePart"))
end
local room = workspace:FindFirstChild("WeatherAdminRoom")
check("admin room exists", room ~= nil)
local panels = room and room:FindFirstChild("CameraWallPanels")
if panels then
	local names = {}
	for _, panel in ipairs(panels:GetChildren()) do
		local id = panel:GetAttribute("CameraId")
		if id then
			check("camera label " .. id, type(panel:GetAttribute("CameraDisplayName")) == "string" and panel:GetAttribute("CameraDisplayName") ~= "")
			names[id] = true
		end
	end
	for _, definition in ipairs(definitions) do check("camera button " .. definition.Id, names[definition.Id] == true) end
else
	check("camera wall panels", false)
end
if Admin:IsAuthorized(player) then
	check("admin entry safe landing", Admin:EnterAdminRoom(player))
	check("admin entry room membership", Admin:IsInsideRoom(player))
	check("admin entry clears velocity", root.AssemblyLinearVelocity.Magnitude < 0.01)
else
	print("[SystemAudit] WARNING admin entry requires the existing authorized creator/admin test account")
end
local restored, reason = Teleports.Near(player, original)
check("return to starting area", restored, reason)
print("[SystemAudit] Finished: " .. #failures .. " failures; actual connected players=" .. #Players:GetPlayers())
if #Players:GetPlayers() < 2 then
	print("[SystemAudit] WARNING multiplayer admission/release still requires a separate two-client Studio test")
end
