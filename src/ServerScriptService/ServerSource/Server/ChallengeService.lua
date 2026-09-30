local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local Signal=require(RS.Packages.Signal)
local Contracts=require(RS.Shared.Gameplay.ContractProgress)
local ContractConfig=require(RS.Shared.Gameplay.Definitions.CollectionProgressionDefinitions).Contracts
local Http=game:GetService("HttpService")
local rng=Random.new()
local Definitions=require(RS.Shared.Gameplay.Definitions.ChallengeDefinitions)
local Kingdom=require(RS.Shared.Gameplay.KingdomProgress)
local Service=Knit.CreateService({Name="ChallengeService",Client={},Completed=Signal.new()})
local Data,Biomes,Economy,Profiles
local function period(kind,now)
 if kind=="Daily" then local start=math.floor(now/86400)*86400;return start,start+86400 end
 local start=math.floor((now+3*86400)/(7*86400))*(7*86400)-3*86400;return start,start+7*86400
end
function Service:Ensure(player,now)
 local data=Data:Get(player);if not data then return end
 local activity=Kingdom.Ensure(data)
 if not activity.LegacyDailyMigrated then
  activity.LegacyDailyMigrated=true;activity.LegacyDaily={Entries={}}
  for id,e in pairs(data.DailyChallenges.Entries or {})do
   if type(e)=="table" and (tonumber(e.Progress)or 0)>0 then activity.LegacyDaily.Entries[id]=table.clone(e)end
  end
 end
 if not activity.LegacyWeeklyMigrated then
  activity.LegacyWeeklyMigrated=true;activity.LegacyWeekly={Entries={}}
  local weekStart=period('Weekly',now or os.time());local saved=data.WeeklyChallenges
  -- Current-week entries stay in their original ledger. Only stale pre-migration
  -- progress needs a retained copy before the existing reset replaces it.
  if saved.PeriodStart~=weekStart then for id,e in pairs(saved.Entries or {})do
   if type(e)=='table'and(tonumber(e.Progress)or 0)>0 then activity.LegacyWeekly.Entries[id]=table.clone(e)end
  end end
 end
 for _,kind in ipairs({"Daily","Weekly"}) do
  local start,reset=period(kind,now or os.time());local field=kind.."Challenges";local saved=data[field]
  if saved.PeriodStart~=start or type(saved.Entries)~="table" then saved={PeriodStart=start,ResetAt=reset,Entries={}};data[field]=saved end
  for _,def in ipairs(Definitions[kind]) do
   local entry=saved.Entries[def.Id]
   if type(entry)~="table" then entry={Progress=0,Claimed=false};saved.Entries[def.Id]=entry end
   entry.Type=def.Type;entry.Target=def.Target;entry.Progress=math.clamp(tonumber(entry.Progress) or 0,0,def.Target)
  end
 end
 Contracts.Ensure(data,now or os.time(),rng,function()return Http:GenerateGUID(false)end)
 return data
end
function Service:Track(player,event,amount,biome)
 local data=self:Ensure(player);if not data or (biome and not Biomes:IsUnlocked(player,biome)) then return end
 data.Stats[event]=(data.Stats[event] or 0)+amount
 for _,kind in ipairs({"LegacyDaily","LegacyWeekly","Weekly"}) do
  for _,def in ipairs(Definitions[kind=="LegacyDaily"and "Daily"or "Weekly"]) do
   local entries=kind=='Weekly'and data.WeeklyChallenges.Entries or data.Activities[kind].Entries
   local entry=entries[def.Id]
   if entry and def.Type==event and not entry.Claimed then
    local previous=entry.Progress;entry.Progress=math.min(def.Target,entry.Progress+amount)
    if previous<def.Target and entry.Progress>=def.Target then self.Completed:Fire(player,def.DisplayName) end
   end
  end
 end
 Data:Publish(player,"Activities","DailyChallenges","WeeklyChallenges","Stats")
end
function Service:TrackContract(player,event,detail)
 local data=self:Ensure(player);if not data then return end
 if Contracts.Track(data,event,detail)then Data:Publish(player,"Contracts");Knit.GetService("PetService"):RequestSave(player)end
end
-- Identities come from committed server operations, never client counters.
function Service:Committed(player,event,id,detail)
 local data=self:Ensure(player);if not data or not Kingdom.FirstEvent(data,event..":"..id)then return false end
 detail=detail or {}
 if event=="Search"then
  local pet=Knit.GetService("PetService"):FindOwned(data,detail.UID)
  if pet then Kingdom.RecordFamily(data,detail.FamilyId,pet,detail.Mastery)end
 end
 if self.Activities then self.Activities:Committed(player,event,id,detail)end
 Data:Publish(player,"Activities","TreeMastery");Knit.GetService("PetService"):RequestSave(player)
 return true
end
function Service:GetSearchEffects(player,tree,familyId)
 return self.Activities and self.Activities:SearchEffects(player,tree,familyId)or {}
end
function Service:ClaimContract(player,id)
 return Knit.GetService("PetService"):Transaction(player,function()
  local data=self:Ensure(player);if not data then return false,"Profile is loading"end
  for _,receipt in ipairs(data.Contracts.Receipts)do if receipt.Id==id then return true,"Contract reward already claimed."end end
  local index,entry;for i,e in ipairs(data.Contracts.Entries)do if type(e)=="table" and e.Id==id then index=i;entry=e;break end end
  if not entry or entry.Progress<entry.Target then return false,"Contract is not complete."end
  local ok,why=Economy:GrantExact(player,{Coins=entry.Coins,FriendshipTokens=entry.Tokens},"Contract",function()
   table.insert(data.Contracts.Receipts,{Id=id,ClaimedAt=os.time(),Coins=entry.Coins,Tokens=entry.Tokens})
   while #data.Contracts.Receipts>ContractConfig.ReceiptLimit do table.remove(data.Contracts.Receipts,1)end
   data.Contracts.Entries[index]=false
   Contracts.Ensure(data,os.time(),rng,function()return Http:GenerateGUID(false)end)
  end)
  if not ok then return false,why end
  Data:Publish(player,"Contracts");Knit.GetService("PetService"):RequestSave(player)
  return true,"Contract claimed — a new objective is ready!"
 end)
