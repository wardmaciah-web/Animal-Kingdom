local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerDataService = Knit.CreateService({ Name = "PlayerDataService", Client = {} })
local ProfileService

function PlayerDataService:Get(player)
	local profile = ProfileService.Profiles[player]
	return profile and profile:IsActive() and profile.Data or nil
end

function PlayerDataService:Set(player, key, value)
	if type(key) ~= "string" or key == "Currencies" or key == "ForestCoins" or key == "FriendshipTokens" then return false end
	local data = self:Get(player)
	if not data or data[key] == nil then return false end
	ProfileService:ChangeData(player, { key }, value)
	return true
end

-- Mutations are synchronous; publishing does not wait for storage/network.
function PlayerDataService:Publish(player, ...)
 local data = self:Get(player)
 if not data then return end
 for _, key in ipairs({...}) do ProfileService:ChangeData(player, {key}, data[key]) end
end

function PlayerDataService:PublishPath(player, path)
 local value = self:Get(player)
 if not value then return end
 for _, key in ipairs(path) do value = value[key] end
 ProfileService:ChangeData(player, path, value)
end

function PlayerDataService:KnitInit()
	ProfileService = Knit.GetService("ProfileService")
end

return PlayerDataService
