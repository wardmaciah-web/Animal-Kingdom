local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Definitions = require(ReplicatedStorage.Shared.AdminCommandDefinitions)
local Events = require(ReplicatedStorage.Shared.EventDefinitions)
local modules = ServerScriptService.AdminCommandCenter
local Policy = require(modules.RequestPolicy)
local PlotStatus = require(modules.PlotStatus)
local Teleports = require(modules.Teleports)
local RoomPanels = require(modules.RoomPanels)
local ActivityLog = require(modules.ActivityLog)

local Service = Knit.CreateService({Name="AdminCommandService", Client={}})
local WeatherAdmin, Weather
local requestRemote, responseRemote, stateRemote, announcementRemote, cameraRemote
local activity = ActivityLog.new(Definitions.ActivityLimit)
local pending, busy, lastAnnouncement, roomPresence, spectators, respawning = {}, {}, {}, {}, {}, {}
local announcementBusy = false
local lastBroadcast = -math.huge
local startedAt = workspace:GetServerTimeNow() - time()
local destinationNames = {}
for _, destination in ipairs(Definitions.Destinations) do destinationNames[destination.Id] = destination.DisplayName end

local function reply(player, message, ok)
	if player.Parent == Players then responseRemote:FireClient(player, {Kind="Result", Message=message, Success=ok == true}) end
end

local function record(player, message)
	activity:Add(player, message)
end

local function stopSpectating(admin, reason)
	local session = spectators[admin]
	if not session then return end
	spectators[admin] = nil
	if session.Connection then session.Connection:Disconnect() end
	if session.Root then pcall(admin.RemoveReplicationFocus, admin, session.Root) end
	record(admin, "stopped spectating " .. session.Target.Name)
	if admin.Parent == Players then responseRemote:FireClient(admin, {Kind="SpectateStop", Reason=reason}) end
end

local function startSpectating(admin, target)
	if admin == target then reply(admin, "SELECT ANOTHER PLAYER", false); return end
	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then reply(admin, "TARGET CHARACTER NOT READY", false); return end
	stopSpectating(admin)
	local session = {Target=target, Root=root}
	spectators[admin] = session
	-- Keep the distant subject replicated while the admin remains in the room.
	local focusOk = pcall(admin.AddReplicationFocus, admin, root)
	if workspace.StreamingEnabled and not focusOk then
		spectators[admin] = nil
		reply(admin, "SPECTATE STREAMING UNAVAILABLE", false)
		return
	end
	session.Connection = target.CharacterRemoving:Connect(function() stopSpectating(admin, "Target respawned") end)
	cameraRemote:FireClient(admin, "Close")
	responseRemote:FireClient(admin, {Kind="SpectateStart", TargetUserId=target.UserId, Position=root.Position})
	record(admin, "started spectating " .. target.Name)
end

local function confirmation(player, payload, title)
	local token = HttpService:GenerateGUID(false)
	pending[player] = {Token=token, Payload=table.clone(payload), Expires=os.clock()+Definitions.ConfirmationLifetime, QueueRevision=Weather.QueueRevision}
	responseRemote:FireClient(player, {Kind="Confirm", Token=token, Title=title, Lifetime=Definitions.ConfirmationLifetime})
end

local function sendState(player, roster, plots)
	stateRemote:FireClient(player, {
		Authorized=true, InRoom=WeatherAdmin:IsInsideRoom(player), Players=roster, MaxPlayers=Players.MaxPlayers,
		ServerStartedAt=startedAt, Plots=plots, Weather=Weather:GetCurrentState(), Activity=activity:Snapshot(),
	})
end

local function snapshot()
	local plotInfo, plots = PlotStatus.GetSnapshot()
	local roster = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local plot = PlotStatus.GetPlayerPlot(player, plots)
		table.insert(roster, {Username=player.Name, DisplayName=player.DisplayName, UserId=player.UserId, Plot=plot and plot.Name or ""})
	end
	table.sort(roster, function(a,b) return a.Username:lower() < b.Username:lower() end)
	return roster, plotInfo
end

