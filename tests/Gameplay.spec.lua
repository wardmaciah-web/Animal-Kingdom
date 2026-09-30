local checks=0
local function check(condition,message) checks+=1;assert(condition,message) end
local function signal()
 local handlers={}
 return {Connect=function(_,fn) table.insert(handlers,fn);return {Disconnect=function() end} end,Fire=function(_,...) for _,fn in ipairs(handlers) do fn(...) end end}
end
local nodes={}
local function node(path)
 if nodes[path] then return nodes[path] end
 local n={Path=path,Name=path:match('[^.]+$')};nodes[path]=n
 local parent,name=path:match('^(.*)%.([^.]+)$')
 if parent then n.Parent=node(parent);n.Parent[name]=n end
 function n:WaitForChild(name) return assert(self[name],self.Path..'.'..name) end
 function n:FindFirstChild(name) return self[name] end
 return n
end
for path in pairs(sources) do node(path) end
local Vec={};Vec.__index=function(v,k) if k=='Magnitude' then return math.sqrt(v.X^2+v.Y^2+v.Z^2) end return Vec[k] end
local function vector(x,y,z) return setmetatable({X=x,Y=y,Z=z,_type='Vector3'},Vec) end
Vec.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
Vec.__add=function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
local now,uid=100,0
local delayed={}
local services,modules,overrides={}, {}, {}
local players={GetPlayers=function() return {} end}
local workspace={GetServerTimeNow=function() return now end}
local function instance(kind)
 local v={_type='Instance',ClassName=kind,Attributes={},Parent=workspace,Position=vector(0,0,0)}
 function v:GetDescendants() return self.Children or {} end
 function v:FindFirstChild(name) for _,child in ipairs(self.Children or {}) do if child.Name==name then return child end end end
 function v:GetFullName() return self.Name or self.ClassName end
 function v:GetPivot() return self.CFrame end
 function v:PivotTo(cf) self.CFrame=cf end
 function v:FindFirstChildWhichIsA(class) for _,child in ipairs(self.Children or {}) do if child:IsA(class) then return child end end end
 function v:IsA(class) return self.ClassName==class or (class=='BasePart' and self.ClassName=='Part') end
 function v:IsDescendantOf(parent) return self.Parent==parent end
 function v:SetAttribute(key,value) self.Attributes[key]=value end
 function v:GetAttribute(key) return self.Attributes[key] end
 return v
end
local dataByPlayer={}
services.PlayerDataService={Get=function(_,p) return dataByPlayer[p] end,Publish=function() end,PublishPath=function() end}
services.ProfileService={Profiles={},Loaded=signal(),Releasing=signal()}
local eventId=nil
services.WeatherGameplayService={GetModifier=function() return 1 end,GetRarityMultiplier=function() return 1 end,GetEventId=function() return eventId end}
services.EventModifierService={GetMultiplier=function() return 1 end,RefreshMovement=function() end}
local Knit={CreateService=function(s) services[s.Name]=s;return s end,GetService=function(name) return assert(services[name],name) end,CreateSignal=signal}
overrides['ReplicatedStorage.Packages.Knit']=Knit
overrides['ReplicatedStorage.Packages.Signal']={new=signal}
node('ReplicatedStorage.Packages.Knit');node('ReplicatedStorage.Packages.Signal')
overrides['ServerScriptService.BiomeTeleport.Landing']={FindFloor=function() return nil end};node('ServerScriptService.BiomeTeleport.Landing')
local randomCounter=0
local function rng()
 return {NextNumber=function() randomCounter=(randomCounter+37)%100;return randomCounter/100 end,NextInteger=function(_,a,b) return math.floor((a+b)/2) end}
end
local engine={ReplicatedStorage=node('ReplicatedStorage'),ServerScriptService=node('ServerScriptService'),Players=players,
 HttpService={GenerateGUID=function() uid+=1;return 'uid-'..uid end,JSONEncode=function() return '[]' end},CollectionService={HasTag=function(_,o,tag) return o:GetAttribute(tag)==true end},RunService={}}
