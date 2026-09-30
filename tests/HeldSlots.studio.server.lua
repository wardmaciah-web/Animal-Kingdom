-- Temporary Studio mock-only acceptance harness; not mapped into the game.
local K=require(game.ReplicatedStorage.Packages.Knit)
K.OnStart():await()
local RS=game.ReplicatedStorage
local Http=game.HttpService
local profiles=K.GetService('ProfileService')
local pets=K.GetService('PetService')
local resource=K.GetService('ResourceService')
local locations=require(RS.Shared.Gameplay.PetLocations)
local migrations=require(RS.Shared.Gameplay.ProfileMigrations)
local display=require(game.ServerScriptService.ServerSource.Utilities.MeadowSanctuaryDisplay)
local geometry=require(RS.Shared.Gameplay.PetVisualGeometry)
local definitions=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local p=game.Players:GetPlayers()[1]
local profile=assert(profiles.Profiles[p]);assert(profile.is_mock==true,'Never test on live player data')
local original=profile.Data
local originalPivot=p.Character:GetPivot()
local fixture,treeRecords={},{}
local report={Checks={},TreeRewards={}}
local function check(ok,name)assert(ok,name);table.insert(report.Checks,name)end
local function copy(v)if type(v)~='table' then return v end;local out={};for k,x in pairs(v)do out[k]=copy(x)end;return out end
local function data()return profiles.Profiles[p].Data end
local function invariant()
 local d=data();local ids,slots={},{}
 for _,pet in ipairs(d.Pets)do
  check(not ids[pet.UID],'Unique UID '..pet.UID);ids[pet.UID]=true
  check(pet.Location=='Held' or pet.Location=='Inventory' or pet.Location=='Sanctuary','One logical location '..pet.UID)
  if pet.Location~='Inventory' then
   local key=pet.Location..pet.LocationSlot;check(not slots[key],'Exclusive slot '..key);slots[key]=true
  end
 end
 local active=locations.Find(d,d.ActiveHeldPetUID)
 check(d.ActiveHeldPetUID=='' or active and active.Location=='Held','Active pet belongs to Held slot')
 return true
