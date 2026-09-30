local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Knit=require(RS.Packages.Knit)
local Guard=require(script.Parent.Parent.Utilities.GameplayGuard)
local Streak=require(RS.Shared.Gameplay.SearchStreak)
local Biomes=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local Mastery=require(RS.Shared.Gameplay.BiomeMastery)
local Service=Knit.CreateService({Name="ProgressionService",Client={}})
local Data
local streaks=setmetatable({},{__mode="k"}) -- session-only, never restored from a profile
function Service.Client:UnlockBiome(player,id)
 if not Guard.Id(id) or not Guard.RateLimit(player,"UnlockBiome",.5) then return false end
 return Knit.GetService("BiomeService"):Unlock(player,id)
end
function Service:GetStreak(player,now)return Streak.Current(streaks[player],now or os.time())end
function Service:PublishStreak(player)
 local count,bonus=self:GetStreak(player)
 player:SetAttribute("SearchStreakCount",count);player:SetAttribute("SearchStreakBonus",bonus)
end
function Service:OnPetCommitted(player,pet,result,context)
 -- Called synchronously exactly once by PetService's committed-award boundary.
 Knit.GetService("ChallengeService"):TrackContract(player,"Pet",{Pet=pet,NewDiscovery=result.NewDiscovery,Source=context.Source,PoolId=context.PoolId})
 if context.Source=="NormalTree" and Biomes.IsContentReady(context.Biome)then
  local data=Data:Get(player);local mastery=Mastery.Ensure(data,context.Biome);mastery.Searches+=1+math.clamp(context.Search and context.Search.Mastery or 0,0,1)
  Data:Publish(player,"BiomeMastery")
  streaks[player]=Streak.Commit(streaks[player],os.time());self:PublishStreak(player)
  local detail=require(RS.Shared.Gameplay.KingdomProgress).Detail(pet)
  detail.FamilyId=context.PoolId;detail.NewDiscovery=result.NewDiscovery
  local search=context.Search or {};detail.TreeId=search.TreeId
  -- Mission ownership is evaluated at the committed outcome, before publication
  -- can select a newly acquired Held pet. Buffs retain their acceptance snapshot.
  detail.HeldUID=data.ActiveHeldPetUID
  detail.BonusCoins=search.BonusCoins;detail.Mastery=search.Mastery;detail.OneUseRunId=search.OneUseRunId;detail.HotId=search.HotId
  Knit.GetService("ChallengeService"):Committed(player,"Search",pet.UID,detail)
 else
  local detail=require(RS.Shared.Gameplay.KingdomProgress).Detail(pet);detail.Source=context.Source
  Knit.GetService("ChallengeService"):Committed(player,"Acquisition",pet.UID,detail)
 end
end
function Service:ClaimMastery(player,biome,level)
 return Knit.GetService("PetService"):Transaction(player,function()
  if not Knit.GetService("BiomeService"):IsUnlocked(player,biome)then return false,"Biome unavailable"end
  local data=Data:Get(player);local status=Mastery.Status(data,biome,level)
  if not status or status.Claimed or not status.Ready then return false,"Mastery reward unavailable"end
  local ok,why=Knit.GetService("EconomyService"):GrantExact(player,{Coins=status.Goal.Coins,FriendshipTokens=status.Goal.Tokens},"Mastery",function()
   Mastery.Ensure(data,biome).Claims[tostring(level)]=true
  end)
  if not ok then return false,why end
  Data:Publish(player,"BiomeMastery");Knit.GetService("PetService"):RequestSave(player)
  if biome=='Forest'then Knit.GetService('NotificationService'):Announce('Mastery:'..player.UserId..':'..biome..':'..level,player.DisplayName..' completed Forest mastery '..level..'!',55,'Achievement')end
  return true,"Mastery reward claimed!"
 end)
end
function Service:KnitInit()Data=Knit.GetService("PlayerDataService")end
function Service:KnitStart()
 Knit.GetService("ModifierService"):RegisterProvider("SearchStreak",function(player,key)
  if key~="Luck"then return 1 end;local _,bonus=self:GetStreak(player);return 1+bonus
 end)
 Players.PlayerRemoving:Connect(function(player)streaks[player]=nil end)
 task.spawn(function()while true do
  for _,player in ipairs(Players:GetPlayers())do if Data:Get(player)then self:PublishStreak(player)end end
  task.wait(1)
 end end)
end
return Service
