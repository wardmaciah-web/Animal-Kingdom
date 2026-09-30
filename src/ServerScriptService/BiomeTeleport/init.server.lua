local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local destinations=require(script.Destinations)
local Landing=require(script.Landing)
local profiles=require(ServerScriptService:WaitForChild("ServerSource"):WaitForChild("Server"):WaitForChild("ProfileService"))
local folder=ReplicatedStorage:FindFirstChild("AnimalKingdomRemotes")
if not folder then folder=Instance.new("Folder"); folder.Name="AnimalKingdomRemotes"; folder.Parent=ReplicatedStorage end
local remote=folder:FindFirstChild("TeleportToBiome")
if not remote then remote=Instance.new("RemoteEvent"); remote.Name="TeleportToBiome"; remote.Parent=folder end
assert(remote:IsA("RemoteEvent"),"TeleportToBiome must be a RemoteEvent")
local markers=Landing.EnsureMarkers(destinations)
local handle,forget=require(script.RequestHandler).new(profiles,markers,Landing,destinations,function(player,name,success,message)
	remote:FireClient(player,name,success,message)
end,nil,function(player,biome)
 local Knit=require(ReplicatedStorage.Packages.Knit)
 Knit.GetService('GardenExpeditionService'):LeaveGarden(player)
 player:SetAttribute('CurrentBiome',biome)
end)
remote.OnServerEvent:Connect(handle)
Players.PlayerRemoving:Connect(forget)
-- Map generation may finish after this script starts; fill missing markers without duplicates.
task.spawn(function()
	for _=1,12 do
		local complete=true
		for name in pairs(destinations) do
			local marker=markers:FindFirstChild(name)
			if not marker or not marker:IsA("BasePart") then complete=false;break end
		end
		if complete then break end
		task.wait(5)
		Landing.EnsureMarkers(destinations)
	end
end)
