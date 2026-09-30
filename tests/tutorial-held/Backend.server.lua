-- Inject as a temporary Script in Studio Play only; asserts the existing profile is mock.
local K=require(game.ReplicatedStorage.Packages.Knit);K.OnStart():await()
local H=game:GetService('HttpService');local p=game.Players:GetPlayers()[1]
K.GetService('ProfileService'):WaitUntilProfileLoaded(p)
local profile=K.GetService('ProfileService').Profiles[p]
assert(game:GetService('RunService'):IsStudio() and p:GetAttribute('ProfileDataMode')=='StudioMockSnapshot' and profile.is_mock,'Mock profile required')
local function copy(v)if type(v)~='table'then return v end local n={}for k,x in pairs(v)do n[k]=copy(x)end return n end
local original=copy(profile.Data);local originalCF=p.Character:GetPivot()
local G=game.ReplicatedStorage.Shared.Gameplay;local L=require(G.PetLocations);local M=require(G.ProfileMigrations)
local P=K.GetService('PetService');local T=K.GetService('TutorialService');local Plot=K.GetService('PlotService');local D=K.GetService('PlayerDataService')
local Display=require(game.ServerScriptService.ServerSource.Utilities.MeadowSanctuaryDisplay)
local checks={};local function check(v,label)assert(v,label);checks[#checks+1]=label end
local function fingerprint(pet)return H:JSONEncode({pet.UID,pet.PetId,pet.Weight,pet.Level,pet.XP,pet.Mutation,pet.Shiny,pet.Prismatic,pet.Favorite,pet.Locked,pet.Cosmetic,pet.AcquiredAt})end
local ok,err=xpcall(function()
 profile.Data=M.Apply(copy(require(game.ReplicatedStorage.SharedSource.Datas.ProfileTemplate)),function()return H:GenerateGUID(false)end)
 local d=profile.Data;local root=p.Character.HumanoidRootPart;root.Anchored=true
 local own=assert(Plot:GetPlot(p));p.Character:PivotTo(own.CFrame+Vector3.new(0,5,0))
 T:Reconcile(p)
 check(d.Currencies.Coins==250 and require(G.Definitions.MeadowTreeDefinitions).Ordered[1].Cost==250,'existing starting balance funds normal first search')
 check(d.TutorialProgress.Step==1 and d.TutorialProgress.FlowVersion==2,'new tutorial uses existing Step')
 check(not T:Complete(p) and not T:Restart(p) and not d.TutorialCompleted,'early complete/restart requests cannot skip objectives')
 check(not T:RevealDone(p,'forged-uid'),'client cannot invent a reward UID')
 local legacy={TutorialProgress={Step=12,Gathered=true},TutorialCompleted=false};T:Normalize(legacy)
 check(legacy.TutorialProgress.Step==1 and legacy.TutorialProgress.LegacyStep==12 and legacy.TutorialProgress.Gathered,'legacy step retained during flow migration')
 local floor=K.GetService('BiomeService'):GetFloor('Meadow');p.Character:PivotTo(floor.CFrame+Vector3.new(0,5,0));T:Reconcile(p)
 check(d.TutorialProgress.Step==2,'actual Meadow position advances travel step')
 local id;for species in pairs(require(G.IndexCatalog).Current())do local def=require(G.Definitions.PetDefinitions)[species];if def.Rarity=='Common' then id=species;break end end
 local a=P:Create(id,'Normal');a.Cosmetic='FlowerCrown';P:Adopt(d,a);P:Discover(d,a);P:Publish(p)
 T:Awarded(p,'Meadow',{Duration=.6,Results={{Pet=a}}})
 check(d.TutorialProgress.Step==2 and d.TutorialProgress.PetUID==a.UID,'committed server reward UID recorded without skipping reveal')
 check(not T:RevealDone(p,a.UID),'reveal cannot finish before authoritative duration')
 task.wait(.7);check(d.TutorialProgress.Step==2,'elapsed time alone does not complete active reveal')
 check(T:RevealDone(p,a.UID) and d.TutorialProgress.Step==3,'matching finished presentation acknowledged after real owned reward')
 check(d.ActiveHeldPetUID=='','Held slot alone does not make tutorial pet active')
 check(P:Equip(p,a.UID,true) and d.ActiveHeldPetUID==a.UID,'existing Equip selects exact tutorial UID')
 d.Currencies.Coins=0
 check(not P:Sell(p,'Held',a.UID) and L.Find(d,a.UID)==a,'sole tutorial pet cannot be sold into unaffordable-search dead end')
 local slot1=assert(Display.GetSlot(p,1));p.Character:PivotTo(CFrame.new(slot1.Surface+Vector3.new(0,3,0)));T:Reconcile(p)
 -- Some authored display tiers lie just beyond floor bounds; enter via existing plot teleport if needed.
 if d.TutorialProgress.Step==3 then Plot:Teleport(p);T:Reconcile(p)end
 check(d.TutorialProgress.Step==4 and d.TutorialProgress.SlotId~=nil,'own plot arrival selects real empty physical slot')
 local selected=d.TutorialProgress.SlotId;local wrong=selected==1 and 2 or 1;local wrongSlot=Display.GetSlot(p,wrong)
 p.Character:PivotTo(CFrame.new(wrongSlot.Surface+Vector3.new(0,3,0)))
 check(P:SwapSanctuary(p,a.LocationSlot,wrong,a.UID,''),'normal placement in another slot still works')
 task.wait();check(d.TutorialProgress.Step==5 and d.TutorialProgress.SlotId==wrong,'another valid slot immediately completes PLACE through canonical profile update')
 for _=1,5 do T:Reconcile(p);check(d.TutorialProgress.Step==5,'placed pet stays on collection objective')end
 check(P:SwapSanctuary(p,0,wrong,'',a.UID),'normal manual pickup remains available')
 task.wait();check(d.TutorialProgress.Step==4 and not L.At(d,'Sanctuary',d.TutorialProgress.SlotId),'manual pickup returns to PLACE with an empty slot')
 selected=d.TutorialProgress.SlotId
 local target=Display.GetSlot(p,selected);p.Character:PivotTo(CFrame.new(target.Surface+Vector3.new(0,3,0)));local stats=fingerprint(a)
 check(P:SwapSanctuary(p,a.LocationSlot,selected,a.UID,''),'place at selected physical slot')
 T:Reconcile(p);check(d.TutorialProgress.Step==5 and a.LocationSlot==selected and fingerprint(a)==stats,'exact selected placement advances without changing stats')
 T:Collected(p,0);check(d.TutorialProgress.Step==5,'zero collection cannot advance tutorial')
 local pad=own:FindFirstChild('IncomeCollector');p.Character:PivotTo(pad.CFrame+Vector3.new(0,4,0));d.UncollectedSanctuaryCoins=5.75
 local got,result=Plot:Collect(p);task.wait(.1)
 check(got and result.Amount>0 and d.TutorialProgress.Step==6,'positive existing collection signal unlocks congratulations')
 local pets=H:JSONEncode(d.Pets);local money=d.Currencies.Coins;local placements=H:JSONEncode(d.PlotProgression)
 check(T:Restart(p) and d.TutorialProgress.Step==1 and not d.TutorialCompleted,'restart resets guidance only')
 check(H:JSONEncode(d.Pets)==pets and d.Currencies.Coins==money and H:JSONEncode(d.PlotProgression)==placements,'restart preserves pets, coins and placements')
 -- Resume saved placement canonically rather than regranting a pet.
 d.TutorialProgress.Step=4;d.TutorialProgress.PetUID=a.UID;d.TutorialProgress.SlotId=wrong
 profile.Data=M.Apply(H:JSONDecode(H:JSONEncode(d)),function()error('UID recreated')end);d=profile.Data;a=L.Find(d,a.UID)
 local character=root.Parent;root.Parent=nil;T:Reconcile(p,true)
 check(d.TutorialProgress.Step==4,'resume waits for the character to be ready')
 root.Parent=character;T:Reconcile(p)
 check(d.TutorialProgress.Step==5 and d.TutorialProgress.SlotId==a.LocationSlot,'resume recovers an already placed exact UID after character readiness')
 d.UncollectedSanctuaryCoins=3;Plot:Collect(p);task.wait(.1)
 check(T:Complete(p) and d.TutorialCompleted and d.TutorialProgress.Step==6,'Complete sets existing completion flag')
 profile:Save();local deadline=os.clock()+12
 repeat task.wait(.2)until profile.LastSavedData.TutorialCompleted or os.clock()>deadline
 local saved=profile.ProfileStore.Mock:GetAsync(profile.Key)
 check(saved and saved.Data.TutorialCompleted and saved.Data.TutorialProgress.Step==6,'existing mock ProfileStore save/readback persists completion')
 profile.Data=M.Apply(copy(saved.Data),function()error('UID recreated on restore')end);d=profile.Data
 T:Reconcile(p,true);check(d.TutorialCompleted and d.TutorialProgress.Step==6,'completed restored profile does not restart')
 -- Held actions reuse the single sale and move transactions.
 d.Currencies.Coins=1000;d.Pets={};d.GardenExpeditions={};d.ActiveHeldPetUID='';P:Publish(p)
 local function pet(location,slot,flag,species)local v=P:Create(species or id,'Normal');L.Set(v,location,slot);if flag then v[flag]=true end;d.Pets[#d.Pets+1]=v;return v end
 local held=pet('Held',1);d.ActiveHeldPetUID=held.UID;local inv=pet('Inventory');P:Publish(p)
 local before=d.Currencies.Coins;local value=require(G.SellValueCalculator).Calculate(held)
 check(P:Sell(p,'Held',held.UID) and d.Currencies.Coins==before+value,'single active Held sale credits exact existing value')
 check(not L.Find(d,held.UID) and d.ActiveHeldPetUID=='' and d.HeldPetSlots[1]=='','Held sale frees slot and clears overhead UID')
 check(L.Find(d,inv.UID)==inv and not P:Sell(p,'Held',held.UID) and d.Currencies.Coins==before+value,'Held replay does not sell other inventory or double-credit')
 local defs=require(G.Definitions.PetDefinitions);local secret,protected
 for species,def in pairs(defs)do if type(def)=='table'then if def.Rarity=='Secret'then secret=species end;if def.Protected then protected=species end end end
 for _,case in ipairs({{'Locked',id},{'Favorite',id},{'Prismatic',id},{false,secret},{false,protected}})do
  local v=pet('Held',1,case[1],case[2]);d.ActiveHeldPetUID=v.UID;P:Publish(p)
  check(not P:Sell(p,'Held',v.UID) and L.Find(d,v.UID)==v,'Held sale respects protection '..tostring(case[1]or case[2]))
  L.Set(v,'Inventory');P:Publish(p)
 end
 local inactive=pet('Held',1);local active=pet('Held',2);d.ActiveHeldPetUID=active.UID;P:Publish(p)
 check(not P:Sell(p,'Held',inactive.UID),'cannot sell a non-active Held UID')
 local fingerprintBefore=fingerprint(active)
 check(P:Move(p,active.UID,'Inventory') and active.Location=='Inventory' and fingerprint(active)==fingerprintBefore and d.HeldPetSlots[2]=='' and d.ActiveHeldPetUID=='','STORE preserves exact record and all stats')
 d.ActiveHeldPetUID=inactive.UID;P:Publish(p);P:Sell(p,'Inventory','')
 check(L.Find(d,inactive.UID)==inactive,'Sell All remains Inventory-only')
 d.Pets={};d.Currencies.Coins=0;d.ActiveHeldPetUID='';d.TutorialCompleted=false
 local tutorialPet=pet('Inventory');pet('Inventory');d.TutorialProgress={Step=3,FlowVersion=2,PetUID=tutorialPet.UID};P:Publish(p)
 check(P:Sell(p,'Inventory','') and #d.Pets==1 and L.Find(d,tutorialPet.UID)==tutorialPet,'Sell All preserves a tutorial companion when selling the whole batch would strand onboarding')
 local seen={}for _,v in ipairs(d.Pets)do check(not seen[v.UID],'no duplicate UID '..v.UID);seen[v.UID]=true end
end,debug.traceback)
profile.Data=original;P:Publish(p);for key in pairs(original)do D:Publish(p,key)end
if p.Character and p.Character:FindFirstChild('HumanoidRootPart')then p.Character.HumanoidRootPart.Anchored=false;p.Character:PivotTo(originalCF)end
workspace:SetAttribute('AKTutorialBackendResults',H:JSONEncode({Passed=ok,Checks=checks,Error=not ok and err or nil}))
if not ok then warn(err)end
