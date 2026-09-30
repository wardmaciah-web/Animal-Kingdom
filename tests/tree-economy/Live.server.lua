-- Temporary Studio Play harness; never install under src or publish.
-- First search is triggered by real client input. Remaining families call the real
-- ResourceService in Play, with its heartbeat, transaction, feedback and cooldown.
assert(game:GetService('RunService'):IsStudio())
local K=require(game.ReplicatedStorage.Packages.Knit);K.OnStart():await()
local H=game.HttpService;local p=game.Players:GetPlayers()[1]
K.GetService('ProfileService'):WaitUntilProfileLoaded(p)
local profile=K.GetService('ProfileService').Profiles[p]
assert(profile.is_mock and p:GetAttribute('ProfileDataMode')=='StudioMockSnapshot','Mock only')
local function copy(v)if type(v)~='table'then return v end local n={}for k,x in pairs(v)do n[k]=copy(x)end return n end
local original=copy(profile.Data);local originalCF=p.Character:GetPivot()
local G=game.ReplicatedStorage.Shared.Gameplay
local F=require(G.Definitions.TreeFamilyDefinitions);local E=require(G.Definitions.EggDefinitions)
local Defs=require(G.Definitions.PetDefinitions);local Stats=require(G.PetStats);local M=require(G.ProfileMigrations)
local Locations=require(G.PetLocations);local Format=require(G.PetNumberFormat)
local P=K.GetService('PetService');local D=K.GetService('PlayerDataService');local R=K.GetService('ResourceService')
local Egg=K.GetService('EggService');local Eco=K.GetService('EconomyService');local Plot=K.GetService('PlotService')
local Sanctuary=K.GetService('SanctuaryService');local Tutorial=K.GetService('TutorialService')
local Mods=K.GetService('ModifierService');local Progress=K.GetService('ProgressionService')
local Display=require(game.ServerScriptService.ServerSource.Utilities.MeadowSanctuaryDisplay)
local result={Checks={},Families={},Transactions={},OriginalCoins=original.Currencies.Coins}
local function check(v,label)assert(v,label);table.insert(result.Checks,label)end
local function stage(name)workspace:SetAttribute('AKEconomyStage',name)end
local function waitFor(fn,seconds,label)
 local untilTime=os.clock()+seconds
 repeat if fn()then return end task.wait(.1)until os.clock()>untilTime
 error('Timed out: '..label)
end
local function publishAll()P:Publish(p);for key in pairs(profile.Data)do D:Publish(p,key)end;Mods:PublishOdds(p)end
local function position(record)
 p.Character:PivotTo(CFrame.lookAt(record.InteractionPosition+Vector3.new(0,0,6),record.InteractionPosition))
 p.Character.HumanoidRootPart.Anchored=true
end
local function fingerprint(pet)
 local fields={};for _,key in ipairs({'UID','UniquePetId','PetId','Weight','XP','Level','Mutation','Shiny','Prismatic','Favorite','Locked','Cosmetic','AcquiredAt','Location','LocationSlot','AwardProgressApplied'})do fields[key]=pet[key]end
 return fields
