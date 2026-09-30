local Policy = {}
local targetActions = {TeleportToPlayer=true, TeleportToPlot=true, ReturnPlayerToPlot=true, BringPlayer=true, RespawnPlayer=true, SpectatePlayer=true}
local simpleActions = {GetState=true, StopSpectating=true, ClearQueue=true, EmergencyReset=true}

function Policy.SanitizeMessage(message, maxCharacters)
	if type(message) ~= "string" or #message > maxCharacters * 4 then return nil end
	local count = utf8.len(message)
	if not count or count > maxCharacters then return nil end
	local output = {}
	for _, code in utf8.codes(message) do
		local whitespace = code <= 32 or code == 127 or code == 160 or code == 0x1680
			or (code >= 0x2000 and code <= 0x200F) or code == 0x2028 or code == 0x2029
			or code == 0x202F or code == 0x205F or code == 0x3000 or code == 0xFEFF
		table.insert(output, whitespace and " " or utf8.char(code))
	end
	local clean = table.concat(output):gsub("%s+", " "):match("^%s*(.-)%s*$")
	return clean ~= "" and clean or nil
end

function Policy.Validate(payload, definitions, events)
	if type(payload) ~= "table" or type(payload.Action) ~= "string" or #payload.Action > 32 then return false end
	local action = payload.Action
	local fields = {Action=true}
	if targetActions[action] then
		fields.TargetUserId = true
		local id = payload.TargetUserId
		-- Negative Studio test IDs are valid; the service must still resolve an actual Player.
		if type(id) ~= "number" or id ~= id or math.abs(id) > 2^53 or id % 1 ~= 0 then return false end
	elseif action == "Teleport" then
		fields.Destination = true
		local valid = false
		for _, destination in ipairs(definitions.Destinations) do
			if destination.Id == payload.Destination then valid = true; break end
		end
		if not valid then return false end
	elseif action == "QueueEvent" then
		fields.EventId = true
		if type(payload.EventId) ~= "string" or #payload.EventId > 40 or not events[payload.EventId] then return false end
	elseif action == "Announce" then
		fields.Message = true
		if not Policy.SanitizeMessage(payload.Message, definitions.MaxAnnouncementCharacters) then return false end
	elseif action == "Confirm" then
		fields.Token = true
		if type(payload.Token) ~= "string" or #payload.Token ~= 36 then return false end
	elseif not simpleActions[action] then
		return false
	end
	for key in pairs(payload) do if not fields[key] then return false end end
	return true
end

-- Limits are charged before authorization can yield on a group lookup.
function Policy.new(authorize, definitions, events, clock)
	local previous = {}
	clock = clock or os.clock
	return function(player, payload, ...)
		if select("#", ...) ~= 0 then return false end
		local now = clock()
		if previous[player] and now - previous[player] < 0.35 then return false end
		previous[player] = now
		if not authorize(player) then return false end
		return Policy.Validate(payload, definitions, events)
	end, function(player) previous[player] = nil end
end

return Policy
