-- Temporary observer for the actual server Script environment. Never modifies profile data.
local RS=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local Knit=require(RS.Packages.Knit)
local state=Instance.new('Folder');state.Name='ProfileRepairTestAudit';state.Parent=RS
local function write(name,value) state:SetAttribute(name,Http:JSONEncode(value)) end
local ok,err=xpcall(function()
 Knit.OnStart():await()
 local player=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
 local profiles=Knit.GetService('ProfileService')
 profiles:WaitUntilProfileLoaded(player)
 local profile=assert(profiles.Profiles[player],'No profile')
 local data=assert(Knit.GetService('PlayerDataService'):Get(player),'No ready data')
 local function count(t) local n=0 for _ in pairs(t or {}) do n+=1 end return n end
 local total=0 for _ in pairs(profiles.Profiles) do total+=1 end
 local summary={ready=player:GetAttribute('ProfileReady'),state=player:GetAttribute('ProfileLoadState'),mode=player:GetAttribute('ProfileDataMode'),isMock=profile.is_mock,active=profile:IsActive(),profileCount=total,
  dataVersion=data.DataVersion,coins=data.ForestCoins,tokens=data.FriendshipTokens,currencies=data.Currencies,pets=#data.Pets,ownedPets=#data.OwnedPets,petIndex=count(data.PetIndex),biomes=count(data.UnlockedBiomes),displayed=#data.DisplayedPetIds,sanctuary=data.UncollectedSanctuaryCoins,gardenExpeditions=data.GardenExpeditions,gardenCosmetics=data.GardenCosmetics}
 write('Summary',summary);write('Data',data)
 print('[ProfileRepairTest] Ready snapshot: '..Http:JSONEncode(summary))
 profiles.Releasing:Connect(function(p) if p==player then print('[ProfileRepairTest] Releasing signal: '..p.Name) end end)
 profile.OnSessionEnd:Connect(function()
  local released=not profile:IsActive()
  write('Release',{inactive=released,removed=profiles.Profiles[player]==nil})
  print('[ProfileRepairTest] OnSessionEnd: inactive='..tostring(released)..'; serviceRemoved='..tostring(profiles.Profiles[player]==nil))
 end)
 profile.OnAfterSave:Connect(function()
  print('[ProfileRepairTest] OnAfterSave: active='..tostring(profile:IsActive())..'; mock='..tostring(profile.is_mock))
 end)
end,debug.traceback)
if not ok then write('Error',err);warn('[ProfileRepairTest] '..tostring(err)) end
