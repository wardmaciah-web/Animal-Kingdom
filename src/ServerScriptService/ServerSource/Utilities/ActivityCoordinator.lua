-- Owned by ChallengeService. One profile ledger and one committed event stream.
local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local Knit=require(RS.Packages.Knit)
local P=require(RS.Shared.Gameplay.KingdomProgress)
local C=require(RS.Shared.Gameplay.Definitions.KingdomActivityDefinitions)
local Families=require(RS.Shared.Gameplay.Definitions.TreeFamilyDefinitions)
local Pets=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Biomes=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local Locations=require(RS.Shared.Gameplay.PetLocations)
local Variants=require(RS.Shared.Gameplay.Definitions.VariantDefinitions)
local PetMath=require(RS.Shared.Gameplay.PetMath)
local M={};M.__index=M
local function service(name)return Knit.GetService(name)end
local function now()return workspace:GetServerTimeNow()end
local function data(player)return service("PlayerDataService"):Get(player)end
local function count(t)local n=0;for _ in pairs(t)do n+=1 end;return n end
local function goal(id,kind,target,extra)
 local g={Id=id,Kind=kind,Target=target,Progress=0};for k,v in pairs(extra or {})do g[k]=v end;return g
end
function M.new(owner)
 local self=setmetatable({Owner=owner,Session=game.JobId~=""and game.JobId or Http:GenerateGUID(false),Records={},LastNotice={},StartedAt=now()},M)
 self.Routes=require(script.Parent.ActivityRoutes).new(self)
 self.World=require(script.Parent.KingdomWorldActivities).new(self)
 return self
end
function M:Publish(player)
 service("PlayerDataService"):Publish(player,"Activities","TreeMastery")
 service("PetService"):RequestSave(player)
end
function M:Queue(d,id,rewards,label)
 local a=P.Ensure(d)
 if a.Receipts[id] or a.Pending[id]then return true end
 if count(a.Pending)>=C.Limits.PendingRewards then return false end
 a.Pending[id]={Id=id,Rewards=rewards,Label=label,CreatedAt=now()};return true
end
function M:Ensure(player)
 local d=data(player);if not d then return end
 local a=P.Ensure(d);local day=d.DailyChallenges.PeriodStart
 if (a.PrunedAt or 0)+86400<now()then
  a.PrunedAt=now()
  -- All current goal/mission claims also have persistent claim state. Transport
  -- receipts outlive the seven-day cooperative inbox lifetime before pruning.
  for id,at in pairs(a.Receipts)do if type(at)=='number'and at<now()-8*86400 then a.Receipts[id]=nil end end
  for uid,at in pairs(a.MissionDays)do if at<day-8*86400 then a.MissionDays[uid]=nil end end
 end
 -- Existing Daily entries remain available as legacy progress. Journey uses the
 -- SAME daily UTC bucket supplied by ChallengeService, without duplicate grants.
 if not a.Journey or a.Journey.Day~=day then
  local old=a.Journey
  local canReset=not old or old.Claimed or not P.Complete(old.Entries) or self:Queue(d,old.Id,{Coins=C.Journey.Coins,FriendshipTokens=C.Journey.Tokens},"Unclaimed Kingdom Journey")
  if canReset then
   a.Journey={Id="Journey:"..day,Day=day,ResetAt=day+86400,Step=1,Claimed=false,Entries={
    goal("Journey:"..day..":1","Search",3,{Biome="Meadow",Text="Search three Meadow trees"}),
    goal("Journey:"..day..":2","Collect",100,{Text="Collect 100 Sanctuary Coins"}),
    goal("Journey:"..day..":3","Garden",1,{Text="Complete a Garden expedition"}),
    goal("Journey:"..day..":4","Rarity",1,{Rarity=3,Text="Find a Rare or better pet"}),
   }}
  end
 end
 for _,biome in ipairs({"Meadow","Forest"})do if Biomes.IsContentReady(biome)and d.UnlockedBiomes[biome]then
  local old=a.BiomeGoals[biome]
  if not old or old.Day~=day then
   local canReset=not old or old.Claimed or not P.Complete(old.Entries)or self:Queue(d,old.Id,{Coins=C.BiomeGoals.Coins[biome],FriendshipTokens=C.BiomeGoals.Tokens},biome.." goals")
   if canReset then
    local id="BiomeGoals:"..biome..":"..day
    a.BiomeGoals[biome]={Id=id,Day=day,Claimed=false,Entries={
     goal(id..":Search","Search",5,{Biome=biome,Text="Search five trees"}),
     goal(id..":Rarity","Rarity",1,{Biome=biome,Rarity=2,Text="Find an Uncommon or better pet"}),
     goal(id..":Heavy","Heavy",1,{Biome=biome,Ratio=1.15,Text="Find a pet at least 1.15× base weight"}),
    }}
   end
  end
 end end
 if a.Mission and not service("PetService"):FindOwned(d,a.Mission.UID)then a.Mission=nil;a.MissionMessage="Mission ended: that pet is no longer owned.";self:Publish(player)end
 if a.Route and not a.Route.Completed and a.Route.EndsAt<=now()then
  a.LastRoute={Name=a.Route.Name,Result="Time expired. All earned pets are kept."};a.Route=nil
  a.Finale=nil;self:Publish(player)
 end
 return d,a
