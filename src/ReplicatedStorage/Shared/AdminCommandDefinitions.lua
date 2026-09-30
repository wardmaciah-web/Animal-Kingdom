local cameras = require(script.Parent.AdminCameraDefinitions)
local destinations = {}
for _, camera in ipairs(cameras) do
	if camera.Id ~= "HighOverview" then
		table.insert(destinations, {Id = camera.Id, DisplayName = camera.DisplayName})
	end
end
table.insert(destinations, {Id = "AdminRoom", DisplayName = "ADMIN ROOM"})

return table.freeze({
	Destinations = destinations,
	MaxAnnouncementCharacters = 150,
	ActivityLimit = 20,
	ConfirmationLifetime = 15,
	Panels = {"PlayerControl", "ServerStatus", "Announcements", "Teleports", "EventQueue", "ActivityLog"},
})
