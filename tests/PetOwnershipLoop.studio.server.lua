local RS=game.ReplicatedStorage
local Knit=require(RS.Packages.Knit)
local Players=game:GetService('Players')
local profiles=Knit.GetService('ProfileService')
local pets=Knit.GetService('PetService')
local resource=Knit.GetService('ResourceService')
local eggs=Knit.GetService('EggService')
local plot=Knit.GetService('PlotService')
local sanctuary=Knit.GetService('SanctuaryService')
local garden=Knit.GetService('GardenExpeditionService')
local Definitions=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Locations=require(RS.Shared.Gameplay.PetLocations)
local Stats=require(RS.Shared.Gameplay.PetStats)
local Sell=require(RS.Shared.Gameplay.SellValueCalculator)
local Geometry=require(RS.Shared.Gameplay.PetVisualGeometry)
local function copy(t)local n={};for k,v in pairs(t)do n[k]=type(v)=='table' and copy(v) or v end;return n end
local player=Players:GetPlayers()[1];assert(player:GetAttribute('ProfileDataMode')=='StudioMockSnapshot')
local profile=profiles.Profiles[player];assert(profile and profile:IsActive())
_G.AKPetOwnershipOriginal=_G.AKPetOwnershipOriginal or {Data=profile.Data,Pivot=player.Character:GetPivot(),Anchored=player.Character.HumanoidRootPart.Anchored}
local data=copy(require(RS.SharedSource.Datas.ProfileTemplate))
require(RS.Shared.Gameplay.ProfileMigrations).Apply(data,function()return game.HttpService:GenerateGUID(false)end)
data.Currencies.Coins=1000000;data.ForestCoins=data.Currencies.Coins;data.UnlockedBiomes.Forest=true;data.TutorialCompleted=true;data.SanctuaryIncomeUpdatedAt=workspace:GetServerTimeNow()
profile.Data=data;profiles.Client.GetData:Fire(player,data);pets:Publish(player)
local root=player.Character.HumanoidRootPart;root.Anchored=true
local report={Assertions=0,TreeRewards={},Failures={},Checks={}}
local function check(value,name)report.Assertions+=1;table.insert(report.Checks,name);assert(value,name)end
local trees={}
for object,record in pairs(resource:GetRecords())do if record.IsTree and record.Biome=='Forest' then table.insert(trees,object)end end
table.sort(trees,function(a,b)return a:GetFullName()<b:GetFullName()end)
check(#trees>=7,'At least seven physical Forest trees available')
for i=1,6 do
 local tree=trees[i];local record=resource:GetRecords()[tree];local definition=assert(require(RS.Shared.Gameplay.Definitions.ForestTreeDefinitions).Get(tree,'Forest'))
 player.Character:PivotTo(CFrame.new(record.InteractionPosition+Vector3.new(0,2,4)))
 eggs:StudioForceNext(player,definition.Pets[(i-1)%3+1].PetId)
 local before=#data.Pets;local accepted,why=resource:Gather(player,tree);check(accepted,'Tree search accepted '..i..' '..tostring(why))
 local duplicates=0;for _=1,12 do if resource:Gather(player,tree)then duplicates+=1 end end
 check(duplicates==0,'Rapid search rejected '..i)
 task.wait(1.05)
 check(record.Awarded and #data.Pets==before+1,'Tree committed one reward '..i)
 local pet=data.Pets[#data.Pets];local result=record.HatchResult.Results[1]
 check(pet.Weight>=Definitions[pet.PetId].BaseWeight,'Tree weight at least base '..i)
 check(pet.Location==(i<=5 and 'Held' or 'Inventory') and (i>5 or pet.LocationSlot==i),'Destination '..i)
 check(result.Pet.UID==pet.UID and result.Pet.Weight==pet.Weight and result.Pet.CoinsPerSecond==Stats.Income(pet),'Reveal uses exact owned stats '..i)
 check(data.PetIndex[pet.PetId]~=nil,'Species Index discovery '..i)
 table.insert(report.TreeRewards,{UID=pet.UID,PetId=pet.PetId,Weight=pet.Weight,Income=pet.CoinsPerSecond,Location=pet.Location,Slot=pet.LocationSlot,Cost=definition.Cost})
 task.wait(3)
end
local seventh=trees[7];local rec=resource:GetRecords()[seventh];player.Character:PivotTo(CFrame.new(rec.InteractionPosition+Vector3.new(0,2,4)))
local balance=data.Currencies.Coins;local count=#data.Pets;data.PetStorageCapacity=1
local allowed,message=eggs:CheckTreeHatch(player,seventh)
check(not allowed and message:find('PET STORAGE FULL',1,true) and data.Currencies.Coins==balance and #data.Pets==count,'Both full rejects before charge')
data.PetStorageCapacity=50
check(plot:Teleport(player),'Visit owned plot')
local a=Locations.At(data,'Held',1);local originalWeight=a.Weight
local f=assert(pets:Grant(player,'ForestBadger','Normal'));f.Weight=Definitions.ForestBadger.BaseWeight*2;pets:Publish(player)
check(pets:Move(player,f.UID,'Sanctuary',18),'Place F into display 18')
check(pets:SwapSanctuary(player,1,18,a.UID,f.UID),'Swap A with F')
check(Locations.At(data,'Held',1)==f and Locations.At(data,'Sanctuary',18)==a and a.Weight==originalWeight,'Same owned IDs and weights after swap')
check(not pets:SwapSanctuary(player,1,18,a.UID,f.UID),'Duplicate swap cannot reverse committed exchange')
check(pets:Move(player,f.UID,'Inventory'),'Store Held pet')
check(pets:SwapSanctuary(player,1,18,'',a.UID),'Return display pet into empty Held slot')
check(Locations.At(data,'Held',1)==a and not Locations.At(data,'Sanctuary',18),'Empty-slot transfer preserves UID')
local light=assert(pets:Grant(player,'ForestBadger','Normal'));light.Weight=12
local heavy=assert(pets:Grant(player,'ForestBadger','Normal'));heavy.Weight=24
pets:Publish(player)
check(pets:Move(player,light.UID,'Sanctuary',1),'Place base-weight Badger')
check(pets:Move(player,heavy.UID,'Sanctuary',2),'Place heavy Badger')
check(heavy.CoinsPerSecond>light.CoinsPerSecond,'Heavy Badger earns more')
check(math.abs(sanctuary:GetIncome(data)-Stats.Income(light)-Stats.Income(heavy))<.001,'Sanctuary total equals exact individual sum')
local income=sanctuary:GetIncome(data);local held=Locations.At(data,'Held',2);held.Weight=Definitions[held.PetId].BaseWeight*3;pets:Publish(player)
check(sanctuary:GetIncome(data)==income,'Held potential income is not paid')
local g=assert(pets:Grant(player,'MeadowFluffyLop','Normal'));local duration=next(require(RS.Shared.Gameplay.Definitions.GardenDefinitions).Durations)
check(garden:Start(player,g.UID,duration,'garden-send-weight-qa'),'Send normal Inventory pet to Garden')
check(g.Location=='Garden' and not pets:Move(player,g.UID,'Held'),'Garden pet cannot also be Held')
local favored=assert(pets:Grant(player,'MeadowFieldMouse','Normal'));favored.Favorite=true
local locked=assert(pets:Grant(player,'ForestBrownBat','Normal'));locked.Locked=true
pets:Publish(player)
local expected,total=0,0;for _,pet in ipairs(data.Pets)do if Sell.Eligible(pet)then expected+=1;total+=Sell.Calculate(pet)end end
local ok,quote=pets:QuoteSale(player);check(ok and quote.Count==expected and quote.Total==total,'Sell All quote uses exact server total')
local discoveryCount={};for id,entry in pairs(data.PetIndex)do discoveryCount[id]=entry.Count end
local beforeSale=data.Currencies.Coins
local sold,result=pets:Sell(player,quote.Token);check(sold and result.Count==expected and data.Currencies.Coins==beforeSale+total,'Sell All exact payout')
for _=1,12 do check(not pets:Sell(player,quote.Token),'Duplicate sale token rejected')end
check(data.Currencies.Coins==beforeSale+total,'No duplicate coins')
check(pets:FindOwned(data,favored.UID) and pets:FindOwned(data,locked.UID) and pets:FindOwned(data,g.UID),'Favorite locked Garden protected')
check(pets:FindOwned(data,a.UID) and pets:FindOwned(data,light.UID) and pets:FindOwned(data,heavy.UID),'Held and Sanctuary protected')
for id,c in pairs(discoveryCount)do check(data.PetIndex[id].Count==c,'Discovery survives sale '..id)end
local trip;for _,t in ipairs(data.GardenExpeditions)do if t.UID==g.UID then trip=t end end
local gardenWeight=g.Weight;trip.ReadyAt=os.time()-1
check(garden:Claim(player,g.UID,'garden-claim-weight-qa') and g.Location=='Inventory' and g.Weight==gardenWeight,'Garden claim returns same instance/weight to reserved space')
local currentCoins=data.Currencies.Coins
local quoteOK,stale=pets:QuoteSale(player,g.UID);check(quoteOK,'Individual sale quotation');g.Favorite=true
check(not pets:Sell(player,stale.Token) and data.Currencies.Coins==currentCoins and pets:FindOwned(data,g.UID),'Changed protection invalidates quote without payout/removal')
g.Favorite=false;pets:Publish(player)
local encoded=game.HttpService:JSONEncode(data);local restored=game.HttpService:JSONDecode(encoded)
require(RS.Shared.Gameplay.ProfileMigrations).Apply(restored,function()error('No new UID on reload')end)
for _,pet in ipairs(data.Pets)do local re=Locations.Find(restored,pet.UID);check(re and re.Weight==pet.Weight and re.Location==pet.Location and re.LocationSlot==pet.LocationSlot,'Persist owned state '..pet.UID)end
check(not pets:Move(player,'not-owned','Held'),'Foreign/unowned UID rejected')
report.Selling={Count=expected,Total=total,DiscoveryRetained=true,DoubleCredit=false}
report.Income={Light=light.CoinsPerSecond,Heavy=heavy.CoinsPerSecond,Total=sanctuary:GetIncome(data)}
report.SavedRoundtrip=true
_G.AKPetQAState={Player=player,Data=data,Light=light.UID,Heavy=heavy.UID,GardenPet=g.UID,Report=report}
root.Anchored=false
pets:Publish(player)
task.wait(.4)
local folder=workspace.Sanctuaries:FindFirstChild(tostring(player.UserId)).DisplayedPets
local lm,hm=folder:FindFirstChild(light.UID),folder:FindFirstChild(heavy.UID)
check(lm and hm,'Real Sanctuary clones present')
local lb,hb=Geometry.Measure(lm),Geometry.Measure(hm)
check(hb.Size.Magnitude>lb.Size.Magnitude*1.2,'Heavier Sanctuary clone visibly larger')
for _,model in ipairs({lm,hm})do
 local bounds=Geometry.Measure(model,CFrame.new());local gap=bounds.Min.Y-model:GetAttribute('DisplaySurfaceY')
 check(math.abs(gap-.04)<.02,'Weighted clone sits above shelf')
 check(model:GetAttribute('Weight')>0 and model:FindFirstChild('PetInformation',true)~=nil,'Weighted overhead label present')
end
report.SanctuarySizes={Light=tostring(lb.Size),Heavy=tostring(hb.Size)}
return report