end
function Service:Claim(player,kind,id)
 if kind=="Contracts"then return self:ClaimContract(player,id)end
 if kind=="LegacyDaily"or kind=="Daily"or kind=='LegacyWeekly'then
  return Knit.GetService("PetService"):Transaction(player,function()
   local ledger=kind=='LegacyWeekly'and 'LegacyWeekly'or 'LegacyDaily'
   local data=self:Ensure(player);local entry=data and data.Activities[ledger].Entries[id]
   local def;for _,d in ipairs(Definitions[kind=='LegacyWeekly'and 'Weekly'or 'Daily'])do if d.Id==id then def=d end end
   if not entry or not def or entry.Progress<def.Target then return false,"Legacy reward unavailable."end
   if entry.Claimed then return true,"Legacy reward already claimed."end
   local ok,why=Economy:GrantExact(player,{Coins=def.Coins,FriendshipTokens=def.Tokens},"Challenge",function()entry.Claimed=true end)
   if not ok then return false,why end
   Knit.GetService("PetService"):AddEquippedXP(player,25)
   Data:Publish(player,"Activities");Knit.GetService("PetService"):RequestSave(player)
   return true,"Retained challenge reward claimed!"
  end)
 end
 if not Definitions[kind] then return false,"Invalid challenge period" end
 local data=self:Ensure(player);if not data then return false,"Data not ready" end
 local current=player:GetAttribute("CurrentBiome")
 if current and current~="Town" and not Biomes:IsUnlocked(player,current) then return false,"Biome locked" end
 local def;for _,candidate in ipairs(Definitions[kind]) do if candidate.Id==id then def=candidate end end
 local entry=def and data[kind.."Challenges"].Entries[id]
 if not entry or entry.Claimed or entry.Progress<def.Target then return false,"Challenge unavailable" end
 local ok,why=Economy:GrantExact(player,{Coins=def.Coins,FriendshipTokens=def.Tokens},"Challenge",function()entry.Claimed=true end)
 if not ok then return false,why end
 Knit.GetService("PetService"):AddEquippedXP(player,25)
 Data:Publish(player,kind.."Challenges");return true,"Challenge reward claimed!"
end
function Service:ObserveWeather(player)
 local data=Data:Get(player);if not data then return end
 local state=Knit.GetService("WeatherEventService"):GetCurrentState()
 if state.Phase~="Event" then return end
 local key=state.EventId..":"..tostring(state.StartedAt)
 if data.Stats.LastWeatherKey==key then return end
 local biome=player:GetAttribute("CurrentBiome")
 if biome and biome~="Town" and not Biomes:IsUnlocked(player,biome) then return end
 data.Stats.LastWeatherKey=key;self:Track(player,"Weather",1)
end
function Service:KnitInit()
 Data=Knit.GetService("PlayerDataService");Biomes=Knit.GetService("BiomeService");Economy=Knit.GetService("EconomyService");Profiles=Knit.GetService("ProfileService")
end
function Service:KnitStart()
 self.Activities=require(script.Parent.Parent.Utilities.ActivityCoordinator).new(self)
 local function ready(player) self:Ensure(player);Data:Publish(player,"DailyChallenges","WeeklyChallenges","Contracts");self:ObserveWeather(player) end
 Profiles.Loaded:Connect(ready);for player in pairs(Profiles.Profiles) do ready(player) end
 Knit.GetService("ResourceService").Harvested:Connect(function(player,biome) self:Track(player,"Gather",1,biome) end)
 Knit.GetService("EggService").Hatched:Connect(function(player,count,biome) self:Track(player,"Hatch",count,biome) end)
 Knit.GetService("PlotService").Collected:Connect(function(player,credited)
  self:TrackContract(player,"Collector",{Amount=credited})
  self:Committed(player,"Collect",Http:GenerateGUID(false),{Amount=credited})
 end)
 Knit.GetService("GardenExpeditionService").Settled:Connect(function(player,tripId,uid)
  self:TrackContract(player,"Garden",{});self:Committed(player,"Garden",tripId,{UID=uid})
 end)
 Biomes.Unlocked:Connect(function(player,biome) self:Track(player,"UnlockBiome",1,biome);self:Ensure(player);Data:Publish(player,"Contracts")end)
 Economy.Changed:Connect(function(player,currency,amount,reason)
  if amount<=0 or reason=="Challenge" or reason=="Index" or reason=="Refund" or reason=="Contract" or reason=="Mastery" or reason=="KingdomActivity" or reason=="HotTree" then return end
  if currency=="Coins" then self:Track(player,"EarnCoins",amount)
  elseif currency=="FriendshipTokens" then self:Track(player,"EarnTokens",amount) end
 end)
 RS:WaitForChild("WeatherState").AttributeChanged:Connect(function(attribute)
  if attribute=="Phase" or attribute=="EventId" or attribute=="StartedAt" then task.defer(function() for player in pairs(Profiles.Profiles) do self:ObserveWeather(player) end end) end
 end)
 task.spawn(function()
  while true do task.wait(60);for player in pairs(Profiles.Profiles) do ready(player) end end
 end)
 self.Activities:Start()
end
return Service
