local Biomes=require(game:GetService("ReplicatedStorage").Shared.Gameplay.Definitions.BiomeDefinitions)
local Handler={}

-- Dependencies let Studio tests exercise the real request policy without editing saved profiles.
function Handler.new(profiles, markers, landing, destinations, send, clock, onLanded)
	local lastRequest={}
	clock=clock or os.clock
	local function handle(player,name,...)
		if type(name)~="string" or not destinations[name] or select("#",...)~=0 then return end
		local now=clock()
		if lastRequest[player] and now-lastRequest[player]<.75 then return end
		lastRequest[player]=now
		if not Biomes.IsContentReady(destinations[name]) then send(player,name,false,Biomes.ComingSoonMessage);return end
		local profile=profiles.Profiles[player]
		local owned=profile and profile.Data and profile.Data.UnlockedBiomes
		if type(owned)~="table" or owned[destinations[name]]~=true then send(player,name,false); return end
		local marker=markers:FindFirstChild(name)
		local floor=landing.FindFloor(destinations[name])
		if not marker or not marker:IsA("BasePart") or not floor then send(player,name,false); return end
		local success=landing.Move(player.Character,marker,floor)
		if success and onLanded then onLanded(player,destinations[name]) end
		send(player,name,success)
	end
	return handle,function(player) lastRequest[player]=nil end
end
return Handler
