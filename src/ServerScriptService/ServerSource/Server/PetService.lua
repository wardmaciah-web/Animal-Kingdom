local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Knit=require(RS.Packages.Knit)
local Signal=require(RS.Packages.Signal)
local Definitions=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Variants=require(RS.Shared.Gameplay.Definitions.VariantDefinitions)
local PetMath=require(RS.Shared.Gameplay.PetMath)
local Locations=require(RS.Shared.Gameplay.PetLocations)
local Weight=require(RS.Shared.Gameplay.PetWeight)
local Stats=require(RS.Shared.Gameplay.PetStats)
local SellValue=require(RS.Shared.Gameplay.SellValueCalculator)
local CurrencyDefs=require(RS.Shared.Gameplay.Definitions.CurrencyDefinitions)
local rng=Random.new()
local Guard=require(script.Parent.Parent.Utilities.GameplayGuard)
local Pets=Knit.CreateService({Name="PetService",Client={},Granted=Signal.new(),Equipped=Signal.new()})
local Data
local confirmations=setmetatable({},{__mode="k"})
local locks=setmetatable({},{__mode="k"})
local saveRequests=setmetatable({},{__mode="k"})
-- Request a checkpoint through the existing profile; rapid selections coalesce.
function Pets:RequestSave(player)
 local state=saveRequests[player] or {At=-math.huge};saveRequests[player]=state
 if state.Queued then return end
 state.Queued=true
 task.delay(math.max(0,3-(os.clock()-state.At)),function()
  state.Queued=false;state.At=os.clock()
  local profile=Knit.GetService("ProfileService").Profiles[player]
  if profile and profile:IsActive() then profile:Save() end
 end)
end
function Pets:Transaction(player,callback)
 if locks[player] then return false,"Another pet action is in progress. Please try again." end
 if not Data:Get(player) then return false,"Your pets are still loading." end
 locks[player]=true
 local ok,accepted,result=xpcall(callback,debug.traceback)
 locks[player]=nil
 if not ok then warn('[PetTransaction] '..tostring(accepted));return false,"Pet action unavailable. Your saved pets are safe." end
 return accepted,result
end
function Pets:RefreshStats(pet)
 pet.CoinsPerSecond=Stats.Income(pet);pet.SellValue=SellValue.Calculate(pet)
 pet.WeightQuality=Weight.Quality(pet,Definitions[pet.PetId])
end
function Pets:Adopt(data,pet)
 local slot=Locations.FirstFree(data,'Held',Locations.HeldSlots)
 Locations.Set(pet,slot and 'Held' or 'Inventory',slot)
 self:RefreshStats(pet);table.insert(data.Pets,pet)
 return pet.Location
end
function Pets:FindOwned(data,uid)
 if not Guard.Id(uid) then return nil end
 for i,pet in ipairs(data.Pets) do if pet.UID==uid then return pet,i end end
 return nil
end
function Pets:HasSpace(player,count)
 local data=Data:Get(player)
 return data~=nil and Locations.HeldSlots-Locations.Count(data,"Held")+math.max(0,data.PetStorageCapacity-Locations.Count(data,"Inventory")-Locations.Count(data,"Garden"))>=count
end
function Pets:Discover(data,pet)
 local entry=data.PetIndex[pet.PetId];local first=type(entry)~="table"
 if first then entry={Count=0,Variants={}};data.PetIndex[pet.PetId]=entry end
 entry.Count+=1;entry.Variants[pet.Mutation]=true
 if pet.Shiny then entry.Variants.Shiny=true end
 if pet.Prismatic then entry.Variants.Prismatic=true end
 return first
end
function Pets:Create(petId,mutation,shiny,prismatic,luck,weightBias)
 local def=Definitions[petId]
 if not def or not Variants.Mutations[mutation or "Normal"] then return nil end
 local uid=Http:GenerateGUID(false)
 return {UID=uid,UniquePetId=uid,PetId=petId,Weight=Weight.Roll(def,rng,luck,weightBias),Location="Inventory",Level=1,XP=0,Mutation=mutation or "Normal",Shiny=shiny==true,
  Prismatic=prismatic==true or def.Prismatic==true,Favorite=false,Locked=false,AcquiredAt=os.time()}
end
-- Single committed-pet progression boundary, called only after canonical adoption/discovery.
-- The saved marker makes a replay harmless; movement/publication never calls this.
function Pets:RecordAward(player,pet,result,context)
 if pet.AwardProgressApplied then return false end
 local data=Data:Get(player);assert(data and self:FindOwned(data,pet.UID)==pet,"Award must be owned before progression")
 result.WeightRecord=require(RS.Shared.Gameplay.SpeciesRecords).Record(data,pet)
 pet.AwardProgressApplied=true
 Knit.GetService("ProgressionService"):OnPetCommitted(player,pet,result,context or {})
 Data:Publish(player,"WeightRecords")
 return true
