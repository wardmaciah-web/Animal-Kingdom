local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Knit = require(ReplicatedStorage.Packages.Knit)

local ProfileService = Knit.CreateService({
	Name = "ProfileService",
	Client = {
		GetData = Knit.CreateSignal(),

		--[[
			@description Use this for client to reduce network receive data, this updates DataController.Data
		
			Note: If you use :Connect() and want to retrieve updated data, ensure to add a task.wait() 
			at least for the DataController.Data to update.
		]]
		UpdateSpecificData = Knit.CreateSignal(),
	},

	UpdateSpecificData = Signal.new(),
})

local ActualProfileStore =
	require(ServerScriptService:WaitForChild("ServerSource"):WaitForChild("Externals"):WaitForChild("ProfileStore"))
local ProfileTemplate = require(ReplicatedStorage.SharedSource.Datas.ProfileTemplate)
local AnimalKingdomConfig = require(ReplicatedStorage.SharedSource.Datas.AnimalKingdomConfig)
local PetDatabase = require(ReplicatedStorage.SharedSource.Datas.PetDatabase)
local MutationDatabase = require(ReplicatedStorage.SharedSource.Datas.MutationDatabase)

local STORE_NAME = "OriginalData1"
local PlayerProfileStore
local StudioMock = false
local StudioSeeded = {}

local Profiles = {} -- [player] = profile
local Loading = {}
local DataRequestPending, LastDataRequest = {}, {}
local LOAD_TIMEOUT = 120
ProfileService.Profiles = Profiles

