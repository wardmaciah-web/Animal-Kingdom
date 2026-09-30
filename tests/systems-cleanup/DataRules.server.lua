-- QA ONLY: temporary Studio Play Script; tests pure data repair and the existing mock profile.
local K=require(game.ReplicatedStorage.Packages.Knit);K.OnStart():await()
local Http=game:GetService('HttpService');local p=game.Players:GetPlayers()[1]
assert(game:GetService('RunService'):IsStudio() and p:GetAttribute('ProfileDataMode')=='StudioMockSnapshot','Mock profile required')
local G=game.ReplicatedStorage.Shared.Gameplay;local L=require(G.PetLocations)
local checks={};local function check(v,name)assert(v,name);table.insert(checks,name)end
local profile=K.GetService('ProfileService').Profiles[p];local original=profile.Data
local originalCF=p.Character:GetPivot()
local function copy(t)local n={}for k,v in pairs(t)do n[k]=type(v)=='table' and copy(v) or v end return n end
local ok,err=xpcall(function()
 local slots={};for i=1,64 do slots[i]=true end
 local d={Pets={},PetStorageCapacity=0,RecoveryData={},ActiveHeldPetUID=''}
 for i=1,64 do table.insert(d.Pets,{UID='fixture-'..i,Location='Sanctuary',LocationSlot=i})end
 local legacy={UID='legacy-70',Location='Sanctuary',LocationSlot=70,Weight=19.5,XP=12,Level=4,Locked=true,Mutation='Normal',Cosmetic='FlowerCrown'}
 table.insert(d.Pets,legacy)
 check(L.ReconcileSanctuary(d,slots) and legacy.Location=='Inventory' and L.Find(d,'legacy-70')==legacy,'full 64-slot repair returns exact legacy record to Inventory')
 check(legacy.Weight==19.5 and legacy.XP==12 and legacy.Locked and legacy.Cosmetic=='FlowerCrown','repair preserves pet stats and flags')
 check(d.RecoveryData.SanctuarySlotRepairs[1].PreviousSlot==70 and d.PetStorageCapacity==1,'repair journals previous slot and preserves return capacity')
 check(not L.ReconcileSanctuary(d,slots) and #d.RecoveryData.SanctuarySlotRepairs==1,'repair is idempotent')
 L.Set(d.Pets[1],'Inventory');L.Set(legacy,'Sanctuary',70)
 check(L.ReconcileSanctuary(d,slots) and legacy.LocationSlot==1 and legacy.Location=='Sanctuary','repair reuses real free slot')
 L.Set(legacy,'Sanctuary',70);check(not L.ReconcileSanctuary(d,{}) and legacy.LocationSlot==70,'unresolved empty slot map never migrates pets')
 local eligible=require(G.IndexCatalog).Current();local history={HistoricalUnknown={Count=1,Variants={Normal=true}}};local count=0
 for id in pairs(eligible)do history[id]={Count=1,Variants={Normal=true}};count+=1 end
 local found,total,percent=require(G.Definitions.PetDefinitions).IndexProgress(history)
 check(count>0 and found==count and total==count and percent==100,'currently obtainable Index completion reaches 100 percent')
 check(history.HistoricalUnknown~=nil,'historical discovery retained')
 profile.Data=copy(original);local data=profile.Data;local Pets=K.GetService('PetService');local Data=K.GetService('PlayerDataService')
 data.Pets={};data.GardenExpeditions={};data.ActiveHeldPetUID='';Pets:Publish(p)
 data.PetIndex=history;data.IndexRewards={}
 local index=K.GetService('IndexService')
 for _,percentValue in ipairs({25,50,75,100})do check(index:Claim(p,percentValue) and not index:Claim(p,percentValue),'Index reward claimed once '..percentValue)end
 local plot=assert(K.GetService('PlotService'):GetPlot(p));local pad=assert(plot:FindFirstChild('IncomeCollector'))
 p.Character:PivotTo(pad.CFrame+Vector3.new(0,4,0));p.Character.HumanoidRootPart.Anchored=true
 data.UncollectedSanctuaryCoins=12.75;data.Currencies.Coins=require(G.Definitions.CurrencyDefinitions).Coins.MaxBalance
 Data:Publish(p,'Currencies','UncollectedSanctuaryCoins');task.wait(.2)
 check(pad:GetAttribute('CollectibleCoins')==0 and pad.IncomeStatus.Balance.Text:find('Coin capacity reached',1,true),'full-wallet collector displays EMPTY and capacity feedback')
 check(K.GetService('EconomyService'):Spend(p,'Coins',2,'MockQA'),'mock wallet spend opens room')
 task.wait(.2);check(pad:GetAttribute('CollectibleCoins')==2 and pad.IncomeStatus.Balance.Text:find('READY',1,true),'currency update refreshes collectible whole amount')
 local accepted,result=K.GetService('PlotService'):Collect(p)
 check(accepted and result.Amount==2 and data.UncollectedSanctuaryCoins==10.75,'partial-cap collection retains exact remainder')
 task.wait(.2);check(pad:GetAttribute('CollectibleCoins')==0,'collector returns to EMPTY after cap-limited payout')
 workspace:SetAttribute('AKIndexEligibleCount',count)
end,debug.traceback)
profile.Data=original;K.GetService('PetService'):Publish(p)
for key in pairs(original)do K.GetService('PlayerDataService'):Publish(p,key)end
p.Character.HumanoidRootPart.Anchored=false;p.Character:PivotTo(originalCF)
workspace:SetAttribute('AKDataRulesResults',Http:JSONEncode({Passed=ok,Checks=checks,Error=not ok and err or nil}))
if not ok then warn(err)end
