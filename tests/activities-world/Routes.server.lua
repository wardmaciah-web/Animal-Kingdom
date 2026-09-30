-- Actual Studio server search/placement transactions; mock funds and deterministic
-- NEW reward rolls. Character movement is scripted, not a manual walking test.
local RS=game.ReplicatedStorage;local H=game.HttpService;local K=require(RS.Packages.Knit)
K.OnStart():await();assert(game:GetService('RunService'):IsStudio())
local p=game.Players:GetPlayers()[1]or game.Players.PlayerAdded:Wait()
local profiles=K.GetService('ProfileService');profiles:WaitUntilProfileLoaded(p);local profile=profiles.Profiles[p];assert(profile.is_mock)
local original=profile.Data;local root=p.Character:WaitForChild('HumanoidRootPart');local oldCF,oldAnchor=root.CFrame,root.Anchored
local egg=K.GetService('EggService');local create=egg.CreateRewardPet
local report={Kind='Studio Play transactions with mock/copy profile and scripted movement',Assertions=0,Failures={},Variants={}}
local function check(v,m)report.Assertions+=1;assert(v,m)end
local function waitFor(fn,seconds,label)local deadline=os.clock()+seconds;repeat if fn()then return end;task.wait(.1)until os.clock()>deadline;error('Timed out: '..label)end
local ok,err=xpcall(function()
 local d=H:JSONDecode(H:JSONEncode(require(RS.SharedSource.Datas.ProfileTemplate)))
 require(RS.Shared.Gameplay.ProfileMigrations).Apply(d,function()return H:GenerateGUID(false)end)
 d.Currencies.Coins=1000000;d.UnlockedBiomes.Forest=true;d.TutorialCompleted=true;profile.Data=d
 local c=K.GetService('ChallengeService');c:Ensure(p);local a=c.Activities;a:Ensure(p);local routes=a.Routes
 local pets=K.GetService('PetService');pets:Publish(p);root.Anchored=true
 local defs=require(RS.Shared.Gameplay.Definitions.PetDefinitions);local families=require(RS.Shared.Gameplay.Definitions.TreeFamilyDefinitions)
 egg.CreateRewardPet=function(self,player,id,biome,snapshot)local pet=create(self,player,id,biome,snapshot);if player==p then pet.Weight=defs[id].BaseWeight*1.6 end;return pet end
 local function meadow()
  local first=routes:Candidates('Meadow','Meadow_Shakeable_01')[1];root.CFrame=CFrame.new(first.Record.InteractionPosition+Vector3.new(12,0,0))
 end
 local function search(target,forced)
  local object,record
  waitFor(function()
   for tree,r in pairs(K.GetService('ResourceService'):GetRecords())do if tree:GetAttribute('ActivityTreeId')==target.TreeId then object,record=tree,r;break end end
   if not record or record.State~='AVAILABLE'then return false end
   root.CFrame=CFrame.new(Vector3.new(unpack(target.Position))+Vector3.new(0,3,0));return egg:CheckTreeHatch(p,object)
  end,30,'ready target '..target.Name)
  if forced then egg:StudioForceNext(p,forced)end
  local before=#d.Pets;local coins=d.Currencies.Coins;local price=families[target.FamilyId].Cost
  check(K.GetService('ResourceService'):Gather(p,object),'actual normal search accepted')
  check(not K.GetService('ResourceService'):Gather(p,object),'duplicate search rejected')
  waitFor(function()return #d.Pets==before+1 end,8,'committed normal pet')
  check(#d.Pets==before+1 and d.Currencies.Coins==coins-price,'one pet and one exact charge')
  check(not egg:HatchFromTree(p,object,record.Claim),'committed claim replay rejected')
  task.wait(4);return d.Pets[#d.Pets]
 end
 task.wait(3);meadow()
 local coins=d.Currencies.Coins;d.Currencies.Coins=0
 check(not routes:Offer(p,'Rush:Speed','Meadow').Eligible,'low-balance Rush rejected')
 check(routes:Offer(p,'Paw','Meadow').Eligible,'free Paw Hunt stays eligible at zero coins');d.Currencies.Coins=coins
 for _,variant in ipairs({'Speed','Tour','Heavy','Rarity','Species','NoRepeat'})do
  meadow();local accepted,why=routes:Accept(p,'Rush:'..variant,'Meadow');check(accepted,why)
  local r=d.Activities.Route;local before=#d.Pets;local started=os.clock()
  workspace:SetAttribute('AKRouteTestStage',variant)
  for _=1,r.Target do
   local target=r.Targets[math.min(r.Progress+1,#r.Targets)]
   search(target,variant=='Rarity'and 'MeadowPatchworkLop'or nil)
  end
  check(r.Completed and r.Progress==r.Target,'variant completed '..variant)
  local rewardBalance=d.Currencies.Coins;check(a:Claim(p,r.Id),'route reward claimed')
  check(d.Currencies.Coins==rewardBalance+r.Rewards.Coins,'route pays exact reward')
  a:Claim(p,r.Id);check(d.Currencies.Coins==rewardBalance+r.Rewards.Coins,'route reward replay harmless')
  table.insert(report.Variants,{Id=variant,Pets=#d.Pets-before,Seconds=os.clock()-started,WalkingDistance=r.Distance,PriceBudget=r.CostBudget})
 end
 meadow();local accepted,why=routes:Accept(p,'Paw','Meadow');check(accepted,'Paw: '..tostring(why));local r=d.Activities.Route
 check(not routes:Discover(p,r.Id,6),'out-of-sequence paw rejected')
 for i=1,6 do
  root.CFrame=CFrame.new(Vector3.new(unpack(r.Targets[i].Position))+Vector3.new(0,3,0))
  check(routes:Discover(p,r.Id,i),'server validates paw '..i)
  check(not routes:Discover(p,r.Id,i),'paw replay rejected '..i)
 end
 check(r.Completed,'free exploration completes');check(a:Claim(p,r.Id),'Paw reward claim')
 meadow();check(routes:Accept(p,'Adventure','Meadow'),'adventure accepted');r=d.Activities.Route
 search(r.Targets[1]);check(r.Step==2,'adventure named-tree step')
 search(r.Targets[1]);check(r.Step==3,'adventure normalized weight step')
 local pet=d.Pets[#d.Pets]
 if pet.Location=='Inventory'and not require(RS.Shared.Gameplay.PetLocations).FirstFree(d,'Held',5)then pets:Move(p,d.HeldPetSlots[1],'Inventory')end
 check(pets:Equip(p,pet.UID,true),'hold adventure pet')
 K.GetService('PlotService'):Teleport(p)
 local display=require(game.ServerScriptService.ServerSource.Utilities.MeadowSanctuaryDisplay)
 local slot=display.GetSlot(p,1);check(slot,'physical display slot available')
 root.CFrame=CFrame.new(slot.Surface+Vector3.new(0,3,0));check(pets:SwapSanctuary(p,pet.LocationSlot,1,pet.UID,''),'actual adventure Sanctuary placement')
 check(r.Completed,'three-step adventure completes');check(a:Claim(p,r.Id),'adventure reward claim')
 local ids={};for _,owned in ipairs(d.Pets)do check(not ids[owned.UID],'unique acquired UID');ids[owned.UID]=true;check(owned.Location=='Held'or owned.Location=='Inventory'or owned.Location=='Sanctuary','canonical location')end
 report.Acquisitions=#d.Pets
end,debug.traceback)
egg.CreateRewardPet=create;profile.Data=original;root.CFrame=oldCF;root.Anchored=oldAnchor
K.GetService('PetService'):Publish(p);K.GetService('PlayerDataService'):Publish(p,'Activities','Currencies','Contracts','DailyChallenges','WeeklyChallenges')
if not ok then table.insert(report.Failures,tostring(err))end
report.Passed=#report.Failures==0;workspace:SetAttribute('AKActivitiesRoutes',H:JSONEncode(report));workspace:SetAttribute('AKRouteTestStage','Finished')