local env=setmetatable({workspace=workspace,game={GetService=function(_,name) return assert(engine[name],name) end},
 Color3={fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end,new=function(...) return {...} end},
 Vector3={new=vector,zero=vector(0,0,0)},Random={new=rng},Instance={new=instance},
 typeof=function(v) return type(v)=='table' and v._type or typeof(v) end,
 os={clock=function() return now end,time=function() return now end},task={spawn=function(fn,...) fn(...) end,defer=function(fn,...) fn(...) end,delay=function(seconds,fn) table.insert(delayed,{At=now+seconds,Callback=fn}) end},warn=print,
},{__index=getfenv()})
local function requireModule(n)
 if overrides[n.Path] then return overrides[n.Path] end
 if modules[n.Path] then return modules[n.Path] end
 local fn=assert(loadstring(assert(sources[n.Path],n.Path),n.Path))
 setfenv(fn,setmetatable({script=n,require=requireModule},{__index=env}))
 local value=fn();modules[n.Path]=value;return value
end
local function loadService(name)
 local s=requireModule(node('ServerScriptService.ServerSource.Server.'..name));if s.KnitInit then s:KnitInit() end;return s
end
local migrations=requireModule(node('ReplicatedStorage.Shared.Gameplay.ProfileMigrations'))
local guid=engine.HttpService.GenerateGUID
local old={ForestCoins=12345,FriendshipTokens=99,OwnedPets={{UniquePetId='old',PetId='RemovedDefinition',Mutation='Unknown'},{UniquePetId='old',PetId='Dog'}},DisplayedPetIds={'old'},UnlockedBiomes={Forest=true},PetIndex={Dog=3},CustomField='preserve'}
migrations.Apply(old,guid)
check(old.Currencies.Coins==12345 and old.Currencies.FriendshipTokens==99,'Legacy balances lost')
check(#old.Pets==2 and old.Pets[1].PetId=='RemovedDefinition' and old.Pets[1].UID~=old.Pets[2].UID,'Unknown or duplicate pets lost')
check(old.CustomField=='preserve' and old.PetIndex.Dog.Count==3 and old.UnlockedBiomes.Meadow,'Existing progression lost')
old.Currencies.Coins=13579;migrations.Apply(old,guid);check(old.Currencies.Coins==13579,'Migration not idempotent')
local future={DataVersion=999};check(not pcall(migrations.Apply,future,guid),'Future profile downgraded')
local broken={ForestCoins=0/0,FriendshipTokens=math.huge};migrations.Apply(broken,guid);check(broken.Currencies.Coins==0 and broken.Currencies.FriendshipTokens==0,'Invalid balances survived')
print('PASS additive/idempotent migration, legacy copies and unknown definitions, future version rejection, malformed values')
local weighted=requireModule(node('ReplicatedStorage.Shared.Gameplay.WeightedRandom'))
local pool={{Weight=0,Id='zero'},{Weight=1,Id='one'},{Weight=3,Id='three'}}
check(weighted.Roll(pool,{NextNumber=function() return 0 end}).Id=='one','Zero weight selected')
check(weighted.Roll(pool,{NextNumber=function() return .25 end}).Id=='three','Boundary wrong')
check(weighted.Roll(pool,{NextNumber=function() return 1 end}).Id=='three','Upper boundary wrong')
check(not pcall(weighted.Roll,{{Weight=math.huge}},rng()),'Infinite weight accepted')
check(weighted.Roll({{Weight=0}},rng())==nil,'Empty table selected')
local economy=loadService('EconomyService')
local function player(id)
 local p=instance('Player');p.UserId=id;p.Parent=players
 local root=instance('Part');local humanoid={Health=100}
 p.Character={FindFirstChild=function(_,name) return name=='HumanoidRootPart' and root or nil end,FindFirstChildOfClass=function() return humanoid end}
 dataByPlayer[p]=migrations.Apply({},guid);return p,dataByPlayer[p],root
end
local p,data,root=player(1)
check(economy:Add(p,'Coins',1000),'Credit failed')
for _,amount in ipairs({-1,0/0,math.huge,1.1}) do check(not economy:Add(p,'Coins',amount),'Invalid credit accepted');check(not economy:Spend(p,'Coins',amount),'Invalid spend accepted') end
check(not economy:Add(p,'MadeUpCurrency',1),'Unknown currency accepted')
check(economy:Spend(p,'Coins',1000) and not economy:Spend(p,'Coins',1),'Overspend accepted')
check(economy:GetBalance(p,'ForestCoins')==0,'Compatibility currency diverged')
check(economy:Add(p,'Coins',9e15) and not economy:Add(p,'Coins',1),'Balance cap failed')
check(economy:Spend(p,'Coins',9e15),'Balance spend failed')
print('PASS authoritative economy: finite integers, supported currencies, cap, debit, overdraft, legacy adapter')
local modifiers=loadService('ModifierService')
local pets=loadService('PetService')
local biomes=loadService('BiomeService')
local loot=loadService('LootService')
local egg=loadService('EggService')
local resource=loadService('ResourceService')
services.NotificationService={Send=function(_,p,message) p.LastNotice=message end}
local function makeTree(biome)
 local tree=instance('Part');tree.CFrame={Position=vector(0,0,0)};tree.Transparency=.15;tree.CanCollide=true;tree.CanTouch=true;tree.CanQuery=true
 local anchor=instance('Attachment');anchor.Name='AKTreeInteraction'
 local prompt=instance('ProximityPrompt');prompt.Name='GatherPrompt';prompt.Enabled=true;prompt.Triggered=signal();anchor.Children={prompt};tree.Children={anchor,prompt}
 tree:SetAttribute('BiomeId',biome or 'Meadow');tree:SetAttribute('GatherableTree',true);tree:SetAttribute('AuthoredGatherableTree',true)
 resource:Register(tree);return tree,resource:GetRecords()[tree],prompt
end
local function treeHatch(p,tree)
 local ok,why=resource:Gather(p,tree);if not ok then return false,why end
 now+=1.2;local record=resource:GetRecords()[tree];resource:Finish(record)
 return record.State=='RESPAWNING',record.HatchResult
end
local index=loadService('IndexService')
local upgrades=loadService('UpgradeService')
local challenges=loadService('ChallengeService')
local dog=pets:Grant(p,'Dog','Normal');local dog2=pets:Grant(p,'Dog','Normal')
check(dog.UID~=dog2.UID and #data.Pets==2,'Pet UID collision')
check(pets:Equip(p,dog.UID,true),'Equip failed')
local foreign=pets:Grant(player(2),'Dog','Normal')
check(not pets:Equip(p,foreign.UID,true),'Foreign pet equipped')
pets:Flag(p,dog.UID,'Locked',true);check(not pets:RequestDelete(p,dog.UID),'Locked pet deletable')
pets:Flag(p,dog.UID,'Locked',false)
local ok,confirmation=pets:RequestDelete(p,dog.UID);check(ok,'Confirmation failed')
check(pets:Delete(p,dog.UID,confirmation.Token) and not pets:Delete(p,dog.UID,confirmation.Token),'Replayed delete succeeded')
check(#data.EquippedPets==0 and data.PetIndex.Dog~=nil,'Deletion removed Index or kept equip')
pets:Equip(p,dog2.UID,true);pets:AddEquippedXP(p,1000);check(dog2.Level>1 and pets:GetGatheringPower(p)>5,'Pet XP/power not applied')
print('PASS pet ownership, independent copies, locked protection, one-use confirmation, Index retention, XP and power')
local target=makeTree()
economy:Add(p,'Coins',10000)
local before=economy:GetBalance(p,'Coins');local count=#data.Pets
ok,confirmation=treeHatch(p,target)
check(ok and #confirmation.Results==1 and #data.Pets==count+1,'Tree did not immediately award one pet')
check(confirmation.EggId=='MeadowEgg' and economy:GetBalance(p,'Coins')>=before,'Tree hatch charged Coins or used wrong egg')
local another=makeTree();check(not resource:Gather(p,another),'Hatch presentation cooldown bypassed')
now+=5;data.PetStorageCapacity=#data.Pets;before=economy:GetBalance(p,'Coins');local scheduleCount=#delayed
check(not resource:Gather(p,another) and economy:GetBalance(p,'Coins')==before,'Full inventory charged')
check(resource:GetRecords()[another].State=='AVAILABLE' and #delayed==scheduleCount,'Full inventory consumed tree')
data.PetStorageCapacity=100;now+=5;root.Position=vector(100,0,0)
check(not resource:Gather(p,another),'Remote tree hatch at distance accepted');root.Position=vector(0,0,0)
now+=5;local lockedTree=makeTree('Forest');check(not resource:Gather(p,lockedTree),'Locked biome tree hatched')
check(not egg:Hatch(p,target,1),'Retired ground egg entry awarded pet')
check(not egg:HatchFromTree(p,another,{}),'Unclaimed tree manufactured pet')
-- All fifty real service records can be in flight independently before any completion.
local allUIDs,concurrent={},{}
for i=1,50 do
 local candidate,profile=player(100+i);local tree=makeTree()
 check(resource:Gather(candidate,tree),'Independent player tree claim failed')
 table.insert(concurrent,{Player=candidate,Data=profile,Tree=tree})
end
now+=1.2
for _,entry in ipairs(concurrent) do
 local record=resource:GetRecords()[entry.Tree];resource:Finish(record)
 check(record.State=='RESPAWNING' and #entry.Data.Pets==1,'Concurrent tree inventory crossed')
 local pet=entry.Data.Pets[1];check(not allUIDs[pet.UID],'Cross-player UID collision');allUIDs[pet.UID]=true
 local size=#entry.Data.Pets;resource:Finish(record);check(#entry.Data.Pets==size,'Repeated completion duplicated pet')
end
print('PASS free tree hatch, capacity before lock, range, cooldown, locked biome, retired egg remote, 50 simultaneous independent tree claims')
now+=5;data.Settings.AutoDelete={Common=true,Rare=true,Legendary=true};count=#data.Pets
ok,confirmation=treeHatch(p,another);check(ok,'Auto-delete tree hatch failed')
check(confirmation.Results[1].AutoDeleted or confirmation.Results[1].Pet.Prismatic,'Configured auto-delete ignored')
local mathModule=requireModule(node('ReplicatedStorage.Shared.Gameplay.PetMath'))
check(mathModule.Protected({PetId='Dog',Prismatic=true}) and mathModule.Protected({PetId='Dog',Favorite=true}) and mathModule.Protected({PetId='Dog',Locked=true}),'Auto-delete protection failed')
check(not biomes:Unlock(p,'Jungle'),'Skipped previous biome')
economy:Add(p,'Coins',1e8);check(biomes:Unlock(p,'Forest'),'Forest purchase failed')
check(not biomes:Unlock(p,'Forest'),'Repeat biome purchase succeeded')
check(upgrades:Purchase(p,'PetStorage') and data.PetStorageCapacity>=75,'Storage upgrade failed')
check(not upgrades:Purchase(p,'Fake'),'Invalid upgrade accepted')
challenges:Ensure(p);challenges:Track(p,'Gather',20,'Meadow')
check(data.DailyChallenges.Entries.Trees20.Progress==20,'Challenge progress missing')
before=economy:GetBalance(p,'Coins');check(challenges:Claim(p,'Daily','Trees20'),'Challenge claim failed')
check(not challenges:Claim(p,'Daily','Trees20') and economy:GetBalance(p,'Coins')==before+1000,'Double challenge payout')
now=86401;challenges:Ensure(p);check(data.DailyChallenges.Entries.Trees20.Progress==0 and not data.DailyChallenges.Entries.Trees20.Claimed,'Daily rollover failed')
local definitions=requireModule(node('ReplicatedStorage.Shared.Gameplay.Definitions.PetDefinitions'))
for _,def in ipairs(definitions.Ordered) do data.PetIndex[def.PetId]={Count=1,Variants={Normal=true}} end
check(index:Claim(p,25) and not index:Claim(p,25),'Index reward repeated')
local seasons=loadService('SeasonalService');check(not seasons:IsActive('Halloween'),'Inactive season started')
print('PASS auto-delete protection, progression prerequisites, upgrades, challenge one-time rewards/UTC rollover, Index one-time claims, inactive seasons')
local policy=requireModule(node('ServerScriptService.ServerSource.Utilities.GameplayRequestPolicy'))
now+=10;check(policy.Check(p,'Equip',{UID=dog2.UID,Equipped=true}),'Valid policy rejected')
now+=1;check(not policy.Check(p,'Equip',{UID=dog2.UID,Equipped=true,Coins=10000}),'Extra authoritative field accepted')
now+=1;check(not policy.Check(p,'Hatch',{Target=target,Count=100}),'Invalid hatch count accepted')
now+=1;check(not policy.Check(p,'GiveCoins',{Amount=10000}),'Invented action accepted')
now+=1;check(not policy.Check(p,'Place',{Id='Chair',Offset=vector(0/0,0,0),Rotation=0}),'NaN placement accepted')
now+=1;check(policy.Check(p,'TutorialNext',{}),'Valid action failed');check(not policy.Check(p,'TutorialNext',{}),'Global rate limit bypassed')
print('PASS remote action schemas, no client-authoritative fields, malformed placement, global/per-action rate limits')
table.clear(delayed);data.Settings.AutoDelete={};data.PetStorageCapacity=100;now+=10
local tree,record,prompt=makeTree()
local other,otherData=player(999)
local countBefore=#data.Pets;local originalPivot=tree:GetPivot()
before=economy:GetBalance(p,'Coins');local otherBefore=economy:GetBalance(other,'Coins')
check(resource:Gather(p,tree),'First gather rejected')
check(not resource:Gather(other,tree),'Two players claimed the same tree')
check(record.State=='SHAKING' and not prompt.Enabled,'Tree did not lock before yielding')
local claim=record.Claim
check(not egg:HatchFromTree(other,tree,claim),'Other player stole tree claim')
check(not egg:HatchFromTree(p,tree,{}),'Forged claim accepted')
now+=1.2;resource:Finish(record)
check(record.State=='RESPAWNING' and tree.Transparency==1 and not tree.CanCollide and not tree.CanTouch and not tree.CanQuery and not prompt.Enabled,'Tree not completely hidden/disabled')
check(#data.Pets==countBefore+1 and #otherData.Pets==0,'Tree race awarded wrong pet owner')
check(economy:GetBalance(p,'Coins')>before and economy:GetBalance(other,'Coins')==otherBefore,'Secondary reward crossed players')
check(#delayed==1 and delayed[1].At==now+20 and tree:GetAttribute('RespawnAt')==now+20,'Respawn deadline was not exactly twenty seconds')
check(not egg:HatchFromTree(p,tree,claim),'Committed claim replay duplicated pet')
resource:Finish(record);check(#data.Pets==countBefore+1 and #delayed==1,'Repeated finish duplicated pet or cooldown')
check(not resource:Gather(other,tree),'Respawning tree harvested')
now+=19.999;check(now<delayed[1].At and record.State=='RESPAWNING','Tree respawned early')
now+=.001;delayed[1].Callback()
check(record.State=='AVAILABLE' and tree:GetPivot()==originalPivot and tree.Transparency==.15 and tree.CanCollide and tree.CanTouch and tree.CanQuery and prompt.Enabled,'Same original tree not restored exactly')
-- Capacity can change while shaking; cancellation must return the original tree immediately.
local fullTree,fullRecord=makeTree();now+=5;check(resource:Gather(p,fullTree),'Capacity recheck setup failed')
data.PetStorageCapacity=#data.Pets;local jobs=#delayed;now+=1.2;resource:Finish(fullRecord)
check(fullRecord.State=='AVAILABLE' and fullTree.Transparency==.15 and #delayed==jobs and p.LastNotice=='PET INVENTORY FULL','Mid-shake inventory fill consumed tree')
data.PetStorageCapacity=100
local deathTree,deathRecord=makeTree();now+=5;check(resource:Gather(p,deathTree),'Death recheck setup failed')
p.Character:FindFirstChildOfClass('Humanoid').Health=0;now+=1.2;resource:Finish(deathRecord)
check(deathRecord.State=='AVAILABLE','Death before commit consumed tree');p.Character:FindFirstChildOfClass('Humanoid').Health=100
print('PASS real resource/egg integration: atomic race, claim owner/replay safety, single pet, exact hiding and twenty-second restoration, mid-shake full/death cancellation')
-- Every biome routes through its central EggId without a purchase or caller-selected pet.
local biomeDefs=requireModule(node('ReplicatedStorage.Shared.Gameplay.Definitions.BiomeDefinitions'))
local eggDefs=requireModule(node('ReplicatedStorage.Shared.Gameplay.Definitions.EggDefinitions'))
local hatchCounts,gatherCounts={},{}
egg.Hatched:Connect(function(owner,n) hatchCounts[owner]=(hatchCounts[owner] or 0)+n end)
resource.Harvested:Connect(function(owner) gatherCounts[owner]=(gatherCounts[owner] or 0)+1 end)
for i,biome in ipairs(biomeDefs.Ordered) do
 local owner,profile=player(2000+i);profile.UnlockedBiomes[biome.Id]=true
 local t=makeTree(biome.Id);local success,reveal=treeHatch(owner,t)
 check(success and reveal.EggId==biome.EggId and #profile.Pets==1,'Biome to egg routing failed: '..biome.Id)
 check(profile.PetIndex[profile.Pets[1].PetId]~=nil,'Tree hatch Index missing: '..biome.Id)
 check(hatchCounts[owner]==1 and gatherCounts[owner]==1,'Tree/hatch challenges must each fire once')
 resource:Finish(resource:GetRecords()[t]);check(hatchCounts[owner]==1 and gatherCounts[owner]==1,'Repeated finish repeated challenge events')
end
for _,pet in ipairs(definitions.Ordered) do
 local found=false;for _,entry in ipairs(eggDefs[biomeDefs[pet.Biome].EggId].Pets) do if entry.PetId==pet.PetId then found=true;break end end
 check(found,'Retiring egg stands made an Index pet unobtainable: '..pet.PetId)
end
local leaving,leavingData=player(3000);local leaveTree,leaveRecord=makeTree();check(treeHatch(leaving,leaveTree),'Departure test hatch failed')
local savedUID=leavingData.Pets[1].UID;dataByPlayer[leaving]=nil
now=delayed[#delayed].At;delayed[#delayed].Callback()
check(leaveRecord.State=='AVAILABLE' and leavingData.Pets[1].UID==savedUID and #leavingData.Pets==1,'Departure changed committed pet or prevented tree restoration')
now+=1;check(not policy.Check(p,'Hatch',{Target=tree,Count=1}),'Retired normal hatch remote accepted')
now+=1;check(not policy.Check(p,'Gather',{Target=tree,EggId='MythicalEgg'}),'Client changed tree egg ID')
print('PASS all twelve free biome eggs, one challenge event each, all 304 Index pets obtainable, leave-after-commit restoration, retired/forged egg requests')
-- Exercise the actual resolver against a minimal Instance tree in all seven asset categories.
local function assetInstance(class)
 local props={ClassName=class,Children={},Attributes={}}
 local object
 local methods={}
 function methods:IsA(name) return class==name or (class=='Part' and name=='BasePart') end
 function methods:SetAttribute(k,v) props.Attributes[k]=v end
 function methods:GetAttribute(k) return props.Attributes[k] end
 function methods:GetDescendants()
  local result={};for _,child in ipairs(props.Children) do table.insert(result,child);for _,d in ipairs(child:GetDescendants()) do table.insert(result,d) end end;return result
 end
 function methods:FindFirstChild(name) for _,child in ipairs(props.Children) do if child.Name==name then return child end end end
 function methods:FindFirstChildWhichIsA(name,recursive)
  for _,child in ipairs(recursive and self:GetDescendants() or props.Children) do if child:IsA(name) then return child end end
 end
 function methods:Destroy() props.Destroyed=true end
 function methods:Clone()
  local clone=assetInstance(class)
  for key,value in pairs(props) do if key~='Children' and key~='Parent' and key~='Attributes' and key~='PrimaryPart' then clone[key]=value end end
  for key,value in pairs(props.Attributes) do clone:SetAttribute(key,value) end
  for _,child in ipairs(props.Children) do local duplicate=child:Clone();duplicate.Parent=clone end
  return clone
 end
 object=setmetatable({}, {__index=function(_,key) return methods[key] or props[key] end,__newindex=function(_,key,value)
  props[key]=value;if key=='Parent' and value then table.insert(value.Children,object) end
 end})
 return object
end
env.Instance={new=assetInstance};env.CFrame={new=function(position) return {Position=position or vector(0,0,0),ToObjectSpace=function(_,cf) return cf end} end}
env.Enum={Material={SmoothPlastic='SmoothPlastic'},PartType={Ball='Ball'}}
local assets=assetInstance('Folder');node('ReplicatedStorage').Assets=assets
local resolver=requireModule(node('ReplicatedStorage.Shared.Gameplay.AssetResolver'))
for _,category in ipairs(resolver.Categories) do
 local folder=assetInstance('Folder');folder.Name=category;folder.Parent=assets
 local fallback=resolver.Create(category,'Dog');check(fallback:GetAttribute('Placeholder')==true and fallback:FindFirstChildWhichIsA('BasePart',true)~=nil,'Missing placeholder '..category)
 local template=assetInstance('Model');template.Name='Dog';local body=assetInstance('Part');body.Name='ImportedGeometry';body.Parent=template;template.Parent=folder
 local real=resolver.Create(category,'Dog')
 check(real~=template and real:FindFirstChild('ImportedGeometry')~=nil and not real:GetAttribute('Placeholder'),'Asset swap failed '..category)
end
print('PASS actual asset resolver: fallback and imported-model selection for pets, eggs, trees, resources, furniture, decorations, seasonal')
local currentWeather={Phase='Break',EventId='',StartedAt=0}
services.WeatherEventService={GetCurrentState=function() return currentWeather end}
local legacyWeather=loadService('EventModifierService')
local weatherGameplay=loadService('WeatherGameplayService');modifiers:KnitInit()
local eventDefinitions=requireModule(node('ReplicatedStorage.Shared.EventDefinitions'))
local eventCount=0
for id,definition in pairs(eventDefinitions) do
 if type(definition)=='table' and definition.Id then
  eventCount+=1;currentWeather={Phase='Event',EventId=id,StartedAt=now-15}
  for _,key in ipairs({'Coins','Luck','MutationChance','ResourceRewards','GatheringPower','WalkSpeed','PetXP'}) do
   local value=modifiers:Get(p,key,'Snow');check(value>0 and value<math.huge,'Non-finite weather modifier '..id..'/'..key)
  end
  currentWeather.Phase='Break'
  for _,key in ipairs({'Coins','Luck','MutationChance','ResourceRewards','GatheringPower','WalkSpeed','PetXP'}) do check(modifiers:Get(p,key,'Snow')==1,'Stale weather modifier '..id..'/'..key) end
 end
end
check(eventCount==18,'Not all weather definitions were tested')
currentWeather={Phase='Event',EventId='Golden',StartedAt=now};check(modifiers:Get(p,'Coins')==10,'Golden multiplier wrong')
currentWeather={Phase='Event',EventId='Rainbow',StartedAt=now};check(modifiers:Get(p,'Luck')==2,'Rainbow multiplier wrong')
currentWeather={Phase='Event',EventId='Heatwave',StartedAt=now};check(modifiers:Get(p,'ResourceRewards','Desert')==1.25 and modifiers:Get(p,'ResourceRewards','Meadow')==1,'Heatwave biome condition wrong')
currentWeather={Phase='Break'}
print('PASS production weather/modifier services: all 18 event modifier sets, immediate cleanup, Golden/Rainbow values and Heatwave biome restrictions')
local plot=instance('Part');plot:SetAttribute('OwnerUserId',p.UserId);plot:SetAttribute('Claimed',true)
local plotFrame={PointToObjectSpace=function(_,position) return position end}
overrides['ServerScriptService.PlotLocator']={getPlots=function() return {plot} end,getBounds=function() return plotFrame,vector(100,2,100) end};node('ServerScriptService.PlotLocator')
local plots=loadService('PlotService')
check(plots:GetPlot(p)==plot and plots:GetPlot(other)==nil,'Plot ownership crossed')
check(plots:CanVisit(other,p),'Default visitor permission missing')
check(plots:SetVisitors(p,false) and not plots:CanVisit(other,p) and plots:CanVisit(p,p),'Visitor permission failed')
check(not plots:SetVisitors(other,true),'Non-owner changed plot permissions')
local shop=loadService('ShopService');before=economy:GetBalance(p,'Coins')
check(shop:Buy(p,'WoodenChair') and data.Items.WoodenChair==1 and economy:GetBalance(p,'Coins')==before-500,'Shop ownership/price mismatch')
check(not shop:Buy(p,'FakeItem') and not shop:Buy(p,'Pumpkin'),'Unknown/inactive shop item accepted')
data.Items.WoodenChair=20;check(not shop:Buy(p,'WoodenChair'),'Shop capacity bypassed')
local placement=loadService('PlacementService')
check(not placement:Place(other,'WoodenChair',vector(0,0,0),0),'Placement by player without plot accepted')
check(not placement:Place(p,'FakeItem',vector(0,0,0),0),'Undefined placement accepted')
check(not placement:Place(p,'WoodenChair',vector(0,5,0),45),'Invalid placement rotation/height accepted')
check(not placement:Remove(other,'stolen-placement'),'Another player removed placement')
print('PASS plot ownership/visitor permissions, definition-priced shop inventory/capacity, inactive seasonal shop, placement ownership/definition/transform rejection')
print('GAMEPLAY_TESTS_DONE assertions='..checks..' failures=0')
