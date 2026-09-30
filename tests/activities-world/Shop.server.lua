-- Actual service transactions on a disposable mock profile. Boost expiry and
-- rotation restoration also use explicit simulated timestamps, reported below.
local RS=game.ReplicatedStorage;local H=game.HttpService;local K=require(RS.Packages.Knit)
K.OnStart():await();assert(game:GetService('RunService'):IsStudio())
local p=game.Players:GetPlayers()[1]or game.Players.PlayerAdded:Wait();local profiles=K.GetService('ProfileService');profiles:WaitUntilProfileLoaded(p)
local profile=profiles.Profiles[p];assert(profile.is_mock);local original=profile.Data
local root=p.Character:WaitForChild('HumanoidRootPart');local oldCF,oldAnchor=root.CFrame,root.Anchored
local world=K.GetService('ChallengeService').Activities.World;local oldHotTime=world.NextHot
world:ClearHot();world.NextHot=math.huge -- isolate Shop effects from a scheduled Heavy Hot Tree
local result={Kind='Studio mock Shop/Garden/Sanctuary transactions',Assertions=0,Failures={},Offers={},Paths={}}
local function check(v,m)result.Assertions+=1;assert(v,m)end
local function guid()return H:GenerateGUID(false)end
local ok,err=xpcall(function()
 local d=H:JSONDecode(H:JSONEncode(require(RS.SharedSource.Datas.ProfileTemplate)))
 require(RS.Shared.Gameplay.ProfileMigrations).Apply(d,guid);d.Currencies.Coins=100000;d.Currencies.FriendshipTokens=1000;d.TutorialCompleted=true;profile.Data=d
 local challenge=K.GetService('ChallengeService');challenge:Ensure(p);challenge.Activities:Ensure(p)
 local pets=K.GetService('PetService');pets:Publish(p);root.Anchored=true
 local shop=K.GetService('ShopService');local garden=K.GetService('GardenExpeditionService');local sanctuary=K.GetService('SanctuaryService')
 local D=require(RS.Shared.Gameplay.Definitions.KingdomShopDefinitions);local P=require(RS.Shared.Gameplay.KingdomProgress);local GP=require(RS.Shared.Gameplay.GardenProgress)
 local town=require(game.ServerScriptService.ServerSource.Utilities.TownInteractions);local anchor=town.Get('Shop');check(anchor,'existing store technical anchor')
 for _,entry in ipairs(town.Entries)do
  local target=town.Get(entry.Id);check(target and target.Transparency==1 and not target.CanCollide,'invisible noncolliding anchor '..entry.Id)
  local path=game:GetService('PathfindingService'):CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
  path:ComputeAsync(Vector3.new(-238,12,215),target.Position)
  local reachable=path.Status==Enum.PathStatus.Success;table.insert(result.Paths,{Entry=entry.Id,Reachable=reachable});check(reachable,'walkable Town entry '..entry.Id)
 end
 root.CFrame=CFrame.new(anchor.Position+Vector3.new(60,0,0));local rotation=D.Rotation(workspace:GetServerTimeNow());local balance=d.Currencies.Coins
 check(not shop:BuyBoost(p,'Clover',rotation,guid())and d.Currencies.Coins==balance,'distant boost purchase rejected without spend')
 check(not shop:Buy(p,'WoodenChair',guid(),rotation),'furniture also requires Town store')
 root.CFrame=CFrame.new(anchor.Position)
 check(not shop:BuyBoost(p,'Missing',rotation,guid()),'unknown offer rejected')
 check(not shop:BuyBoost(p,'Clover',rotation-1,guid()),'stale rotation rejected')
 d.Currencies.Coins=0;check(not shop:BuyBoost(p,'Clover',rotation,guid()),'insufficient funds rejected');d.Currencies.Coins=balance
 local modifiers=K.GetService('ModifierService');local scope={Normal=true,FamilyId='Meadow_Shakeable_01'}
 local before=modifiers:GetOddsContext(p,'Meadow',scope)
 for _,id in ipairs({'Clover','Heavy','Search','Blessing','Fertilizer'})do
  local def=D[id];local beforeBalance=d.Currencies[def.Currency];local request=guid()
  local bought,receipt=shop:BuyBoost(p,id,rotation,request);check(bought,'buy '..id..': '..tostring(receipt))
  check(d.Currencies[def.Currency]==beforeBalance-def.Price,'exact price '..id)
  local paid=d.Currencies[def.Currency];local replay,same=shop:BuyBoost(p,id,rotation,request)
  check(replay and same.RequestId==request and d.Currencies[def.Currency]==paid,'persistent receipt replay '..id)
  check(not shop:BuyBoost(p,id,rotation,guid())and d.Currencies[def.Currency]==paid,'personal stock limit '..id)
  if def.Seconds then local b=d.KingdomShop.Active[id];check(math.abs(b.ExpiresAt-b.StartedAt-def.Seconds)<1e-6,'configured duration '..id)else check(d.KingdomShop.Fertilizer==1,'one pending fertilizer')end
  table.insert(result.Offers,{Id=id,Price=def.Price,Currency=def.Currency,Seconds=def.Seconds or 0})
 end
 local after=modifiers:GetOddsContext(p,'Meadow',scope)
 check(math.abs(after.Luck/before.Luck-1.1)<1e-6,'Clover changes actual normal Luck once')
 local odds=require(RS.Shared.Gameplay.NormalTreeOdds);local pool=require(RS.Shared.Gameplay.Definitions.EggDefinitions).Meadow_Shakeable_01
 check(odds.Chance(pool,'MeadowPatchworkLop',after)>odds.Chance(pool,'MeadowPatchworkLop',before),'Clover improves normalized rare probability')
 local tree
 for candidate,r in pairs(K.GetService('ResourceService'):GetRecords())do if r.Biome=='Meadow'and candidate:GetAttribute('RewardPoolId')=='Meadow_Shakeable_01'then tree=candidate;break end end
 local snapshot=modifiers:SearchSnapshot(p,tree,'Meadow','Meadow_Shakeable_01')
 check(snapshot.WeightBias==.15,'Heavy Charm reaches the weight-roll input')
 check(math.abs(snapshot.Recovery-1.05)<1e-6 and snapshot.TreeCooldown==20,'Search Charm changes personal recovery only')
 local normalLucky=modifiers:Get(p,'Luck','Meadow');check(math.abs(normalLucky-before.Luck)<1e-6,'normal-only Clover excluded from special Lucky reward creation')
 local pet=pets:Create('MeadowFieldMouse','Normal',false,false,1);pets:Adopt(d,pet);pets:Discover(d,pet);pets:Publish(p)
 check(not garden:Start(p,pet.UID,'SproutRun',guid())and d.KingdomShop.Fertilizer==1,'failed Garden start does not consume fertilizer')
 check(pets:Move(p,pet.UID,'Inventory'),'store Garden pet');local sent,why=garden:Start(p,pet.UID,'SproutRun',guid());check(sent,tostring(why))
 local trip=d.GardenExpeditions[1]
 check(d.KingdomShop.Fertilizer==0 and trip.KingdomFertilizer==1.15,'valid start consumes once and snapshots trip')
 local plain=H:JSONDecode(H:JSONEncode(trip));plain.KingdomFertilizer=nil
 local boosted=H:JSONDecode(H:JSONEncode(trip));GP.Advance(plain,trip.ReadyAt);GP.Advance(boosted,trip.ReadyAt)
 check(math.abs(boosted.PendingHarvest/plain.PendingHarvest-1.15)<1e-6,'Fertilizer gives exactly +15% Harvest')
 check(boosted.PendingXP==plain.PendingXP,'Fertilizer creates no extra XP multiplier')
 local restored=H:JSONDecode(H:JSONEncode(d));check(restored.GardenExpeditions[1].KingdomFertilizer==1.15 and restored.KingdomShop.Fertilizer==0,'fertilized trip survives mock serialization')
 local deal=D.Offers(rotation)[6];local effect=D[deal.EffectId]
 if effect.Seconds then
  check(not shop:BuyBoost(p,'Mystery',rotation,guid()),'Mystery cannot duplicate an active underlying effect')
  d.KingdomShop.Active[deal.EffectId].ExpiresAt=workspace:GetServerTimeNow()-1
 end
 local previous=d.Currencies[deal.Currency];local bought,receipt=shop:BuyBoost(p,'Mystery',rotation,guid());check(bought,'visible Mystery deal')
 check(receipt.EffectId==deal.EffectId and d.Currencies[deal.Currency]==previous-deal.Price,'Mystery uses displayed effect and exact discounted price')
 table.insert(result.Offers,{Id='Mystery',Effect=deal.EffectId,Price=deal.Price,OriginalPrice=deal.OriginalPrice})
 -- An actual short boundary test of the existing Sanctuary accumulator. Only
 -- this mock expiry is shortened; canonical purchased duration was checked above.
 local shown=pets:Create('MeadowChick','Normal',false,false,1);pets:Adopt(d,shown);pets:Discover(d,shown);pets:Publish(p);check(pets:Equip(p,shown.UID,true),'hold display pet')
 K.GetService('PlotService'):Teleport(p)
 local display=require(game.ServerScriptService.ServerSource.Utilities.MeadowSanctuaryDisplay);local slot=display.GetSlot(p,1);check(slot,'own Sanctuary slot exists')
 root.CFrame=CFrame.new(slot.Surface+Vector3.new(0,3,0));check(pets:SwapSanctuary(p,shown.LocationSlot,1,shown.UID,''),'place Sanctuary pet')
 sanctuary:Accrue(p);local at=d.SanctuaryIncomeUpdatedAt;local startCoins=d.UncollectedSanctuaryCoins
 d.KingdomShop.Active.Blessing={StartedAt=at,ExpiresAt=at+2}
 task.wait(3.1);sanctuary:Accrue(p);local finish=d.SanctuaryIncomeUpdatedAt
 local event=K.GetService('EventModifierService');local expected=sanctuary:GetIncome(d)*(event:GetCoinWeightedSeconds(at,finish)+.15*event:GetCoinWeightedSeconds(at,at+2))
 check(math.abs(d.UncollectedSanctuaryCoins-startCoins-expected)<.02,'actual blessing start/expiry accrues once without touching old balance')
 local collectable=math.floor(d.UncollectedSanctuaryCoins);local beforeCollection=d.Currencies.Coins
 check(K.GetService('PlotService'):Collect(p),'collect blessed Sanctuary coins')
 check(d.Currencies.Coins==beforeCollection+collectable,'collection does not multiply blessing a second time')
 result.ShortBlessingElapsed=finish-at;result.ShortBlessingAccrued=expected
 workspace:SetAttribute('AKShopTestStage','Waiting for actual 60-second Garden trip')
 while os.time()<trip.ReadyAt do task.wait(.5)end
 local harvestBefore=d.Currencies.GardenHarvest;local settled,reward=garden:Claim(p,pet.UID,guid());check(settled,'actual Garden claim')
 check(reward.Amount==math.floor(boosted.PendingHarvest+1e-7)and d.Currencies.GardenHarvest==harvestBefore+reward.Amount,'fertilized Harvest paid once by normal settlement')
 check(not garden:Claim(p,pet.UID,guid()),'Garden replay cannot award twice')
 local restoredShop=H:JSONDecode(H:JSONEncode(d.KingdomShop));check(restoredShop.Rotations[tostring(rotation)].Counts.Clover==1,'stock limit persists through mock restoration')
 result.DurablePersistence='Not tested by this suite; JSON restoration and existing mock ProfileStore only.'
end,debug.traceback)
world.NextHot=oldHotTime;profile.Data=original;root.CFrame=oldCF;root.Anchored=oldAnchor;K.GetService('PetService'):Publish(p);K.GetService('PlayerDataService'):Publish(p,'KingdomShop','Activities','Currencies','GardenExpeditions')
if not ok then table.insert(result.Failures,err)end
result.Passed=#result.Failures==0;workspace:SetAttribute('AKActivitiesShop',H:JSONEncode(result));workspace:SetAttribute('AKShopTestStage','Finished')
