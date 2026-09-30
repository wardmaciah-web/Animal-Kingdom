local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Config = require(ReplicatedStorage.SharedSource.Datas.AnimalKingdomConfig)
local Pets = require(ReplicatedStorage.Shared.Gameplay.Definitions.PetDefinitions)
local PetStats = require(ReplicatedStorage.Shared.Gameplay.PetStats)
local Kingdom = require(ReplicatedStorage.Shared.Gameplay.KingdomProgress)
local Guard = require(script.Parent.Parent.Utilities.GameplayGuard)

local SanctuaryService = Knit.CreateService({ Name = "SanctuaryService", Client = {} })
local DataService
local PetService
local CurrencyService
local EventModifierService
local lastOnlineAccrual = {}
local joinedAt = {}

function SanctuaryService:GetIncome(data)
	local ownedById = {}
	for _, pet in ipairs(data.OwnedPets) do ownedById[pet.UniquePetId] = pet end
	local income = 0
	for _, uniqueId in ipairs(data.DisplayedPetIds) do
		local owned = ownedById[uniqueId]
		local definition = owned and Pets[owned.PetId]
		if definition and owned.Location=="Sanctuary" then income += PetStats.Income(owned) end
	end
 return math.min(income, 1e12)
end

function SanctuaryService:Accrue(player)
	local data = DataService:Get(player)
	if not data then return end
	local now = workspace:GetServerTimeNow()
	local lastOnline = lastOnlineAccrual[player]
	local weightedSeconds
	local weather = function(a,z)return EventModifierService:GetCoinWeightedSeconds(a,z)end
	if lastOnline then
		weightedSeconds = Kingdom.IncomeSeconds(data,lastOnline,now,weather)
	else
		-- Split saved offline time from time spent online before the first tick.
		local sessionStart = joinedAt[player] or now
		local offlineSeconds = math.clamp(sessionStart - (data.SanctuaryIncomeUpdatedAt or sessionStart), 0, 86_400)
		weightedSeconds = Kingdom.IncomeSeconds(data,sessionStart-offlineSeconds,sessionStart) + Kingdom.IncomeSeconds(data,sessionStart,now,weather)
	end
	lastOnlineAccrual[player] = now
	if weightedSeconds > 0 then
		DataService:Set(player, "UncollectedSanctuaryCoins", math.min(9_000_000_000_000_000, data.UncollectedSanctuaryCoins + self:GetIncome(data) * weightedSeconds))
		DataService:Set(player, "SanctuaryIncomeUpdatedAt", now)
	end
end

function SanctuaryService.Client:SetPetDisplayed(player, uniquePetId, displayed)
	if type(uniquePetId) ~= "string" or type(displayed) ~= "boolean" or not Guard.RateLimit(player, "Display", 0.15) then return false end
 return PetService:Move(player,uniquePetId,displayed and "Sanctuary" or "Inventory")
end

function SanctuaryService.Client:Collect(player)
 if not Guard.RateLimit(player,"Collect",.5) then return 0 end
 local ok,result=Knit.GetService("PlotService"):Collect(player)
 return ok and result.Amount or 0
end

function SanctuaryService:KnitStart()
 require(script.Parent.Parent.Utilities.MeadowSanctuaryDisplay).Start()
	Players.PlayerAdded:Connect(function(player) joinedAt[player] = workspace:GetServerTimeNow() end)
	Players.PlayerRemoving:Connect(function(player)
		lastOnlineAccrual[player] = nil
		joinedAt[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do joinedAt[player] = workspace:GetServerTimeNow() end
	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in ipairs(Players:GetPlayers()) do self:Accrue(player) end
		end
	end)
end

function SanctuaryService:KnitInit()
	DataService = Knit.GetService("PlayerDataService")
	PetService = Knit.GetService("PetService")
	CurrencyService = Knit.GetService("CurrencyService")
	EventModifierService = Knit.GetService("EventModifierService")
end

return SanctuaryService
