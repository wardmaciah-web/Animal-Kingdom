local PlotLocator = require(script.Parent.Parent.PlotLocator)
local PlotStatus = {}

-- Read the ownership attributes maintained by AK_PlotAssignment. Never assign,
-- initialize, or repair a plot from the admin tools.
function PlotStatus.GetSnapshot()
	local plots = PlotLocator.getPlots()
	local claimed = 0
	for _, plot in ipairs(plots) do
		if type(plot:GetAttribute("Claimed")) ~= "boolean" or type(plot:GetAttribute("OwnerUserId")) ~= "number" then
			return {Available = false}, plots
		end
		if plot:GetAttribute("Claimed") then claimed += 1 end
	end
	return {Available = #plots > 0, Claimed = claimed, Total = #plots}, plots
end

function PlotStatus.GetPlayerPlot(player, plots)
	for _, plot in ipairs(plots or PlotLocator.getPlots()) do
		if plot:GetAttribute("Claimed") == true and plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot
		end
	end
	return nil
end

function PlotStatus.GetSpawn(plot)
	for _, name in ipairs({"PlotSpawn", "PlayerSpawn", "SpawnPoint", "Spawn", "SpawnLocation"}) do
		local marker = plot:FindFirstChild(name, true)
		if marker and marker:IsA("BasePart") then return marker end
	end
	return nil
end

return PlotStatus