end
local function same(a,b)
 if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not same(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local changed=Eco.Changed:Connect(function(player,currency,amount,reason)
 if player==p then table.insert(result.Transactions,{Currency=currency,Amount=amount,Reason=reason,At=os.clock()})end
end)
local function charges(reason,start)
 local n,total=0,0;for i=start or 1,#result.Transactions do local e=result.Transactions[i];if e.Reason==reason and e.Amount<0 then n+=1;total+=-e.Amount end end;return n,total
end
local ok,err=xpcall(function()
 -- Existing-copy refresh: only derived caches change, including all four locations.
 profile.Data=copy(original);local d=profile.Data
 d.UncollectedSanctuaryCoins=12345.67
 for i,location in ipairs({'Held','Inventory','Sanctuary','Garden'})do
  local pet={UID='economy-preserve-'..i,UniquePetId='economy-preserve-'..i,PetId='MeadowChick',Weight=.6,Level=7,XP=12,Mutation='Golden',Shiny=true,Prismatic=false,Favorite=true,Locked=true,Cosmetic='FlowerCrown',AcquiredAt=123456,Location=location,LocationSlot=(location=='Held' or location=='Sanctuary')and i or nil,CoinsPerSecond=1.25}
  table.insert(d.Pets,pet)
 end
 Locations.Rebuild(d);require(G.SpeciesRecords).Seed(d)
 local fingerprints={};for _,pet in ipairs(d.Pets)do fingerprints[pet.UID]=fingerprint(pet)end
 local coins=d.Currencies.Coins;local contracts=copy(d.Contracts);local records=copy(d.WeightRecords)
 M.Apply(d,function()error('Existing UID regenerated')end);P:Publish(p)
 for _,pet in ipairs(d.Pets)do check(same(fingerprints[pet.UID],fingerprint(pet)),'Saved identity/stat/location preserved '..pet.UID);check(pet.CoinsPerSecond==Stats.Income(pet),'Derived income refreshed '..pet.UID)end
 check(d.Currencies.Coins==coins and d.UncollectedSanctuaryCoins==12345.67,'Balances survive refresh without starter reset')
 check(same(d.Contracts,contracts) and same(d.WeightRecords,records),'Existing contracts and records survive refresh')
 check(d.SanctuaryIncomePerSecond==Sanctuary:GetIncome(d),'Published total equals authoritative total')
 -- Genuinely new template, in the same mock only.
 profile.Data=M.Apply(copy(require(game.ReplicatedStorage.SharedSource.Datas.ProfileTemplate)),function()return H:GenerateGUID(false)end);d=profile.Data
 -- Swapping a mock table does not fire ProfileService.Loaded: initialize the
 -- existing dependent lifecycle explicitly, as a genuinely new load does.
 K.GetService('ChallengeService'):Ensure(p)
 K.GetService('WeatherEventService'):EndCurrentEvent()
 K.GetService('WeatherEventService'):PauseAutomaticEvents()
 K.GetService('WeatherEventService'):StartBreak()
 d.SanctuaryIncomeUpdatedAt=workspace:GetServerTimeNow();publishAll();Sanctuary:Accrue(p)
 check(d.Currencies.Coins==250 and #d.Pets==0,'Clean profile starts with exactly 250 and no pets')
 local recordsById={};local copies={}
 for tree,record in pairs(R:GetRecords())do if record.IsTree and (record.Biome=='Meadow' or record.Biome=='Forest')then
  local id=tree:GetAttribute('RewardPoolId');local def=assert(E[id],id)
  check(record.Prompt.ActionText=='SEARCH · '..Format.Number(def.Cost)..' Forest Coins','Prompt price matches '..tree:GetFullName())
  check(record.Prompt.ObjectText==def.DisplayName and tree:GetAttribute('SearchCost')==nil,'Family name and no local price '..tree:GetFullName())
  local resolver=require(G.Definitions[record.Biome..'TreeDefinitions']);check(resolver.Get(tree,record.Biome)==def,'Physical copy shares exact definition '..id)
  recordsById[id]=recordsById[id]or record;copies[id]=(copies[id]or 0)+1
 end end
 result.Copies=copies
 local starter=assert(recordsById.Meadow_Shakeable_01);position(starter);Tutorial:Reconcile(p)
 check(d.TutorialProgress.Step==2,'Free Meadow arrival advances tutorial')
 for id,record in pairs(recordsById)do if record.Biome=='Meadow' and id~='Meadow_Shakeable_01' then check(not Tutorial:ValidTree(p,record.Object),'Tutorial excludes unaffordable family '..id)end end
 waitFor(function()return Egg:CheckTreeHatch(p,starter.Object)end,60,'client assets ready')
 -- A missing starter model must fail before charging, without pruning the pool.
 local template=game.ReplicatedStorage.MeadowPetTemplates.MeadowFieldMouse;local parent=template.Parent
 template.Parent=nil;local accepted=Egg:CheckTreeHatch(p,starter.Object);template.Parent=parent
 check(not accepted and d.Currencies.Coins==250 and #d.Pets==0,'Missing model cannot consume starter coins')
 waitFor(function()return Egg:CheckTreeHatch(p,starter.Object)end,30,'restored model ready')
 Egg:StudioForceNext(p,'MeadowFieldMouse');stage('StarterReady')
 local tx=#result.Transactions+1;local startStreak=Progress:GetStreak(p)
 waitFor(function()return #d.Pets==1 end,150,'real client starter search')
 local pet=d.Pets[1];local claim=starter.Claim
 waitFor(function()return starter.State=='RESPAWNING'end,5,'starter commit')
 check(pet.PetId=='MeadowFieldMouse' and pet.Location=='Held' and pet.CoinsPerSecond>0,'Starter awarded one valid usable positive-income pet')
 local n,charge=charges('MeadowTreeSearch',tx);check(n==1 and charge==250,'Starter charged exactly 250 once')
 local after=d.Currencies.Coins
 check(after==0,'Paid starter search has no legacy gathering refund')
 check(not Egg:HatchFromTree(p,starter.Object,claim) and #d.Pets==1 and d.Currencies.Coins==after,'Repeated commit cannot charge or grant twice')
 check(Progress:GetStreak(p)==startStreak+1 and d.BiomeMastery.Meadow.Searches==1 and d.WeightRecords[pet.PetId]==pet.Weight,'Single commit records weight, streak and mastery once')
 result.Starter={UID=pet.UID,Weight=pet.Weight,Income=pet.CoinsPerSecond,AfterSearchCoins=after,ZeroBalanceWait=250/pet.CoinsPerSecond,WeakestZeroBalanceWait=250/Defs.MeadowFieldMouse.BaseIncome,StartedAt=os.clock()}
 stage('StarterReveal')
 waitFor(function()return d.TutorialProgress.Step>=3 end,100,'real client reveal acknowledgment')
 check(d.TutorialProgress.PetUID==pet.UID,'Tutorial uses first committed UID without another search')
 check(P:Equip(p,pet.UID,true),'Hold actual starter')
 local before=d.Currencies.Coins;check(Plot:Teleport(p),'Free Sanctuary travel');Tutorial:Reconcile(p)
 check(d.Currencies.Coins==before and d.TutorialProgress.Step==4,'Sanctuary travel costs no coins')
 stage('StarterHeld');task.wait(5)
 local slotId=d.TutorialProgress.SlotId;local slot=assert(Display.GetSlot(p,slotId));p.Character:PivotTo(CFrame.new(slot.Surface+Vector3.new(0,3,0)))
 check(P:SwapSanctuary(p,pet.LocationSlot,slotId,pet.UID,''),'Place first pet at physical Sanctuary slot')
 check(d.Currencies.Coins==before,'Placement is free');Tutorial:Reconcile(p);check(d.TutorialProgress.Step==5,'Placement advances tutorial')
 local placed=os.clock();local startingCoins=d.Currencies.Coins
 stage('StarterEarning');result.Starter.PlacementCoins=startingCoins
 task.wait(2);check(Plot:Collect(p),'Collect actual accrued income');Tutorial:Reconcile(p)
 check(d.TutorialProgress.Step==6 and Tutorial:Complete(p),'Tutorial completes from first pet collection only')
 check(#d.Pets==1,'Tutorial required exactly one paid search')
 while d.Currencies.Coins<250 and os.clock()-placed<130 do task.wait(.5);Plot:Collect(p)end
 check(d.Currencies.Coins>=250,'Starter rebuilds enough for another search through Sanctuary')
 result.Starter.MeasuredSecondsTo250=os.clock()-placed;result.Starter.CollectedCoins=d.Currencies.Coins-startingCoins
 check(Progress:GetStreak(p)==startStreak+1,'Holding, displaying and collecting do not add searches')
 check(starter.State=='AVAILABLE' and starter.Prompt.Enabled,'Starter naturally restores after cooldown')
 local visual
 for _,x in ipairs(workspace:GetDescendants())do if x:IsA('Model') and x.Name==pet.UID and x:GetAttribute('CoinsPerSecond')then visual=x;break end end
 check(visual and visual:GetAttribute('CoinsPerSecond')==Stats.Income(pet),'Displayed pet income equals server stats')
 local label=visual:FindFirstChild('PetIncome',true);check(label and label.Text==Format.Income(pet.CoinsPerSecond),'Sanctuary label agrees with published income')
 -- Spend the recovered funds on the next real search, using another copy.
 stage('RecoverySearch');position(starter);tx=#result.Transactions+1
 check(R:Gather(p,starter.Object),'Recovered balance buys another normal search');waitFor(function()return #d.Pets==2 end,5,'recovery search')
 n,charge=charges('MeadowTreeSearch',tx);check(n==1 and charge==250,'Recovered search charges exactly once')
 task.wait(4)
 -- Higher families: use mock fixture funds, explicitly excluded from pacing.
 check(Eco:Add(p,'Coins',1000000,'QA_MOCK_ONLY'),'Fund isolated family tests')
 check(K.GetService('BiomeService'):Unlock(p,'Forest'),'Existing Forest unlock works')
 local tested={starter}
 table.insert(result.Families,{Id='Meadow_Shakeable_01',Price=250,ClientInput=true,Count=1})
 for _,f in ipairs(F.Ordered)do if (f.Biome=='Meadow' or f.Biome=='Forest')and f.Id~='Meadow_Shakeable_01' then
  local record=assert(recordsById[f.Id]);local def=E[f.Id];position(record);stage('Family:'..f.Id)
  waitFor(function()return Egg:CheckTreeHatch(p,record.Object)end,30,'family ready '..f.Id)
  local count=#d.Pets;local saved=d.Currencies.Coins;local savedUncollected=d.UncollectedSanctuaryCoins
  d.Currencies.Coins=def.Cost-1
  local allowed,why=Egg:CheckTreeHatch(p,record.Object)
  check(not allowed and #d.Pets==count and d.Currencies.Coins==def.Cost-1,'Insufficient funds leaves coins/pets unchanged '..f.Id)
  check(why:find(Format.Number(def.Cost),1,true) and why:find('1 more',1,true),'Useful current-price feedback '..f.Id)
  d.Currencies.Coins=saved
  tx=#result.Transactions+1;local priorStreak=Progress:GetStreak(p)
  check(R:Gather(p,record.Object),'Real Play search '..f.Id)
  local duplicate=R:Gather(p,record.Object);check(not duplicate,'Concurrent search rejected '..f.Id)
  waitFor(function()return record.State=='RESPAWNING'end,6,'family commit')
  check(#d.Pets==count+1,'Exactly one pet '..f.Id)
  local reward=record.HatchResult.Results[1].Pet;local member=false;for _,e in ipairs(def.Pets)do if e.PetId==reward.PetId then member=true end end
  check(member and record.HatchResult.Cost==def.Cost,'Correct pool and server price '..f.Id)
  n,charge=charges(f.Biome..'TreeSearch',tx);check(n==1 and charge==def.Cost,'One actual charge '..f.Id)
  check(d.Currencies.Coins==saved-def.Cost,'Normal search has no secondary loot subsidy '..f.Id)
  check(Progress:GetStreak(p)==priorStreak+1,'One streak increment '..f.Id)
  check(d.UncollectedSanctuaryCoins>=savedUncollected,'Accumulated income preserved during search '..f.Id)
  table.insert(result.Families,{Id=f.Id,Price=charge,Pet=reward.PetId,UID=reward.UID,Income=reward.CoinsPerSecond,Weight=reward.Weight,State=record.State,ClientInput=false})
  table.insert(tested,record);task.wait(4)
 end end
 -- Odds publication uses exactly the same effective context as actual selection.
 Mods:PublishOdds(p)
 for _,biome in ipairs({'Meadow','Forest'})do
  local context=Mods:GetOddsContext(p,biome)
  check(same(context,d.NormalTreeModifiers[biome]),'Index receives current server Luck '..biome)
  for _,f in ipairs(F.ByBiome[biome])do
   local O=require(G.NormalTreeOdds);local rows,total=O.Calculate(E[f.Id],d.NormalTreeModifiers[biome])
   for i,row in ipairs(rows)do check(math.abs(row.Probability-O.Weight(E[f.Id].Pets[i],context)/total)<1e-12,'Actual selection matches Index '..row.PetId)end
  end
 end
 stage('CooldownAndPreservation')
 for _,record in ipairs(tested)do
  waitFor(function()return record.State=='AVAILABLE'end,25,'natural restoration')
  check(record.Prompt.Enabled,'Prompt restored '..record.Object:GetAttribute('RewardPoolId'))
  for part,properties in pairs(record.Properties)do if part.Parent then
   for key,value in pairs(properties)do
    if key=='CFrame'then check((part.CFrame.Position-value.Position).Magnitude<.001,'Tree position restored')else check(part[key]==value,'Tree property restored '..key)end
   end
  end end
 end
 -- JSON save/copy restoration preserves UID, weight, flags, location and money.
 Sanctuary:Accrue(p);local saved=copy(d);local savedPetFields={}
 for _,v in ipairs(saved.Pets)do savedPetFields[v.UID]=fingerprint(v)end
 local restored=M.Apply(H:JSONDecode(H:JSONEncode(saved)),function()error('UID regenerated on restore')end)
 for _,v in ipairs(restored.Pets)do check(same(savedPetFields[v.UID],fingerprint(v)),'Mock restoration preserves '..v.UID)end
 check(restored.UncollectedSanctuaryCoins==saved.UncollectedSanctuaryCoins,'Uncollected balance survives copy restoration')
 -- Lucky regression uses existing Studio-only server fixtures, with zero balance.
 d.Currencies.Coins=0;local Lucky=K.GetService('LuckyTreeService');local cfg=require(G.Definitions.LuckyTreeDefinitions)
 for _,biome in ipairs({'Meadow','Forest'})do
  local event=Lucky:StudioFixture(biome);local prior=Progress:GetStreak(p)
  local usedBefore=#d.Pets;local money=d.Currencies.Coins
  local accepted,reward=Lucky:StudioTry(p,event,'economy-secret','Secret')
  check(accepted and #d.Pets==usedBefore+1 and d.Currencies.Coins==money,'Lucky Secret is free '..biome)
  task.wait(cfg.PersonalCooldown+.1);money=d.Currencies.Coins
  accepted,reward=Lucky:StudioTry(p,event,'economy-coins','Coins')
  check(accepted and d.Currencies.Coins-money==cfg.Biomes[biome].Coins,'Lucky coin amount unchanged '..biome)
  task.wait(cfg.PersonalCooldown+.1);money=d.Currencies.Coins
  accepted,reward=Lucky:StudioTry(p,event,'economy-luck','Luck')
  check(accepted and reward.Multiplier==cfg.Biomes[biome].LuckMultiplier and d.Currencies.Coins==money,'Lucky boost is free and unchanged '..biome)
  local entry=require(G.LuckyTreeRules).Event(d,event.EventId,false)
  check(entry.Used==3 and math.abs(reward.ExpiresAt-entry.Receipts[3].AwardedAt-300)<.001,'Three tries and five-minute boost '..biome)
  task.wait(cfg.PersonalCooldown+.1);check(not Lucky:StudioTry(p,event,'economy-fourth','Coins'),'Fourth Lucky try rejected '..biome)
  check(Progress:GetStreak(p)==prior,'Lucky did not add normal streak '..biome)
 end
 check(not K.GetService('BiomeService'):IsUnlocked(p,'Jungle'),'Unreleased Jungle unavailable')
 result.FinalSanctuaryRate=Sanctuary:GetIncome(d);result.FinalPetCount=#d.Pets
end,debug.traceback)
changed:Disconnect()
profile.Data=original;publishAll()
K.GetService('WeatherEventService'):ResumeAutomaticEvents()
if p.Character then p.Character.HumanoidRootPart.Anchored=false;p.Character:PivotTo(originalCF)end
result.Passed=ok;result.Error=not ok and err or nil;result.RestoredOriginalMock=true
workspace:SetAttribute('AKEconomyLive',H:JSONEncode(result));stage(ok and 'Complete' or 'Failed')
if not ok then warn(err)end