local function broadcastAnnouncement(player, raw)
	local message = Policy.SanitizeMessage(raw, Definitions.MaxAnnouncementCharacters)
	if not message then reply(player, "ENTER A MESSAGE OF 1–150 CHARACTERS", false); return end
	local now = os.clock()
	if announcementBusy or now-lastBroadcast < 2 or (lastAnnouncement[player] and now-lastAnnouncement[player] < 5) then
		reply(player, "PLEASE WAIT BEFORE SENDING ANOTHER ANNOUNCEMENT", false)
		return
	end
	lastAnnouncement[player] = now
	announcementBusy = true
	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(message, player.UserId, Enum.TextFilterContext.PublicChat)
		return result:GetNonChatStringForBroadcastAsync()
	end)
	announcementBusy = false
	if not ok or type(filtered) ~= "string" or not filtered:match("%S") then
		reply(player, "TEXT FILTER UNAVAILABLE — announcement was not sent", false)
		return
	end
	-- Filtering yields. Revalidate authority and membership before broadcasting.
	if player.Parent ~= Players or not WeatherAdmin:IsAuthorized(player) or not WeatherAdmin:IsInsideRoom(player) then return end
	lastBroadcast = os.clock()
	local formattedMessage = string.format('[Admin] "%s": "%s"', player.Name, filtered)
	announcementRemote:FireAllClients({Message=formattedMessage})
	record(player, formattedMessage)
	print(formattedMessage)
	reply(player, "ANNOUNCEMENT SENT", true)
end

local function execute(player, payload, confirmed)
	local action = payload.Action
	if action == "GetState" then sendState(player, snapshot()); return end
	if action == "StopSpectating" then stopSpectating(player); return end
	if action == "Teleport" and payload.Destination == "AdminRoom" then
		local ok, reason = Teleports.ToDestination(player, "AdminRoom", WeatherAdmin)
		if ok then stopSpectating(player); record(player, "teleported to Admin Room") end
		reply(player, ok and "RETURNED TO ADMIN ROOM" or reason, ok)
		return
	end
	if not WeatherAdmin:IsInsideRoom(player) then reply(player, "RETURN TO ADMIN ROOM TO USE THIS CONTROL", false); return end
	if action == "Confirm" then
		local request = pending[player]
		pending[player] = nil
		if not request or request.Token ~= payload.Token or os.clock() > request.Expires then reply(player, "CONFIRMATION EXPIRED", false); return end
		if request.Payload.Action == "QueueEvent" and request.QueueRevision ~= Weather.QueueRevision then
			reply(player, "QUEUE CHANGED — select the event again", false)
			return
		end
		execute(player, request.Payload, true)
		return
	end
	if action == "Announce" then broadcastAnnouncement(player, payload.Message); return end
	if action == "QueueEvent" then
		if not confirmed and Weather.QueuedEventId ~= "" then
			confirmation(player, payload, "REPLACE " .. Events[Weather.QueuedEventId].DisplayName:upper() .. " WITH " .. Events[payload.EventId].DisplayName:upper() .. "?")
			return
		end
		if Weather:QueueEvent(payload.EventId) then
			record(player, "queued " .. Events[payload.EventId].DisplayName)
			reply(player, "EVENT QUEUED — current event continues", true)
		end
		return
	end
	if action == "ClearQueue" then
		Weather:ClearQueue()
		record(player, "cleared event queue")
		reply(player, "QUEUE CLEARED", true)
		return
	end
	if action == "EmergencyReset" then
		if not confirmed then confirmation(player, payload, "RESET WEATHER?\nEnds the event, clears the queue, and resumes the normal cycle."); return end
		Weather:EmergencyReset()
		record(player, "performed emergency weather reset")
		reply(player, "WEATHER RESET — normal cycle resumed", true)
		return
	end
	if action == "Teleport" then
		local ok, reason = Teleports.ToDestination(player, payload.Destination, WeatherAdmin)
		if ok then
			stopSpectating(player)
			cameraRemote:FireClient(player, "Close")
			record(player, "teleported to " .. destinationNames[payload.Destination])
		end
		reply(player, ok and "TELEPORTED" or reason, ok)
		return
	end
	local target = Players:GetPlayerByUserId(payload.TargetUserId)
	if not target or target.Parent ~= Players then reply(player, "PLAYER LEFT THE SERVER", false); return end
	if action == "SpectatePlayer" then startSpectating(player,target); return end
	if action == "RespawnPlayer" then
		if not confirmed then confirmation(player, payload, "RESPAWN " .. target.Name .. "?"); return end
		if respawning[target] then reply(player, "PLAYER IS ALREADY RESPAWNING", false); return end
		respawning[target] = true
		local ok = pcall(target.LoadCharacterAsync, target)
		respawning[target] = nil
		if ok then record(player, "respawned " .. target.Name) end
		reply(player, ok and "PLAYER RESPAWNED" or "RESPAWN FAILED — try again", ok)
		return
	end
	local ok, reason, message
	if action == "TeleportToPlayer" then
		ok, reason = Teleports.ToPlayer(player, target)
		message = "teleported to " .. target.Name
	elseif action == "TeleportToPlot" then
		ok, reason = Teleports.ToPlot(player, target)
		message = "teleported to " .. target.Name .. "'s plot"
	elseif action == "ReturnPlayerToPlot" then
		ok, reason = Teleports.ToPlot(target, target)
		message = "returned " .. target.Name .. " to their plot"
	elseif action == "BringPlayer" then
		if player == target then reply(player, "SELECT ANOTHER PLAYER", false); return end
		ok, reason = Teleports.ToPlayer(target, player)
		message = "brought " .. target.Name .. " to Admin Room"
	end
	if ok then
		record(player, message)
		if action == "TeleportToPlayer" or action == "TeleportToPlot" or player == target then
			stopSpectating(player)
			cameraRemote:FireClient(player, "Close")
		end
	end
	reply(player, ok and "ACTION COMPLETE" or reason or "ACTION UNAVAILABLE", ok)