end
function Pets:Grant(player,petId,mutation,shiny,prismatic)
 local granted
 self:Transaction(player,function()
  if not self:HasSpace(player,1) then return false,"PET STORAGE FULL" end
  local pet=self:Create(petId,mutation,shiny,prismatic);if not pet then return false,"Pet unavailable" end
  local data=Data:Get(player);self:Adopt(data,pet)
  local first=self:Discover(data,pet);self:RecordAward(player,pet,{NewDiscovery=first},{Source="Grant"});self:Publish(player)
  granted=pet;self.Granted:Fire(player,pet,first);return true
 end)
 return granted
end
function Pets:Publish(player)
 local data=Data:Get(player);if not data then return end
 Locations.Rebuild(data)
 for _,entry in pairs(data.PetIndex)do entry.OwnedCount=0 end
 for _,pet in ipairs(data.Pets)do
  self:RefreshStats(pet)
  local entry=data.PetIndex[pet.PetId];if entry then entry.OwnedCount=(entry.OwnedCount or 0)+1 end
 end
 data.SanctuaryIncomePerSecond=Knit.GetService('SanctuaryService'):GetIncome(data)
 data.SanctuaryCapacity=math.min(Locations.MaxSanctuarySlots,require(script.Parent.Parent.Utilities.SanctuarySlotLayout).Count(Knit.GetService('PlotService'):GetPlot(player)))
 Data:Publish(player,"Pets","PetIndex","ActiveHeldPetUID","HeldPetSlots","SanctuaryPetSlots","DisplayedPetIds","MaxEquippedPets","SanctuaryIncomePerSecond","SanctuaryCapacity")
 self:PublishEquipped(player)
 self:RequestSave(player)
end
function Pets:PublishEquipped(player)
 local data=Data:Get(player);if not data then return end
 Data:Publish(player,"EquippedPets")
 local equipped={}
 for _,uid in ipairs(data.EquippedPets) do
  local pet=self:FindOwned(data,uid)
   if pet and pet.UID==data.ActiveHeldPetUID and pet.Location=="Held" and Definitions[pet.PetId] then table.insert(equipped,{UID=uid,PetId=pet.PetId,Level=pet.Level,Mutation=pet.Mutation,Shiny=pet.Shiny,Prismatic=pet.Prismatic,Cosmetic=pet.Cosmetic,Weight=pet.Weight,CoinsPerSecond=pet.CoinsPerSecond,LocationSlot=pet.LocationSlot}) end
 end
 player:SetAttribute("ActiveHeldPetUID",data.ActiveHeldPetUID)
 player:SetAttribute("EquippedPetData",Http:JSONEncode(equipped))
end
function Pets:Move(player,uid,location)
 if location=='Held' then return self:Equip(player,uid,true) end
 return self:Transaction(player,function()
  local data=Data:Get(player);local pet=self:FindOwned(data,uid)
  if not pet then return false,"Pet unavailable" end
  if location~='Inventory' or pet.Location=='Sanctuary' then return false,"Walk to a Sanctuary slot while holding a pet to place or swap." end
  if pet.Location=='Garden' then return false,"Recall or claim this pet from Garden first." end
  if pet.Location~='Held' then return false,"Only Held pets can be stored." end
  if not Locations.InventorySpace(data) then return false,"PET STORAGE FULL" end
  Locations.Set(pet,'Inventory');if data.ActiveHeldPetUID==uid then data.ActiveHeldPetUID='' end
  self:Publish(player);return true
 end)
end
function Pets:Equip(player,uid,equip)
 if not equip then return self:Move(player,uid,'Inventory') end
 return self:Transaction(player,function()
  local data=Data:Get(player);local pet=self:FindOwned(data,uid)
  if not pet then return false,"Pet unavailable" end
  if pet.Location~='Held' and pet.Location~='Inventory' then return false,"Only Held or Inventory pets can be held." end
  if not Definitions[pet.PetId] or not require(RS.Shared.Gameplay.PetModelResolver).Resolve(pet.PetId) then return false,"This companion's model is temporarily unavailable." end
  if pet.Location=='Inventory' then
   local slot=Locations.FirstFree(data,'Held',Locations.HeldSlots)
   if not slot then return false,"All five Held slots are occupied." end
   Locations.Set(pet,'Held',slot)
  end
  data.ActiveHeldPetUID=pet.UID
  self:Publish(player);self.Equipped:Fire(player,uid);return true
 end)