end
function M:Claim(player,id)
 return service("PetService"):Transaction(player,function()
  local d,a=self:Ensure(player);if not d then return false,"Profile is loading."end
  if a.Receipts[id]then return true,"Reward already claimed."end
  local pending=a.Pending[id];local rewards=pending and pending.Rewards;local target
  if not rewards then
   if a.Journey and a.Journey.Id==id and not a.Journey.Claimed and P.Complete(a.Journey.Entries)then target=a.Journey;rewards={Coins=C.Journey.Coins,FriendshipTokens=C.Journey.Tokens}end
   for biome,set in pairs(a.BiomeGoals)do if set.Id==id and not set.Claimed and P.Complete(set.Entries)then target=set;rewards={Coins=C.BiomeGoals.Coins[biome],FriendshipTokens=C.BiomeGoals.Tokens}end end
   if a.Route and a.Route.Id==id and a.Route.Completed then target=a.Route;rewards=a.Route.Rewards end
  end
  if not rewards then return false,"That activity reward is not ready."end
  local ok,why=service("EconomyService"):GrantExact(player,rewards,"KingdomActivity",function()
   if target then target.Claimed=true end
   a.Receipts[id]=now();a.Pending[id]=nil
   if a.Route and a.Route.Id==id then a.LastRoute={Name=a.Route.Name,Result="Completed and claimed!"};a.Route=nil end
  end)
  if not ok then return false,why end
  self:Publish(player);return true,"Activity reward claimed!"
 end)
end
function M:Mission(player,uid,kind)
 return service("PetService"):Transaction(player,function()
  local d,a=self:Ensure(player);if not d then return false,"Profile is loading."end
  if not d.TutorialCompleted then return false,"Finish the tutorial first."end
  local pet=service("PetService"):FindOwned(d,uid)
  if not pet or pet.Level>=Variants.MaxLevel then return false,"Choose an owned pet below the level cap."end
  if a.Mission then return false,"Finish or abandon your current pet mission first."end
  local day=d.DailyChallenges.PeriodStart
  if a.MissionDays[uid]==day then return false,"This pet has completed today's mission."end
  local target,text
  if kind=="HeldSearch"then target=8;text="Search eight normal trees while this exact pet is actively held."
  elseif kind=="Garden"then target=1;text="Complete a Garden expedition with this pet."
  elseif kind=="Visits"then
   if not d.UnlockedBiomes.Forest then return false,"Unlock Forest before choosing this mission."end
   target=2;text="Visit Meadow and Forest while this exact pet is actively held."
  elseif kind=="DisplayedCollect"then target=500;text="Collect 500 Sanctuary Coins while this pet is displayed."
  else return false,"Unknown pet mission."end
  a.Mission={Id=Http:GenerateGUID(false),UID=uid,PetId=pet.PetId,Kind=kind,Target=target,Progress=0,Text=text,Seen={},Day=day,XP=C.Mission.XP}
  self:Publish(player);return true,"Pet mission started. Reward: 100 XP for this pet."
 end)
end
function M:ClaimMission(player,id)
 return service("PetService"):Transaction(player,function()
  local d,a=self:Ensure(player);local m=a and a.Mission
  if a and a.Receipts[id]then return true,"Mission already claimed."end
  if not m or m.Id~=id or m.Progress<m.Target then return false,"Mission is not complete."end
  local pet=service("PetService"):FindOwned(d,m.UID)
  if not pet then return false,"That pet is no longer owned."end
  if pet.Level>=Variants.MaxLevel then return false,"This pet is at its XP cap. The claim remains available until you abandon it."end
  pet.XP+=m.XP
  while pet.Level<Variants.MaxLevel and pet.XP>=PetMath.RequiredXP(pet.Level)do pet.XP-=PetMath.RequiredXP(pet.Level);pet.Level+=1 end
  if pet.Level>=Variants.MaxLevel then pet.XP=0 end
  a.MissionDays[m.UID]=m.Day;a.Receipts[id]=now();a.Mission=nil
  service("PetService"):Publish(player);self:Publish(player);return true,"Your mission pet earned 100 XP!"
 end)