end

function Service:KnitInit()
	WeatherAdmin = Knit.GetService("WeatherAdminService")
	Weather = Knit.GetService("WeatherEventService")
end

function Service:KnitStart()
	ReplicatedStorage:WaitForChild("WeatherState")
	local remotes = ReplicatedStorage:WaitForChild("AnimalKingdomRemotes")
	cameraRemote = remotes:WaitForChild("AdminCameraControl")
	local function remote(name)
		local object = remotes:FindFirstChild(name)
		if not object then object = Instance.new("RemoteEvent"); object.Name=name; object.Parent=remotes end
		assert(object:IsA("RemoteEvent"), name .. " must be a RemoteEvent")
		return object
	end
	requestRemote = remote("AdminCommandRequest")
	responseRemote = remote("AdminCommandResponse")
	stateRemote = remote("AdminCommandState")
	announcementRemote = remote("GlobalAnnouncement")
	local validate, forget = Policy.new(function(player) return WeatherAdmin:IsAuthorized(player) end, Definitions, Events)
	requestRemote.OnServerEvent:Connect(function(player, payload, ...)
		if busy[player] or not validate(player, payload, ...) then return end
		-- Group authorization may yield; another accepted request can become
		-- active before validation resumes.
		if busy[player] or player.Parent ~= Players then return end
		busy[player] = true
		local ok, err = pcall(execute, player, payload, false)
		busy[player] = nil
		if not ok then
			warn("[AdminCommand] Request failed: " .. tostring(err))
			reply(player, "ACTION FAILED — please try again", false)
		end
	end)
	WeatherAdmin.ActionRecorded.Event:Connect(record)
	-- A Phase 1 camera selection ends spectating without changing that controller.
	cameraRemote.OnServerEvent:Connect(function(player, command)
		if (command == "Select" or command == "Exit") and WeatherAdmin:IsAuthorized(player) then stopSpectating(player) end
	end)
	local function watch(player)
		player.CharacterRemoving:Connect(function() stopSpectating(player, "Admin respawned"); pending[player] = nil end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in ipairs(Players:GetPlayers()) do watch(player) end
	Players.PlayerRemoving:Connect(function(player)
		if roomPresence[player] then record(player, "left Admin Room (disconnected)") end
		stopSpectating(player)
		for admin, session in pairs(spectators) do if session.Target == player then stopSpectating(admin, "Player left the server") end end
		pending[player], busy[player], lastAnnouncement[player], roomPresence[player], respawning[player] = nil,nil,nil,nil,nil
		forget(player)
	end)
	task.spawn(function()
		local currentRoom
		while true do
			local room = workspace:FindFirstChild("WeatherAdminRoom")
			if room and room ~= currentRoom and room:FindFirstChild("BackWall") then
				local panels, issue = RoomPanels.Attach(room)
				if panels then currentRoom=room else warn("[AdminCommand] " .. issue); currentRoom=room end
			end
			local roster, plots = snapshot()
			for _, player in ipairs(Players:GetPlayers()) do
				if WeatherAdmin:IsAuthorized(player) then
					local inside = WeatherAdmin:IsInsideRoom(player)
					if inside ~= (roomPresence[player] == true) then
						record(player, inside and "entered Admin Room" or "left Admin Room")
						roomPresence[player] = inside
					end
					if not inside then stopSpectating(player, "Left Admin Room"); pending[player] = nil end
					sendState(player, roster, plots)
				else
					stopSpectating(player, "Authorization changed")
					pending[player] = nil
					stateRemote:FireClient(player, {Authorized=false})
				end
			end
			task.wait(1)
		end
	end)
end

return Service