end
function Pets:SwapSanctuary(player,heldSlot,sanctuarySlot,expectedHeld,expectedSanctuary)
 return self:Transaction(player,function()
  local data=Data:Get(player)
  if not Guard.Finite(heldSlot) or heldSlot%1~=0 or heldSlot<0 or heldSlot>Locations.HeldSlots
   or not Guard.Finite(sanctuarySlot) or sanctuarySlot%1~=0 or sanctuarySlot<1 or sanctuarySlot>Locations.MaxSanctuarySlots then return false,"Invalid display slot" end
  local slot=require(script.Parent.Parent.Utilities.MeadowSanctuaryDisplay).GetSlot(player,sanctuarySlot)
  local root=Guard.Alive(player)
  if not slot or not root or (root.Position-slot.Surface).Magnitude>10 then return false,"Walk closer to that slot in your own Sanctuary." end
  local held=Locations.At(data,'Held',heldSlot);local displayed=Locations.At(data,'Sanctuary',sanctuarySlot)
  if heldSlot==0 then
   if data.ActiveHeldPetUID~='' or expectedHeld~='' or not displayed or displayed.UID~=expectedSanctuary then return false,"Those pets changed. Try again." end
   local free=Locations.FirstFree(data,'Held',Locations.HeldSlots)
   if not free then return false,"Held slots full" end
   if not Definitions[displayed.PetId] or not require(RS.Shared.Gameplay.PetModelResolver).Resolve(displayed.PetId) then return false,"This companion's model is temporarily unavailable." end
   Knit.GetService('SanctuaryService'):Accrue(player)
   Locations.Set(displayed,'Held',free);data.ActiveHeldPetUID=displayed.UID
   self:Publish(player);self.Equipped:Fire(player,displayed.UID);return true
  end
  if not held or held.UID~=data.ActiveHeldPetUID then return false,"Hold a pet first." end
  -- Client UIDs only guard stale/replayed clicks. Ownership, active pet and distance are server-owned.
  if held.UID~=expectedHeld or (displayed and displayed.UID or '')~=expectedSanctuary then return false,"Those pets changed. Try again." end
  for _,pet in ipairs(displayed and {held,displayed} or {held})do
   if not Definitions[pet.PetId] or not require(RS.Shared.Gameplay.PetModelResolver).Resolve(pet.PetId) then return false,"This companion's model is temporarily unavailable." end
  end
  Knit.GetService('SanctuaryService'):Accrue(player)
  Locations.Set(held,'Sanctuary',sanctuarySlot)
  if displayed then Locations.Set(displayed,'Held',heldSlot) end
  data.ActiveHeldPetUID=displayed and displayed.UID or ''
  self:Publish(player)
  Knit.GetService('ChallengeService'):Committed(player,'Place',Http:GenerateGUID(false),{UID=held.UID,PetId=held.PetId,Biome=Definitions[held.PetId].Biome})
  return true
 end)
end
function Pets:ReconcileSanctuary(player,slots)
 return self:Transaction(player,function()
  local data=Data:Get(player)
  local needsRepair=false
  for _,pet in ipairs(data.Pets)do if pet.Location=='Sanctuary' and not slots[pet.LocationSlot] then needsRepair=true;break end end
  if not needsRepair or next(slots)==nil then return true end
  Knit.GetService('SanctuaryService'):Accrue(player)
  if Locations.ReconcileSanctuary(data,slots) then
   Data:Publish(player,'RecoveryData','PetStorageCapacity');self:Publish(player)
  end
  return true
 end)
