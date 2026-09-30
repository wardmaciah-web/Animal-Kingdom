local ActivityLog = {}
ActivityLog.__index = ActivityLog

function ActivityLog.new(limit)
	return setmetatable({entries = {}, limit = limit or 20}, ActivityLog)
end

function ActivityLog:Add(player, message)
	table.insert(self.entries, 1, {Time = os.time(), Username = player.Name, UserId = player.UserId, Message = message})
	while #self.entries > self.limit do table.remove(self.entries) end
end

function ActivityLog:Snapshot()
	local snapshot = {}
	for _, entry in ipairs(self.entries) do table.insert(snapshot, table.clone(entry)) end
	return snapshot
end

return ActivityLog