local Migrations = require(ReplicatedStorage.Shared.Gameplay.ProfileMigrations)
local HttpService = game:GetService("HttpService")
ProfileService.Loaded = Signal.new()
ProfileService.Releasing = Signal.new()
ProfileService.KingdomRewardReceived = Signal.new()
-- Uses the existing OriginalData1 ProfileStore inbox, including its mock store.
-- This is server-only and never exposed as a client method.
function ProfileService:QueueKingdomReward(userId,message)
 assert(type(userId)=="number"and userId%1==0 and userId>0,"Invalid reward recipient")
 assert(type(message)=="table"and message.Kind=="KingdomCoop"and type(message.Id)=="string"and #message.Id<=120,"Invalid cooperative receipt")
 assert(message.Coins==200 and message.Tokens==3,"Unexpected cooperative reward")
 return PlayerProfileStore:MessageAsync("Player_"..userId,message)
end
local function attachKingdomInbox(player,profile)
 profile:MessageHandler(function(message,processed)
  if type(message)~="table"or message.Kind~="KingdomCoop"then return end
  if type(message.Id)~="string"or message.Coins~=200 or message.Tokens~=3 or type(message.ExpiresAt)~="number"then processed();return end
  local activity=require(ReplicatedStorage.Shared.Gameplay.KingdomProgress).Ensure(profile.Data)
  if activity.Receipts[message.Id]or activity.Pending[message.Id]then processed();return end
  -- A delivered, qualified reward stays claimable, including while the player's
  -- pending list is full. Transport retry deadlines must not erase earned money.
  local count=0;for _ in pairs(activity.Pending)do count+=1 end
  -- Leave it in the existing inbox when claims are full. A later profile load
  -- reconciles it; never consume the message without retaining the reward.
  if count>=32 then return end
  activity.Pending[message.Id]={Id=message.Id,Rewards={Coins=message.Coins,FriendshipTokens=message.Tokens},Label="Cooperative Kingdom Goal",CreatedAt=message.CreatedAt}
  processed();profile:Save();ProfileService.KingdomRewardReceived:Fire(player)
 end)
end
local function NormalizeAnimalKingdomData(data)
 Migrations.Apply(data, function() return HttpService:GenerateGUID(false) end)
end


-- Work on a copy: a failed preparation must never save a half-migrated profile.
local function copyData(value, copied)
 if type(value) ~= "table" then return value end
 copied = copied or {}
 if copied[value] then return copied[value] end
 local result = {}
 copied[value] = result
 for key, child in pairs(value) do result[key] = copyData(child, copied) end
 return result
end

local function validateSavedData(value, path, visiting)
 local kind = typeof(value)
 if kind == "nil" or kind == "string" or kind == "boolean" then return end
 if kind == "number" then
  assert(value == value and math.abs(value) < math.huge, "Non-finite saved number at " .. path)
  return
 end
 assert(kind == "table", "Unsupported saved " .. kind .. " at " .. path)
 visiting = visiting or {}
 assert(not visiting[value], "Cyclic saved table at " .. path)
 visiting[value] = true
 local numeric, strings, maxIndex, count = false, false, 0, 0
 for key, child in pairs(value) do
  if type(key) == "number" then
   assert(key >= 1 and key % 1 == 0, "Invalid array key at " .. path)
   numeric = true; maxIndex = math.max(maxIndex, key); count += 1
  else
   assert(type(key) == "string", "Unsupported saved key at " .. path)
   strings = true
  end
  validateSavedData(child, path .. "." .. tostring(key), visiting)
 end
 assert(not (numeric and strings), "Mixed array/dictionary at " .. path)
 assert(not numeric or count == maxIndex, "Sparse saved array at " .. path)
 visiting[value] = nil
end

local function seedStudioSnapshot(player, profile)
 local key = "Player_" .. player.UserId
 if not StudioMock or StudioSeeded[key] then return end
 -- Honor the existing mock flag without hiding schema incompatibility behind a new save.
 -- Read the SAME existing key once; acquire no live session and write no player data.
 if ActualProfileStore.DataStoreState == "Access" then
  local raw = game:GetService("DataStoreService"):GetDataStore(STORE_NAME):GetAsync(key)
  if raw ~= nil then
   assert(type(raw) == "table" and type(raw.Data) == "table", "Invalid stored profile envelope for Studio snapshot")
   profile.Data = copyData(raw.Data)
   player:SetAttribute("StudioProfileSnapshot", true)
   print(string.format("[ProfileService] Studio read-only snapshot: %s/%s; saved version=%s", STORE_NAME, key, tostring(raw.Data.DataVersion)))
  else
   player:SetAttribute("StudioProfileSnapshot", false)
   print("[ProfileService] No saved profile; using in-memory template for " .. player.Name)
  end
 else
  player:SetAttribute("StudioProfileSnapshot", false)
  print("[ProfileService] Studio API unavailable; using in-memory template (no persistent writes)")
 end
 StudioSeeded[key] = true
end

local function DataSuccessfullyLoaded(player)
	local profile = Profiles[player]
	if profile and profile.Data.SanctuaryIncomeUpdatedAt == 0 then
		profile.Data.SanctuaryIncomeUpdatedAt = os.time()
	end
end

local function HandlePlayerAdded(player)
	if Loading[player] or Profiles[player] or not player:IsDescendantOf(Players) then return end
	Loading[player] = true
	player:SetAttribute("ProfileReady", false)
	player:SetAttribute("ProfileLoadState", "Loading")
	player:SetAttribute("ProfileDataMode", StudioMock and "StudioMockSnapshot" or "ExistingStore")
	local started = os.clock()
	local ok, profile = pcall(function()
		return PlayerProfileStore:StartSessionAsync("Player_" .. player.UserId, {
			-- Supplying Cancel replaces ProfileStore's default timeout, so retain
			-- a bounded load while also releasing requests for departed players.
			Cancel = function()
				return not player:IsDescendantOf(Players) or os.clock() - started >= LOAD_TIMEOUT
			end,
		})
	end)
	if not ok then
		Loading[player] = nil
		player:SetAttribute("ProfileLoadState", "Failed")
		warn("[ProfileService] Load failed for " .. player.Name .. ": " .. tostring(profile))
		if player:IsDescendantOf(Players) then player:Kick("Your data could not be loaded. Please rejoin.") end
		return
	end

	if profile ~= nil then
		local originalData = profile.Data
		local stage = "StudioSnapshot"
		local savedVersion = originalData.DataVersion
		local prepared, issue = xpcall(function()
			seedStudioSnapshot(player, profile)
			originalData = profile.Data
			savedVersion = originalData.DataVersion
			profile.Data = copyData(originalData)
			stage = "AddUserId"
			profile:AddUserId(player.UserId)
			stage = "Reconcile"
			profile:Reconcile()
			stage = "Migrate"
			NormalizeAnimalKingdomData(profile.Data)
			stage = "ValidateSavedTypes"
			validateSavedData(profile.Data, "Profile")
		end, debug.traceback)
		if not prepared then
			profile.Data = originalData
			Loading[player] = nil
			player:SetAttribute("ProfileLoadState", "Failed")
			warn(string.format("[ProfileService] Data preparation failed for %s; stage=%s; store=%s; saved=%s; supported=%s; mock=%s\n%s",
				player.Name, stage, STORE_NAME, tostring(savedVersion), tostring(Migrations.Version), tostring(StudioMock), tostring(issue)))
			profile:EndSession()
			if player:IsDescendantOf(Players) then player:Kick("Your data could not be prepared. Please rejoin.") end
			return
		end

		-- Add MetaData for backwards compatibility
		if not profile.MetaData then
			profile.MetaData = {
				ProfileCreateTime = profile.FirstSessionTime,
				SessionLoadCount = profile.SessionLoadCount,
				ActiveSession = profile.Session,
			}
		end

		profile.OnSessionEnd:Connect(function()
			print("[ProfileService] Session released: " .. player.Name .. "; mock=" .. tostring(StudioMock))
			player:SetAttribute("ProfileReady", false)
			player:SetAttribute("ProfileLoadState", "Released")
			if Profiles[player] ~= profile then return end
			Profiles[player] = nil
			-- The profile could've been loaded on another Roblox server
			if player:IsDescendantOf(Players) then player:Kick("Your data session ended. Please rejoin.") end
		end)

		if player:IsDescendantOf(Players) then
			Profiles[player] = profile
			Loading[player] = nil
			attachKingdomInbox(player,profile)
			DataSuccessfullyLoaded(player)
			player:SetAttribute("ProfileReady", true)
			player:SetAttribute("ProfileLoadState", "Ready")
			print(string.format("[ProfileService] Ready: %s; version=%d; mock=%s; %.2fs", player.Name, profile.Data.DataVersion, tostring(StudioMock), os.clock() - started))
			ProfileService.Loaded:Fire(player, profile.Data)
		else
			-- Player left before the profile loaded
			Loading[player] = nil
			profile:EndSession()
		end
	else
		Loading[player] = nil
		player:SetAttribute("ProfileLoadState", "Failed")
		warn(string.format("[ProfileService] No session for %s after %.2fs; timeout=%ds; mock=%s", player.Name, os.clock() - started, LOAD_TIMEOUT, tostring(StudioMock)))
		-- The profile couldn't be loaded possibly due to other
		-- Roblox servers trying to load this profile at the same time
		if player:IsDescendantOf(Players) then player:Kick("Your data could not be loaded. Please rejoin.") end
	end
end

local function HandlePlayerRemoving(player)
	DataRequestPending[player], LastDataRequest[player] = nil, nil
	Loading[player] = nil
	player:SetAttribute("ProfileReady", false)
	player:SetAttribute("ProfileLoadState", "Releasing")
	local profile = Profiles[player]
	ProfileService.Releasing:Fire(player, profile and profile.Data)
	if profile ~= nil then
		-- Clear ownership before EndSession fires its callback. Normal departures
		-- must not be treated as a stolen session.
		Profiles[player] = nil
		profile:EndSession()
	end
end

function ProfileService:WaitUntilProfileLoaded(player)
	while not Profiles[player] and player:IsDescendantOf(Players)
		and player:GetAttribute("ProfileLoadState") ~= "Failed"
		and player:GetAttribute("ProfileLoadState") ~= "Released" do
		task.wait(0.1)
	end
end

function ProfileService:GetProfile(player)
	if player == nil then
		warn("Player instance is nil when getting profile")
		return nil
	end

	if not Profiles[player] then
		ProfileService:WaitUntilProfileLoaded(player)
	end

	local profile = Profiles[player]
	return profile, profile and profile.Data
end

function ProfileService:ChangeData(player, redirectories, newValue)
	local profile, profileData = ProfileService:GetProfile(player)

	if not profileData then
		warn("Profile data not found for player: " .. (player.Name or "Unknown"))
		return
	end

	local directData = profileData

	-- Navigate through the redirectories path
	for i = 1, #redirectories do
		if not directData[redirectories[i]] and i ~= #redirectories then
			local redirectoriesPath = "profileData"
			for j = 1, i do
				redirectoriesPath = redirectoriesPath .. "." .. redirectories[j]
			end
			error(
				"'"
					.. redirectoriesPath
					.. "' table does not exist. ALWAYS PREVENT THIS BY MAKING TABLES INSIDE PROFILETEMPLATE."
			)
			return
		end

		if i ~= #redirectories then
			directData = directData[redirectories[i]]
		end
	end

	-- Set the new value
	directData[redirectories[#redirectories]] = newValue

	-- Fire update signals
	ProfileService.Client.UpdateSpecificData:Fire(player, redirectories, newValue)
	ProfileService.UpdateSpecificData:Fire(player, redirectories, newValue)
end

local publicRequestAt = setmetatable({}, { __mode = "k" })
local function allowPublicRead(player)
 local now = os.clock()
 if publicRequestAt[player] and now - publicRequestAt[player] < .5 then return false end
 publicRequestAt[player] = now
 return true
end
function ProfileService.Client:GetOtherPlayer_ProfileData(player, otherPlayer)
 if not allowPublicRead(player) or typeof(otherPlayer) ~= "Instance" or not otherPlayer:IsA("Player") or not otherPlayer:IsDescendantOf(Players) then return nil end
 local profile = Profiles[otherPlayer]
 if not profile then return nil end
 return {PetIndex=profile.Data.PetIndex, NumNomIndex=profile.Data.NumNomIndex}
end
function ProfileService.Client:GetProfileAge(player)
 if not allowPublicRead(player) then return 0 end
 local profile = Profiles[player]
 return profile and os.time() - profile.FirstSessionTime or 0
end

function ProfileService:KnitStart()
	-- Subscribe before taking the snapshot; Loading also guards duplicate starts.
	Players.PlayerAdded:Connect(HandlePlayerAdded)
	Players.PlayerRemoving:Connect(HandlePlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(HandlePlayerAdded, player)
	end

	-- The vendor library owns final saves; also release explicit mocks on shutdown.
	game:BindToClose(function()
		for player in pairs(Profiles) do HandlePlayerRemoving(player) end
	end)

	-- Handle client data requests
	ProfileService.Client.GetData:Connect(function(player)
		local now = os.clock()
		if DataRequestPending[player] or (LastDataRequest[player] and now - LastDataRequest[player] < 1) then return end
		DataRequestPending[player], LastDataRequest[player] = true, now
		ProfileService:WaitUntilProfileLoaded(player)
		local _, profileData = ProfileService:GetProfile(player)
		DataRequestPending[player] = nil
		if profileData and player:IsDescendantOf(Players) then ProfileService.Client.GetData:Fire(player, profileData) end
	end)
end

function ProfileService:KnitInit()
	local store = ActualProfileStore.New(STORE_NAME, ProfileTemplate)
	StudioMock = RunService:IsStudio() and script:GetAttribute("AKUseMockProfiles") ~= false
	PlayerProfileStore = StudioMock and store.Mock or store
	print("[ProfileService] Mode: " .. (StudioMock and "Studio mock with read-only saved snapshot" or "existing store " .. STORE_NAME))
end

return ProfileService