end
function Pets:Sell(player,mode,expectedUID)
 return self:Transaction(player,function()
  local data=Data:Get(player)
  local heldSale=mode=='Held'
  if mode~='Inventory' and not heldSale then return false,'Invalid sale mode.' end
  if heldSale then
   local held=self:FindOwned(data,expectedUID)
   if not held or held.Location~='Held' or data.ActiveHeldPetUID~=held.UID then return false,'Select that Held pet first.' end
   if SellValue.OnboardingProtected(data,held) then return false,'Keep this companion until you finish the tutorial, or earn enough coins for another search.' end
   if not SellValue.Eligible(held,'Held',data) then return false,'This pet is locked or protected and cannot be sold.' end
  elseif expectedUID~='' then return false,'Sell All uses your eligible Inventory pets.' end
  local sold,total,count={},0,0
  for _,pet in ipairs(data.Pets)do
   local eligible=heldSale and pet.UID==expectedUID and SellValue.Eligible(pet,'Held',data)
    or not heldSale and SellValue.Eligible(pet,'Inventory',data) and pet.UID~=data.ActiveHeldPetUID
   if eligible and Definitions[pet.PetId] then
    local garden=false;for _,trip in ipairs(data.GardenExpeditions or {})do if trip.UID==pet.UID then garden=true;break end end
    if not garden then sold[pet.UID]=true;total+=SellValue.Calculate(pet);count+=1 end
   end
  end
  local companion=data.TutorialProgress and self:FindOwned(data,data.TutorialProgress.PetUID)
  if companion and sold[companion.UID] and SellValue.OnboardingProtected(data,companion,#data.Pets-count,total) then
   sold[companion.UID]=nil;total-=SellValue.Calculate(companion);count-=1
  end
  if count==0 then return false,'No eligible Inventory pets to sell. Locked and protected pets are kept.' end
  if data.Currencies.Coins+total>CurrencyDefs.Coins.MaxBalance then return false,'Your coin balance is full.' end
  local remaining={};for _,pet in ipairs(data.Pets)do if not sold[pet.UID] then table.insert(remaining,pet) end end
  -- Commit ownership and the existing coin balance together, without yielding.
  data.Pets=remaining;data.OwnedPets=remaining;data.Currencies.Coins+=total;data.ForestCoins=data.Currencies.Coins
  self:Publish(player)
  local economy=Knit.GetService('EconomyService');economy:Publish(player,'Coins');economy.Changed:Fire(player,'Coins',total,'PetSale')
  return true,{Kind='PetsSold',Count=count,Total=total,Mode=mode,UID=heldSale and expectedUID or nil}
 end)
end
function Pets:Flag(player,uid,flag,value)
 return self:Transaction(player,function()
  local data=Data:Get(player);local pet,index=self:FindOwned(data,uid)
  if not pet or (flag~="Favorite" and flag~="Locked") or type(value)~="boolean" then return false,"Invalid pet" end
  pet[flag]=value
  Data:PublishPath(player,{"Pets",index});self:RequestSave(player);return true
 end)
end
function Pets:RequestDelete(player,uid)
 local data=Data:Get(player);local pet=data and self:FindOwned(data,uid)
 if not pet or pet.Location~="Inventory" or PetMath.Protected(pet) then return false,"Only unprotected Inventory pets can be released" end
 for _,trip in ipairs(data.GardenExpeditions or {}) do if trip.UID==uid then return false,"Recall this pet from Garden before deleting it." end end
 local token=Http:GenerateGUID(false);confirmations[player]={UID=uid,Token=token,Expires=os.clock()+15}
 return true,{Kind="DeleteConfirmation",UID=uid,Token=token}
end
function Pets:Delete(player,uid,token)
 local pending=confirmations[player];confirmations[player]=nil
 if not pending or pending.UID~=uid or pending.Token~=token or os.clock()>pending.Expires then return false,"Confirmation expired" end
 local data=Data:Get(player);local pet,index=data and self:FindOwned(data,uid)
 -- Do not use a boolean expression for multiple return values.
 if data then pet,index=self:FindOwned(data,uid) end
 if not pet or pet.Location~="Inventory" or PetMath.Protected(pet) then return false,"Only unprotected Inventory pets can be released" end
 for _,trip in ipairs(data.GardenExpeditions or {}) do if trip.UID==uid then return false,"Recall this pet from Garden before deleting it." end end
 local equipped=table.find(data.EquippedPets,uid);if equipped then table.remove(data.EquippedPets,equipped) end
 local displayed=table.find(data.DisplayedPetIds,uid);if displayed then table.remove(data.DisplayedPetIds,displayed) end
 table.remove(data.Pets,index);self:Publish(player);Data:Publish(player,"DisplayedPetIds");return true
end
function Pets:GetGatheringPower(player)
 local data=Data:Get(player);if not data then return 0 end
 local total=0
 for _,uid in ipairs(data.EquippedPets) do local pet=self:FindOwned(data,uid);if pet then total+=PetMath.Power(pet) end end
 return total*Knit.GetService("ModifierService"):Get(player,"GatheringPower")
end
function Pets:AddEquippedXP(player,amount)
 local data=Data:Get(player);if not data then return end
 amount=math.floor(amount*Knit.GetService("ModifierService"):Get(player,"PetXP"))
 local changedLevel=false
 for _,uid in ipairs(data.EquippedPets) do
  local pet,index=self:FindOwned(data,uid)
  if pet and pet.Level<Variants.MaxLevel then
   local previousLevel=pet.Level
   pet.XP+=amount
   while pet.Level<Variants.MaxLevel and pet.XP>=PetMath.RequiredXP(pet.Level) do pet.XP-=PetMath.RequiredXP(pet.Level);pet.Level+=1 end
   if pet.Level==Variants.MaxLevel then pet.XP=0 end
   changedLevel=changedLevel or pet.Level~=previousLevel
   self:RefreshStats(pet)
   -- XP updates scale with equipped slots, not storage size.
   Data:PublishPath(player,{"Pets",index})
  end
 end
 if changedLevel then self:PublishEquipped(player) end
end
function Pets:KnitInit() Data=Knit.GetService("PlayerDataService") end
function Pets:KnitStart()
 local profiles=Knit.GetService("ProfileService")
 profiles.Loaded:Connect(function(player) self:Publish(player) end)
 for player in pairs(profiles.Profiles) do self:Publish(player) end
end
return Pets