end
local function snapshot()
 local d=data()
 return {Pets=copy(d.Pets),Held=copy(d.HeldPetSlots),Sanctuary=copy(d.SanctuaryPetSlots),Active=d.ActiveHeldPetUID,Coins=d.Currencies.Coins,Visual=Http:JSONDecode(p:GetAttribute('EquippedPetData') or '[]'),Checks=#report.Checks}
end
local b=Instance.new('BindableFunction');b.Name='AKHeldQAServer';b.Parent=game.ServerStorage
b.OnInvoke=function(action,arg)
 local ok,result=xpcall(function()
  if action=='Setup' then
   local d=copy(require(RS.SharedSource.Datas.ProfileTemplate));migrations.Apply(d,function()return Http:GenerateGUID(false)end)
   d.Currencies.Coins=100000;d.ForestCoins=d.Currencies.Coins;d.TutorialCompleted=true;d.SanctuaryIncomeUpdatedAt=workspace:GetServerTimeNow()
   profile.Data=d;profiles.Client.GetData:Fire(p,d);pets:Publish(p)
   check(#d.Pets==0 and #d.HeldPetSlots==5,'Start with five empty Held slots')
   return snapshot()
  elseif action=='Tree' then
   local candidates={}
   for object,r in pairs(resource:GetRecords())do
    if r.IsTree and r.Biome=='Meadow' and r.State=='AVAILABLE' and object:GetAttribute('TreeTier')==1 then table.insert(candidates,r)end
   end
   table.sort(candidates,function(a,b)return a.InteractionPosition.X<b.InteractionPosition.X end)
   local r=assert(candidates[1],'Available Meadow tree');treeRecords[arg]=r
   p.Character:PivotTo(CFrame.new(r.InteractionPosition+Vector3.new(0,3,7)))
   return {Prompt=r.Prompt:GetFullName(),Position=tostring(r.InteractionPosition),Before=#data().Pets}
  elseif action=='Reward' then
   local d=data();local r=assert(treeRecords[arg]);local pet=locations.At(d,'Held',arg)
   check(r.Awarded and pet~=nil,'Meadow reward in Held slot '..arg)
   local shown=r.HatchResult.Results[1].Pet
   check(shown.UID==pet.UID and shown.Weight==pet.Weight,'Reveal references awarded owned pet '..arg)
   fixture[arg]=pet.UID
   report.TreeRewards[arg]={UID=pet.UID,Weight=pet.Weight,PetId=pet.PetId}
   local saved=profiles.Profiles[p].LastSavedData
   check(saved and locations.Find(saved,pet.UID)~=nil,'Reward checkpoint saved before reveal finishes '..arg)
   return snapshot()
  elseif action=='NearSlot' then
   local slot=assert(display.GetSlot(p,arg))
   p.Character:PivotTo(CFrame.new(slot.Surface+Vector3.new(0,3,0)))
   return {Slot=arg,Surface=tostring(slot.Surface)}
  elseif action=='Placed' then
   local d=data();check(locations.At(d,'Sanctuary',arg).UID==fixture[1],'PLACE uses exact first pet and requested slot')
   check(d.HeldPetSlots[1]=='' and d.ActiveHeldPetUID=='','PLACE clears Held slot and active model')
   local model=workspace.Sanctuaries[tostring(p.UserId)].DisplayedPets:FindFirstChild(fixture[1])
   check(model~=nil and model:GetAttribute('Weight')==locations.Find(d,fixture[1]).Weight,'PLACE renders real model with saved weight')
   invariant();return snapshot()
  elseif action=='Swapped' then
   local d=data();check(locations.At(d,'Sanctuary',arg).UID==fixture[2],'SWAP places incoming pet in same physical slot')
   check(d.HeldPetSlots[2]==fixture[1] and d.ActiveHeldPetUID==fixture[1],'SWAP returns previous pet to incoming Held slot and selects it')
   for i=1,2 do check(locations.Find(d,fixture[i]).Weight==report.TreeRewards[i].Weight,'SWAP preserves weight '..i)end
   check(not pets:SwapSanctuary(p,2,arg,fixture[2],fixture[1]),'Replayed swap rejected')
   check(not pets:Equip(p,'foreign-uid',true),'Foreign pet UID rejected')
   check(not pets:SwapSanctuary(p,0,arg,fixture[1],fixture[2]),'Invalid Held slot rejected')
   invariant();return snapshot()
  elseif action=='Persist' then
   local expected=copy(data())
   local current=profiles.Profiles[p];local saved=false
   local connection=current.OnAfterSave:Connect(function()saved=true end)
   current:Save();local deadline=os.clock()+15;repeat task.wait(.1)until saved or os.clock()>deadline
   connection:Disconnect();check(saved,'Existing profile checkpoint completed')
   profiles.Profiles[p]=nil;current:EndSession()
   deadline=os.clock()+15;repeat task.wait(.1)until not current:IsActive() or os.clock()>deadline
   local restored=assert(current.ProfileStore.Mock:StartSessionAsync(current.Key))
   restored:Reconcile();migrations.Apply(restored.Data,function()error('Existing UID must persist')end)
   profiles.Profiles[p]=restored;profile=restored
   for _,pet in ipairs(expected.Pets)do
    local after=assert(locations.Find(restored.Data,pet.UID))
    for _,key in ipairs({'UID','UniquePetId','PetId','Weight','Level','XP','Mutation','Shiny','Prismatic','Location','LocationSlot','Cosmetic'})do
     check(after[key]==pet[key],'Session reload preserves '..key..' '..pet.UID)
    end
   end
   check(restored.Data.ActiveHeldPetUID==expected.ActiveHeldPetUID,'Session reload restores active held selection')
   for i=1,5 do check(restored.Data.HeldPetSlots[i]==expected.HeldPetSlots[i],'Session reload restores Held slot '..i)end
   for i,uid in ipairs(expected.SanctuaryPetSlots)do check(restored.Data.SanctuaryPetSlots[i]==uid,'Session reload restores Sanctuary slot '..i)end
   profiles.Loaded:Fire(p,restored.Data);profiles.Client.GetData:Fire(p,restored.Data);pets:Publish(p)
   report.Persistence={Store=current.ProfileStore.Name,MockOnly=true,ReleasedAndReacquiredSameKey=true,Owned=#restored.Data.Pets}
   return snapshot()
  elseif action=='Edges' then
   local d=data();local active=d.ActiveHeldPetUID;local held=locations.Find(d,active)
   local far=p.Character:GetPivot();p.Character:PivotTo(CFrame.new(0,500,0))
   check(not pets:SwapSanctuary(p,held.LocationSlot,1,active,''),'Remote Sanctuary action rejected out of range')
   p.Character:PivotTo(far)
   for i=1,6 do check(pets:Grant(p,'MeadowFieldMouse','Normal')~=nil,'Fixture grant '..i)end
   local inventory
   for _,pet in ipairs(d.Pets)do if pet.Location=='Inventory' then inventory=pet;break end end
   local before=Http:JSONEncode(d.HeldPetSlots)
   check(inventory~=nil and not pets:Equip(p,inventory.UID,true),'Full Held slots reject another inventory pet')
   check(Http:JSONEncode(d.HeldPetSlots)==before and locations.Find(d,inventory.UID)==inventory,'Full slots preserve both assignments and ownership')
   local freed=locations.At(d,'Held',5);check(pets:Move(p,freed.UID,'Inventory'),'Create available Held slot')
   invariant();return {InventoryUID=inventory.UID,FreeSlot=5,Snapshot=snapshot()}
  elseif action=='SellScope' then
   local d=data();local active=d.ActiveHeldPetUID;local shown=copy(d.DisplayedPetIds)
   local total,count=0,0
   for _,pet in ipairs(d.Pets)do if pet.Location=='Inventory' then total+=require(RS.Shared.Gameplay.SellValueCalculator).Calculate(pet);count+=1 end end
   report.SaleExpected={Active=active,Sanctuary=shown,Total=total,Count=count,Before=d.Currencies.Coins}
   return report.SaleExpected
  elseif action=='SoldAll' then
   local d=data();local e=report.SaleExpected
   check(locations.Count(d,'Inventory')==0,'SELL ALL removes normal inventory')
   check(locations.Find(d,e.Active)~=nil and d.ActiveHeldPetUID==e.Active,'SELL ALL preserves active held pet')
   for _,uid in ipairs(e.Sanctuary)do check(locations.Find(d,uid).Location=='Sanctuary','SELL ALL preserves Sanctuary pet')end
   check(d.Currencies.Coins==e.Before+e.Total,'SELL ALL credits exact existing server sell value')
   report.HeldSale={UID=e.Active,Value=require(RS.Shared.Gameplay.SellValueCalculator).Calculate(locations.Find(d,e.Active)),Before=d.Currencies.Coins}
   invariant();return snapshot()
  elseif action=='SoldHeld' then
   local d=data();local e=report.HeldSale
   check(locations.Find(d,e.UID)==nil and d.ActiveHeldPetUID=='','SELL HELD removes owned UID and active selection')
   check(not table.find(d.HeldPetSlots,e.UID),'SELL HELD clears HUD assignment')
   check(d.Currencies.Coins==e.Before+e.Value,'SELL HELD credits exact server value')
   check(not pets:Sell(p,'Held',e.UID),'Repeated held sale cannot pay twice')
   invariant();return snapshot()
  elseif action=='Inspect' then return snapshot()
  elseif action=='Report' then return report
  elseif action=='Restore' then
   profiles.Profiles[p].Data=original;profiles.Client.GetData:Fire(p,original);pets:Publish(p)
   p.Character:PivotTo(originalPivot);return {RestoredOriginalMockProfile=true,Checks=#report.Checks}
  end
  error('Unknown QA action')
 end,debug.traceback)
 return {Success=ok,Result=result}
end
script.Destroying:Connect(function()b:Destroy()end)