end
function M:Abandon(player,kind,id)
 return service("PetService"):Transaction(player,function()
  local _,a=self:Ensure(player);if not a then return false,"Profile is loading."end
  local key=kind=="Mission"and "Mission"or "Route";local current=a[key]
  if not current or current.Id~=id then return false,"That activity is no longer active."end
  if current.Completed or current.Progress and current.Progress>=current.Target then return false,"Claim your completed reward first."end
  if key=="Route"and a.Finale and a.Finale.RunId==current.Id then a.Finale=nil end
  a[key]=nil;self:Publish(player);return true,"Activity abandoned. Your pets and earned income are kept."
 end)
end
function M:Committed(player,event,id,detail)
 local d,a=self:Ensure(player);if not d then return end
 if not d.TutorialCompleted then return end -- tutorial retains exclusive guidance/progress presentation
 if event=="Search"then
  if detail.OneUseRunId and a.Finale and a.Finale.RunId==detail.OneUseRunId then a.Finale=nil end
  if detail.BonusCoins and detail.BonusCoins>0 then
   -- The accepted normal search already spent at least ten times this bonus,
   -- so it made room even at the currency cap. No universal loot multiplier.
   local ok=service("EconomyService"):GrantExact(player,{Coins=detail.BonusCoins},"HotTree",function()end)
   if not ok then assert(self:Queue(d,"Hot:"..id,{Coins=detail.BonusCoins},"Rich Tree bonus"),"Rich Tree reward retained capacity invariant")end
  end
 end
 for _,set in pairs(a.BiomeGoals)do if not set.Claimed then for _,g in ipairs(set.Entries)do P.Advance(g,event,detail)end end end
 local j=a.Journey
 if j and not j.Claimed then
  local g=j.Entries[j.Step]
  if g and P.Advance(g,event,detail)and g.Progress>=g.Target then j.Step+=1 end
 end
 local m=a.Mission
 if m and m.Progress<m.Target then
  local pet=service("PetService"):FindOwned(d,m.UID);local amount=0
  if m.Kind=="HeldSearch"and event=="Search"and detail.HeldUID==m.UID then amount=1
  elseif m.Kind=="Garden"and event=="Garden"and detail.UID==m.UID then amount=1
  elseif m.Kind=="Visits"and event=="Arrival"and detail.HeldUID==m.UID and (detail.Biome=="Meadow"or detail.Biome=="Forest")and not m.Seen[detail.Biome]then m.Seen[detail.Biome]=true;amount=1
  elseif m.Kind=="DisplayedCollect"and event=="Collect"and pet and pet.Location=="Sanctuary"then amount=detail.Amount end
  m.Progress=math.min(m.Target,m.Progress+amount)
 end
 if self.Routes then self.Routes:Committed(player,d,a,event,detail)end
 if self.World then self.World:Committed(player,d,a,event,id,detail)end
end
function M:SearchEffects(player,tree,familyId)
 local d=data(player);if not d then return {}end
 local effects=self.World and self.World:SearchEffects(tree,familyId)or {}
 local a=P.Ensure(d);local f=a.Finale
 if f and f.FamilyId==familyId and f.ExpiresAt>now()then effects.WeightBias=(effects.WeightBias or 0)+C.Paw.FinaleBias;effects.OneUseRunId=f.RunId end
 return effects
end
function M:Start()
 local profiles=service("ProfileService")
 local function ready(player)
  if self:Ensure(player)then self:Publish(player)end
 end
 profiles.Loaded:Connect(ready)
 profiles.KingdomRewardReceived:Connect(function(player)self:Publish(player)end)
 for p in pairs(profiles.Profiles)do ready(p)end
 local lastBiome=setmetatable({},{__mode="k"})
 task.spawn(function()while true do
  task.wait(1)
  for p in pairs(profiles.Profiles)do if p:GetAttribute("ProfileReady")then
   local d,a=self:Ensure(p)
   if d then
    local biome=p:GetAttribute("CurrentBiome")
    local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    if root and hum and hum.Health>0 and biome~=lastBiome[p]and service("BiomeService"):IsUnlocked(p,biome)and service("BiomeService"):AtPosition(root.Position)==biome then
     lastBiome[p]=biome;self.Owner:Committed(p,"Arrival",Http:GenerateGUID(false),{Biome=biome,HeldUID=d.ActiveHeldPetUID})
    elseif biome=="Town"then lastBiome[p]=biome end
    if self.Routes then self.Routes:Tick(p,d,a)end
   end
  end end
  if self.World then self.World:Tick()end
 end end)
end
return M
