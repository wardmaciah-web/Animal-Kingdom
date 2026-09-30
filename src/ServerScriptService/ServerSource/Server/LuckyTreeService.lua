local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local Knit=require(RS.Packages.Knit)
local Config=require(RS.Shared.Gameplay.Definitions.LuckyTreeDefinitions)
local Rules=require(RS.Shared.Gameplay.LuckyTreeRules)
local Biomes=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local PetDefs=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Models=require(RS.Shared.Gameplay.PetModelResolver)
local Shake=require(RS.Shared.Gameplay.TreeShakeMotion)
local Placement=require(script.Parent.Parent.Utilities.LuckyTreePlacement)
local Guard=require(script.Parent.Parent.Utilities.GameplayGuard)
local Service=Knit.CreateService({Name="LuckyTreeService",Client={}})
local Data,Pets,Economy
local rng=Random.new();local prepared={};local active;local nextAt
local status={Ready=false,AutomaticEnabled=false,Issues={}}
local function now()return workspace:GetServerTimeNow()end
local function receiptFor(entry,id)
 if entry then for _,r in ipairs(entry.Receipts)do if r.RequestId==id then return r end end end
end
function Service:Validate()
 local issues={}
 for _,biome in ipairs({"Meadow","Forest"})do
  local def=Config.Biomes[biome];local pet=def.SecretPetId and PetDefs[def.SecretPetId]
  if not Biomes.IsContentReady(biome)then table.insert(issues,biome.." is not released.")end
  if not pet or pet.Biome~=biome or pet.Rarity~="Secret" or not Models.Resolve(def.SecretPetId)then table.insert(issues,biome..": valid real SecretPetId required.")end
  local template,why=Placement.Prepare(biome)
  if not template then table.insert(issues,why)else
   if prepared[biome]then prepared[biome]:Destroy()end;prepared[biome]=template
   -- Clients preload the replicated templates before announcing the event.
  end
 end
 status={Ready=#issues==0,AutomaticEnabled=Config.AutomaticEnabled and #issues==0,Issues=issues}
 return status
end
function Service:GetStatus()return status end
function Service:GetState(player)
 if not active then return {Active=false}end
 local data=Data:Get(player);local entry=data and Rules.Event(data,active.EventId,false)
 local pending;if entry then for _,r in ipairs(entry.Receipts)do if not r.Committed then pending=r.RequestId;break end end end
 return {Active=true,PendingRequestId=pending,EventId=active.EventId,Biome=active.Biome,EndsAt=active.EndsAt,Used=entry and entry.Used or 0}
end
function Service:Sync(player)
 if not Data:Get(player)then return end
 local state=self:GetState(player)
 player:SetAttribute("LuckyTreeEventId",state.EventId or "");player:SetAttribute("LuckyTreeTriesUsed",state.Used or 0)
 player:SetAttribute('LuckyTreeBiome',state.Biome or '');player:SetAttribute('LuckyTreeEndsAt',state.EndsAt or 0)
 self.StateRemote:FireClient(player,state)
end
function Service:Spawn(biome)
 if active then return false,"A Lucky Tree is already active."end
 if not status.Ready or not prepared[biome]then return false,"Lucky Tree prerequisites are not ready."end
 local tree,prompt,position=Placement.Place(biome,prepared[biome],rng)
 if not tree then return false,prompt end
 local event={EventId=Http:GenerateGUID(false),Biome=biome,EndsAt=now()+Config.Lifetime,Tree=tree,Prompt=prompt,Position=position,BusyUntil=0}
 tree.Name=Config.Biomes[biome].TemplateName;tree:SetAttribute("LuckyEventId",event.EventId)
 prompt:SetAttribute("LuckyEventId",event.EventId);prompt:SetAttribute("LuckyBiome",biome)
 tree.Parent=workspace
 event.Pose=Shake.Capture(tree);tree:SetAttribute("LuckyRestorationPivot",event.Pose.Pivot) -- final placement/collision precedes restoration capture
 active=event
 Knit.GetService('NotificationService'):Announce('LuckySpawn:'..event.EventId,'A Lucky Tree has appeared in '..biome..'! Three free tries each • 5% Secret / 40% Coins / 55% Luck.',100,'LuckyTree')
 for _,player in ipairs(Players:GetPlayers())do self:Sync(player)end
 return true,event.EventId
end
function Service:EndEvent()
 if not active then return end
 if active.BusyUntil>now()then active.Prompt.Enabled=false;return end
 if active.Connection then active.Connection:Disconnect()end
 active.Tree:Destroy();active=nil
 for _,player in ipairs(Players:GetPlayers())do self:Sync(player)end
 nextAt=now()+rng:NextInteger(Config.DelayMin,Config.DelayMax)
end
function Service:PresentShake(event)
 if not event.Tree then return end
 event.BusyUntil=now()+Config.ShakeSeconds
 local started=now()
 event.Connection=RunService.Heartbeat:Connect(function()
  local elapsed=now()-started
  if elapsed>=Config.ShakeSeconds or not event.Tree.Parent then
   event.Connection:Disconnect();event.Connection=nil;Shake.Restore(event.Pose)
  else event.Tree:PivotTo(Shake.Pose(event.Pose.Pivot,elapsed))end
 end)
 local remotes=RS:FindFirstChild("AnimalKingdomRemotes")
 if remotes then remotes.GatherVisual:FireAllClients(0,event.Position,Config.ShakeSeconds,event.Tree)end
end
-- Reconcile the accepted result, never reroll. All balance/ownership/attempt changes
-- below are synchronous under PetService's existing per-player transaction lock.
function Service:PrepareReceipt(player,receipt)
 if receipt.Result then return true end
 local def=Config.Biomes[receipt.Biome];local result
 if receipt.Category=="Secret"then
  if not Models.Resolve(def.SecretPetId)then return false,"The accepted Secret reward is waiting for its real model."end
  local pet=Knit.GetService("EggService"):CreateRewardPet(player,def.SecretPetId,receipt.Biome)
  if not pet then return false,"The accepted Secret reward is still being prepared."end
  result={Kind="Hatch",Source="LuckyTree",Results={{Pet=pet}},Duration=Config.SecretRevealSeconds,PresentationDelay=Config.ShakeSeconds}
 elseif receipt.Category=="Coins"then
  result={Kind="LuckyReward",Category="Coins",Amount=def.Coins,Text="+"..require(RS.Shared.Gameplay.PetNumberFormat).Number(def.Coins).." Forest Coins",PresentationDelay=Config.ShakeSeconds}
 else
  result={Kind="LuckyReward",Category="Luck",Multiplier=def.LuckMultiplier,Text=string.format("+%d%% Luck — %d:00",math.floor((def.LuckMultiplier-1)*100+.5),Config.BoostSeconds/60),PresentationDelay=Config.ShakeSeconds}
 end
 result.LuckyEventId=receipt.EventId;result.LuckyRequestId=receipt.RequestId
 receipt.Result=result;return true
end
function Service:CommitReceipt(player,entry,receipt)
 if receipt.Committed then return true,receipt.Result end
 local preparedOK,why=self:PrepareReceipt(player,receipt);if not preparedOK then return false,why end
 local data=Data:Get(player);local def=Config.Biomes[receipt.Biome]
 local awardedAt=now()
 local function mark()receipt.Committed=true;receipt.AwardedAt=awardedAt;entry.Used+=1;entry.NextTryAt=awardedAt+Config.PersonalCooldown end
 if receipt.Category=="Secret"then
  if not Pets:HasSpace(player,1)then return false,"Your accepted Secret reward is waiting for pet storage space."end
  local pet=receipt.Result.Results[1].Pet
  -- A saved prepared receipt is not ownership; it is adopted once on settlement.
  local owned=Pets:FindOwned(data,pet.UID)
  if not owned then
   local result=receipt.Result.Results[1];result.Destination=Pets:Adopt(data,pet);result.NewDiscovery=Pets:Discover(data,pet)
   mark();Pets:RecordAward(player,pet,result,{Source="LuckyTree",Biome=receipt.Biome});Pets.Granted:Fire(player,pet,result.NewDiscovery);result.Pet=table.clone(pet)
  else mark()end
  Pets:Publish(player)
 elseif receipt.Category=="Coins"then
  local ok,why=Economy:GrantExact(player,{Coins=def.Coins},"LuckyTree",mark)
  if not ok then return false,why end
 else
  local boost=Rules.AwardBoost(data,receipt.Biome,awardedAt)
  receipt.Result.ExpiresAt=boost.ExpiresAt;mark();Data:Publish(player,"Boosts")
  Knit.GetService("ModifierService"):PublishOdds(player)
 end
 Data:Publish(player,"LuckyTreeParticipation");Pets:RequestSave(player)
 if active and active.EventId==entry.EventId then self:Sync(player)end
 return true,receipt.Result
end
function Service:TryInternal(player,event,requestId,forced)
 return Pets:Transaction(player,function()
  local data=Data:Get(player);local existing=Rules.Event(data,event.EventId,false)
  local previous=receiptFor(existing,requestId)
  if previous then return self:CommitReceipt(player,existing,previous)end
  local current=now()
  if current>=event.EndsAt then return false,"This Lucky Tree event has ended."end
  if not Knit.GetService("BiomeService"):IsUnlocked(player,event.Biome)then return false,"Unlock "..event.Biome.." before trying this Lucky Tree."end
  if not event.TestOnly then
   local root=Guard.Alive(player)
   if event~=active or not root or not event.Tree:IsDescendantOf(workspace) or (root.Position-event.Position).Magnitude>Config.InteractionDistance then return false,"Move closer to the Lucky Tree."end
  end
  if existing and existing.Used>=Config.Attempts then return false,"All tries used"end
  if existing and (existing.NextTryAt or 0)>current or (event.BusyUntil or 0)>current then return false,"The tree is settling. Try again in a moment."end
  if existing then for _,r in ipairs(existing.Receipts)do if not r.Committed then return false,"Your accepted Lucky reward is still settling. Retry that request."end end end
  -- Every category must be deliverable before any RNG, including Garden return reservations.
  if not Pets:HasSpace(player,1)then return false,"Make room for a possible Secret pet before trying your luck."end
  local secret=Config.Biomes[event.Biome].SecretPetId
  if not Models.Resolve(secret)then return false,"The Secret reward model is unavailable."end
  local fits,why=Economy:CanReceive(player,{Coins=Config.Biomes[event.Biome].Coins});if not fits then return false,why end
  local entry,issue=Rules.Event(data,event.EventId,true,event.EndsAt,current);if not entry then return false,issue end
  local category=forced or Rules.Roll(rng)
  local receipt={RequestId=requestId,EventId=event.EventId,Biome=event.Biome,Category=category,AcceptedAt=current,Committed=false}
  table.insert(entry.Receipts,receipt) -- save selected category before preparation; failure cannot reroll it
  Pets:RequestSave(player)
  local ok,response=self:CommitReceipt(player,entry,receipt)
  if ok then self:PresentShake(event)end
  return ok,response
 end)
end
function Service:Try(player,eventId,requestId)
 -- Settled retries remain readable after event cleanup; new attempts require the active tree.
 local data=Data:Get(player);local entry=data and Rules.Event(data,eventId,false);local old=receiptFor(entry,requestId)
 if old then return Pets:Transaction(player,function()return self:CommitReceipt(player,entry,old)end)end
 if not active or active.EventId~=eventId then return false,"This Lucky Tree event is no longer active."end
 return self:TryInternal(player,active,requestId)
end
function Service:Reconcile(player)
 local data=Data:Get(player);if not data then return end
 for _,entry in ipairs(data.LuckyTreeParticipation.Events or {})do
  for _,receipt in ipairs(entry.Receipts)do if not receipt.Committed then Pets:Transaction(player,function()return self:CommitReceipt(player,entry,receipt)end)end end
 end
 self:Sync(player)
end
-- Backend-only dependency injection: no test tree, no public event and no Remote bypass.
if RunService:IsStudio()then
 function Service:StudioFixture(biome)
  assert(script.Parent.ProfileService:GetAttribute("AKUseMockProfiles")==true,"Mock profiles required")
  assert(Config.Biomes[biome]);return {EventId="QA:"..Http:GenerateGUID(false),Biome=biome,EndsAt=now()+Config.Lifetime,TestOnly=true}
 end
 function Service:StudioTry(player,event,requestId,category)
  assert(event.TestOnly and player:GetAttribute("ProfileDataMode")=="StudioMockSnapshot")
  assert(category=="Secret" or category=="Coins" or category=="Luck")
  return self:TryInternal(player,event,requestId,category)
 end
end
function Service:KnitInit()
 Data=Knit.GetService("PlayerDataService");Pets=Knit.GetService("PetService");Economy=Knit.GetService("EconomyService")
 local folder=RS:FindFirstChild("AnimalKingdomRemotes") or Instance.new("Folder");folder.Name="AnimalKingdomRemotes";folder.Parent=RS
 self.StateRemote=folder:FindFirstChild("LuckyTreeState") or Instance.new("RemoteEvent");self.StateRemote.Name="LuckyTreeState";self.StateRemote.Parent=folder
end
function Service:KnitStart()
 self.StateRemote.OnServerEvent:Connect(function(player,...)if select("#",...)==0 and Guard.RateLimit(player,"LuckyState",1)then self:Sync(player)end end)
 local profiles=Knit.GetService("ProfileService");profiles.Loaded:Connect(function(player)self:Reconcile(player)end)
 for player in pairs(profiles.Profiles)do self:Reconcile(player)end
 task.spawn(function()
  self:Validate()
  for _,player in ipairs(Players:GetPlayers())do self:Sync(player)end
  if not status.AutomaticEnabled then warn("[LuckyTrees] Automatic events disabled: "..table.concat(status.Issues,"; "));return end
  nextAt=now()+rng:NextInteger(Config.DelayMin,Config.DelayMax)
  while true do
   if active and now()>=active.EndsAt then self:EndEvent()
   elseif not active and now()>=nextAt then
    local biome=rng:NextInteger(1,2)==1 and "Meadow" or "Forest"
    local ok,why=self:Spawn(biome);if not ok then warn("[LuckyTrees] "..tostring(why));nextAt=now()+rng:NextInteger(Config.DelayMin,Config.DelayMax)end
   end
   task.wait(.25)
  end
 end)
end
return Service
