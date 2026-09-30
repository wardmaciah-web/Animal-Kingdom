-- Mock/copy profile: real normal transactions plus explicitly simulated mission/co-op events.
local RS=game.ReplicatedStorage;local H=game.HttpService;local K=require(RS.Packages.Knit)
K.OnStart():await();assert(game:GetService('RunService'):IsStudio())
local p=game.Players:GetPlayers()[1]or game.Players.PlayerAdded:Wait()
local profiles=K.GetService('ProfileService');profiles:WaitUntilProfileLoaded(p);local profile=profiles.Profiles[p];assert(profile.is_mock)
local original=profile.Data;local root=p.Character:WaitForChild('HumanoidRootPart');local cf,anchored=root.CFrame,root.Anchored
local report={Kind='Studio Play: Hot searches; simulated missions and two-contributor cooperation',Assertions=0,Failures={},Hot={}}
local function check(v,m)report.Assertions+=1;assert(v,m)end
local function waitFor(fn,seconds,label)local deadline=os.clock()+seconds;repeat if fn()then return end;task.wait(.1)until os.clock()>deadline;error('Timed out: '..label)end
local c=K.GetService('ChallengeService');local a=c.Activities;local world=a.World;local nextHot=world.NextHot;local queue=profiles.QueueKingdomReward
local ok,err=xpcall(function()
 local d=H:JSONDecode(H:JSONEncode(require(RS.SharedSource.Datas.ProfileTemplate)));require(RS.Shared.Gameplay.ProfileMigrations).Apply(d,function()return H:GenerateGUID(false)end)
 d.Currencies.Coins=1000000;d.TutorialCompleted=true;d.UnlockedBiomes.Forest=true;profile.Data=d;c:Ensure(p);a:Ensure(p)
 local pets=K.GetService('PetService');local resource=K.GetService('ResourceService');local egg=K.GetService('EggService');local modifier=K.GetService('ModifierService');local P=require(RS.Shared.Gameplay.KingdomProgress)
 local families=require(RS.Shared.Gameplay.Definitions.TreeFamilyDefinitions);local pools=require(RS.Shared.Gameplay.Definitions.EggDefinitions)
 local odds=require(RS.Shared.Gameplay.NormalTreeOdds);local routes=a.Routes
 world:ClearHot();world.NextHot=workspace:GetServerTimeNow()+9999;root.Anchored=true;pets:Publish(p)
 local candidates=routes:Candidates('Meadow','Meadow_Shakeable_01');check(#candidates>=5,'five authored copies exist')
 local fixture=pets:Create('MeadowFieldMouse','Normal',false,false,1);pets:Adopt(d,fixture);pets:Discover(d,fixture);fixture.Favorite=true
 local identity={UID=fixture.UID,Weight=fixture.Weight,XP=fixture.XP,Location=fixture.Location,Slot=fixture.LocationSlot}
 for i,variant in ipairs(workspace:GetAttribute('AKWorldSkipSearches')and {}or {'Heavy','Lucky','Rich','Fast','Mastery'})do
  workspace:SetAttribute('AKWorldTestStage',variant)
  local candidate=candidates[i];local tree,r=candidate.Tree,candidate.Record;local family=candidate.Family
  root.CFrame=CFrame.new(r.InteractionPosition+Vector3.new(8,0,0));waitFor(function()return r.State=='AVAILABLE'and egg:CheckTreeHatch(p,tree)end,30,'ready hot target')
  local pivot=tree:GetPivot();local size=tree:GetExtentsSize();local base=modifier:SearchSnapshot(p,tree,'Meadow',family.Id)
  check(world:StartHot(variant,tree),'start '..variant);local boosted=modifier:SearchSnapshot(p,tree,'Meadow',family.Id)
  if variant=='Heavy'then check(boosted.WeightBias==.15,'heavy bias real snapshot')
  elseif variant=='Lucky'then
   check(math.abs(boosted.Odds.Luck/base.Odds.Luck-1.15)<1e-9,'Luck applied once')
   local rare='MeadowPatchworkLop';check(odds.Chance(pools[family.Id],rare,boosted.Odds)>odds.Chance(pools[family.Id],rare,base.Odds),'normal Rare chance actually increases')
   modifier:PublishOdds(p);check(math.abs(odds.Chance(pools[family.Id],rare,d.NormalTreeModifiers['Hot:'..family.Id])-odds.Chance(pools[family.Id],rare,boosted.Odds))<1e-12,'Index hot odds equal sampler')
  elseif variant=='Rich'then check(boosted.BonusCoins==25,'Rich exact bonus')
  elseif variant=='Fast'then check(boosted.TreeCooldown==12,'Fast actual shared tree timer');check(modifier:SearchSnapshot(p,candidates[1].Tree,'Meadow',family.Id).TreeCooldown==20,'other copy keeps base cooldown')
  else check(boosted.Mastery==1,'Mastery point in snapshot')end
  local n=#d.Pets;local balance=d.Currencies.Coins;local points=P.Family(d,family.Id).Points or 0;local searches=P.Family(d,family.Id).Searches
  check(resource:Gather(p,tree),'normal transaction accepted');local snapshot=r.Claim.Search;world:ClearHot()
  check(not tree:GetAttribute('HotTreeId'),'expiry removes override attrs during accepted shake')
  waitFor(function()return #d.Pets==n+1 end,8,'hot normal committed reward')
  check(d.Currencies.Coins==balance-family.Cost+(snapshot.BonusCoins or 0),'snapshot exact spend/bonus once')
  check(P.Family(d,family.Id).Searches==searches+1,'actual search count increases once')
  check(P.Family(d,family.Id).Points==points+1+(variant=='Mastery'and 1 or 0),'real family mastery points')
  check(math.abs((r.ReturnAt-workspace:GetServerTimeNow())-snapshot.TreeCooldown)<1,'accepted expiry retains snapshotted cooldown')
  check(not egg:HatchFromTree(p,tree,r.Claim),'accepted reward cannot replay')
  table.insert(report.Hot,{Variant=variant,WeightBias=snapshot.WeightBias,Luck=snapshot.Odds.Luck,Cooldown=snapshot.TreeCooldown,Bonus=snapshot.BonusCoins})
  waitFor(function()return r.State=='AVAILABLE'end,23,'original tree restored')
  check((tree:GetPivot().Position-pivot.Position).Magnitude<.001 and tree:GetPivot().LookVector:Dot(pivot.LookVector)>.99999,'original pose restored')
  check((tree:GetExtentsSize()-size).Magnitude<.01,'original scale restored')
 end
 -- Ordered combined effects: each applied exactly once, no base-definition mutation.
 local tree=candidates[1].Tree;local id='Meadow_Shakeable_01';local time=workspace:GetServerTimeNow()
 P.Family(d,id).Points=120;d.KingdomShop.Active.Clover={StartedAt=time-1,ExpiresAt=time+60};d.KingdomShop.Active.Heavy={StartedAt=time-1,ExpiresAt=time+60};d.KingdomShop.Active.Search={StartedAt=time-1,ExpiresAt=time+60}
 check(world:StartHot('Lucky',tree),'combined Lucky hot starts');local base=modifier:Get(p,'Luck','Meadow');local snap=modifier:SearchSnapshot(p,tree,'Meadow',id)
 check(math.abs(snap.Odds.Luck/base-1.1*1.05*1.15)<1e-9,'Clover family Hot once each')
 check(math.abs(snap.Recovery-1.05)<1e-9,'Search Charm real personal recovery');check(snap.TreeCooldown==20,'Search Charm leaves shared timer')
 modifier:PublishOdds(p);check(d.NormalTreeModifiers[id].Luck<d.NormalTreeModifiers['Hot:'..id].Luck,'ordinary copies do not inherit Hot Luck')
 world:StartHot('Heavy',tree);d.Activities.Finale={RunId='test-finale',FamilyId=id,ExpiresAt=time+60}
 snap=modifier:SearchSnapshot(p,tree,'Meadow',id);check(math.abs(snap.WeightBias-.4)<1e-9,'Heavy Shop + Hot + finale capped at .40')
 local coins=d.Currencies.Coins;d.Currencies.Coins=0;check(not resource:Gather(p,tree),'failed normal search rejected');check(d.Activities.Finale.RunId=='test-finale','failed search keeps one-use entitlement');d.Currencies.Coins=coins
 world:ClearHot();d.Activities.Finale=nil;d.KingdomShop.Active={}
 -- Mission event simulations explicitly exercise the exact UID and location checks.
 check(a:Mission(p,fixture.UID,'Garden'),'Garden UID mission accepted');local mission=d.Activities.Mission
 c:Committed(p,'Garden','wrong-trip',{UID='different'});check(mission.Progress==0,'wrong Garden UID ignored')
 c:Committed(p,'Garden','right-trip',{UID=fixture.UID});check(mission.Progress==1,'settled exact trip UID advances');check(a:ClaimMission(p,mission.Id),'Garden mission XP once')
 d.Activities.MissionDays[fixture.UID]=nil
 check(a:Mission(p,fixture.UID,'Visits'),'visit mission accepted');mission=d.Activities.Mission
 for i,biome in ipairs({'Meadow','Meadow','Forest'})do c:Committed(p,'Arrival','visit'..i,{Biome=biome,HeldUID=fixture.UID})end
 check(mission.Progress==2,'distinct eligible visits exact UID');check(a:ClaimMission(p,mission.Id),'visit XP claim')
 d.Activities.MissionDays[fixture.UID]=nil
 check(a:Mission(p,fixture.UID,'DisplayedCollect'),'displayed-collection mission accepted');mission=d.Activities.Mission
 c:Committed(p,'Collect','unshown',{Amount=500});check(mission.Progress==0,'not displayed receives no credit')
 K.GetService('PlotService'):Teleport(p);local display=require(game.ServerScriptService.ServerSource.Utilities.MeadowSanctuaryDisplay);local slot=display.GetSlot(p,1);root.CFrame=CFrame.new(slot.Surface+Vector3.new(0,3,0))
 check(pets:Equip(p,fixture.UID,true),'equip mission fixture before placement')
 local placed,why=pets:SwapSanctuary(p,fixture.LocationSlot,1,fixture.UID,'');check(placed,'actual mission pet placement: '..tostring(why))
 c:Committed(p,'Collect','shown',{Amount=500});check(mission.Progress==500,'worded whole-collection objective advances while displayed');check(a:ClaimMission(p,mission.Id),'display mission claim')
 world:Rates();local peak=world.Records.PeakIncome.Value;check(world.Records.CurrentIncome.Value>0,'current Sanctuary rate measured')
 check(pets:SwapSanctuary(p,0,1,'',fixture.UID),'normal physical pickup remains usable');check(pets:Move(p,fixture.UID,'Inventory'),'store picked-up pet');world:Rates();check(world.Records.CurrentIncome.Value<peak and world.Records.PeakIncome.Value>=peak,'current and peak rates distinct')
 d.Activities.MissionDays[fixture.UID]=nil;check(a:Mission(p,fixture.UID,'Garden'),'invalidation mission accepted')
 local removed;for i,pet in ipairs(d.Pets)do if pet.UID==fixture.UID then removed=table.remove(d.Pets,i);break end end
 a:Ensure(p);check(d.Activities.Mission==nil,'no-longer-owned UID invalidates safely');table.insert(d.Pets,removed)
 -- Simulated second contributor, then actual existing ProfileStore mock inbox delivery.
 local delivered={};profiles.QueueKingdomReward=function(self,uid,message)delivered[uid]=(delivered[uid]or 0)+1;if uid==p.UserId then return queue(self,uid,message)end;return true end
 world:StartGoal('Search');local g=world.Coop;check(g.Target==12 and g.Minimum==2,'solo target freezes at twelve')
 local second={UserId=987654321,SetAttribute=function()end}
 for _=1,2 do world:ProgressGoal(second,'Search',{})end
 for _=1,10 do world:ProgressGoal(p,'Search',{})end
 check(g.Completed and g.Contributors[tostring(second.UserId)].Amount==2,'two independent simulated contributors shared completion')
 local receipt=g.Id..':'..p.UserId
 waitFor(function()return d.Activities.Pending[receipt]~=nil end,20,'existing mock ProfileStore message delivered')
 local coinsBefore=d.Currencies.Coins;check(a:Claim(p,receipt),'own cooperative pending claim');a:Claim(p,receipt)
 check(d.Currencies.Coins==coinsBefore+200,'cooperative currency paid once')
 check(delivered[p.UserId]==1 and delivered[second.UserId]==1,'individual receipts once; neither consumes other')
 queue(profiles,p.UserId,{Kind='KingdomCoop',Id=receipt,Coins=200,Tokens=3,CreatedAt=time,ExpiresAt=time+600});task.wait(1)
 check(d.Activities.Pending[receipt]==nil,'duplicate inbox message cannot recreate claimed reward')
 -- Failure retry survives replacement of the active goal.
 local retries=0;profiles.QueueKingdomReward=function()retries+=1;return retries>1 end
 local old={Id='RetryFixture',EndsAt=time-1,Rewards={Coins=200,FriendshipTokens=3}};world:Deliver(987654322,old);task.wait(.2);world:StartGoal('Collect')
 local delivery=world.PendingDeliveries['RetryFixture:987654322'];delivery.RetryAt=0;world:Tick();waitFor(function()return delivery.State=='Delivered'end,3,'delivery after goal replacement');check(retries==2,'failed inbox delivery retried independently')
 profiles.QueueKingdomReward=queue
 check(fixture.UID==identity.UID and fixture.Weight==identity.Weight and fixture.Favorite==true,'UID weight and favorite survive activity/Shop changes')
 local restored=H:JSONDecode(H:JSONEncode(d));P.Ensure(restored);check(restored.Activities.Receipts[receipt]~=nil and restored.TreeMastery[id].Points==120,'claims/mastery survive mock serialized restoration')
 local seen={};for _,pet in ipairs(restored.Pets)do check(not seen[pet.UID],'one canonical UID');seen[pet.UID]=true end
 if not workspace:GetAttribute('AKWorldSkipSearches')then check(world.Records.Heaviest and world.Records.Rarest and world.Records.Streak,'session records captured real searches')end
 report.Acquisitions=#d.Pets-1;report.CoopReceipt=receipt;report.RestoredUIDs=#restored.Pets
end,debug.traceback)
profiles.QueueKingdomReward=queue;world:ClearHot();world.NextHot=nextHot;profile.Data=original;root.CFrame=cf;root.Anchored=anchored
K.GetService('PetService'):Publish(p);K.GetService('PlayerDataService'):Publish(p,'Activities','Currencies','TreeMastery','KingdomShop')
if not ok then table.insert(report.Failures,err)end;report.Passed=ok;workspace:SetAttribute('AKWorldTests',H:JSONEncode(report))
