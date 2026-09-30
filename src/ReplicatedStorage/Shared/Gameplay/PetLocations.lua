-- Pet.Location/LocationSlot are canonical. The UID arrays are compatibility indexes,
-- rebuilt from those same owned records, never a second inventory.
local M={HeldSlots=5,MaxSanctuarySlots=70,Version=1}
function M.Find(data,uid)
 for _,pet in ipairs(data.Pets or {})do if pet.UID==uid then return pet end end
end
function M.At(data,location,slot)
 for _,pet in ipairs(data.Pets or {})do if pet.Location==location and pet.LocationSlot==slot then return pet end end
end
function M.FirstFree(data,location,capacity)
 local used={};for _,pet in ipairs(data.Pets or {})do if pet.Location==location then used[pet.LocationSlot or 0]=true end end
 for i=1,capacity do if not used[i]then return i end end
end
function M.Count(data,location)
 local n=0;for _,pet in ipairs(data.Pets or {})do if pet.Location==location then n+=1 end end;return n
end
function M.InventorySpace(data,count)
 -- Each active Garden trip reserves its return space, so claiming never strands a pet.
 return M.Count(data,'Inventory')+M.Count(data,'Garden')+(count or 1)<=data.PetStorageCapacity
end
function M.Set(pet,location,slot)pet.Location=location;pet.LocationSlot=slot end
function M.Rebuild(data)
 local held=table.create(M.HeldSlots,'');local sanctuary=table.create(M.MaxSanctuarySlots,'')
 for _,pet in ipairs(data.Pets or {})do
  local slots=pet.Location=='Held' and held or pet.Location=='Sanctuary' and sanctuary
  if slots then
   local slot=pet.LocationSlot
   if type(slot)=='number' and slot%1==0 and slot>=1 and slot<=#slots and slots[slot]=='' then slots[slot]=pet.UID
   else M.Set(pet,'Inventory') end -- Repair only the assignment; keep the exact owned record.
  end
 end
 data.HeldPetSlots=held;data.SanctuaryPetSlots=sanctuary;data.EquippedPets={};data.DisplayedPetIds={}
 for _,uid in ipairs(held)do if uid~=''then table.insert(data.EquippedPets,uid)end end
 for _,uid in ipairs(sanctuary)do if uid~=''then table.insert(data.DisplayedPetIds,uid)end end
 local active=M.Find(data,data.ActiveHeldPetUID)
 if not active or active.Location~='Held' then data.ActiveHeldPetUID='' end
 data.MaxEquippedPets=M.HeldSlots;data.OwnedPets=data.Pets
end
-- Run only after the actual assigned display anchors are resolved. Never infer zero capacity while loading.
function M.ReconcileSanctuary(data,validSlots)
 if next(validSlots)==nil then return false end
 local occupied,repairs={},{}
 for _,pet in ipairs(data.Pets or {})do
  if pet.Location=='Sanctuary' and validSlots[pet.LocationSlot] and not occupied[pet.LocationSlot] then occupied[pet.LocationSlot]=pet.UID end
 end
 for _,pet in ipairs(data.Pets or {})do
  if pet.Location=='Sanctuary' and (not validSlots[pet.LocationSlot] or occupied[pet.LocationSlot]~=pet.UID) then
   local old=pet.LocationSlot;local free
   for i=1,M.MaxSanctuarySlots do if validSlots[i] and not occupied[i] then free=i;break end end
   M.Set(pet,free and 'Sanctuary' or 'Inventory',free)
   if free then occupied[free]=pet.UID end
   table.insert(repairs,{UID=pet.UID,PreviousSlot=old,Location=pet.Location,Slot=free,Reason='PhysicalSlotUnavailable'})
  end
 end
 if #repairs==0 then return false end
 data.RecoveryData=data.RecoveryData or {};data.RecoveryData.SanctuarySlotRepairs=data.RecoveryData.SanctuarySlotRepairs or {}
 for _,repair in ipairs(repairs)do table.insert(data.RecoveryData.SanctuarySlotRepairs,repair)end
 data.PetStorageCapacity=math.max(data.PetStorageCapacity,M.Count(data,'Inventory')+M.Count(data,'Garden'))
 M.Rebuild(data);return true
end
function M.Migrate(data)
 if (data.PetDataVersion or 0)>M.Version then error('Pet profile version is newer than this server')end
 if (data.PetDataVersion or 0)>=M.Version then M.Rebuild(data);return end
 local Definitions=require(script.Parent.Definitions.PetDefinitions)
 local Weight=require(script.Parent.PetWeight)
 local held=table.clone(data.EquippedPets or {});local displayed=table.clone(data.DisplayedPetIds or {})
 local oldEquipped=data.MaxEquippedPets
 for _,pet in ipairs(data.Pets)do
  pet.Weight=Weight.Normalize(pet.Weight,Definitions[pet.PetId])
  pet.AcquiredAt=type(pet.AcquiredAt)=='number' and pet.AcquiredAt==pet.AcquiredAt and math.abs(pet.AcquiredAt)<math.huge and pet.AcquiredAt or 0
  M.Set(pet,'Inventory')
 end
 -- Preserve active trips first, then Sanctuary slot order, then carried companions.
 -- The old system allowed overlap; one UID cannot occupy two locations afterward.
 for _,trip in ipairs(data.GardenExpeditions or {})do
  local pet=M.Find(data,trip.UID);if pet then M.Set(pet,'Garden',trip.SlotId)end
 end
 for slot,uid in ipairs(displayed)do
  local pet=M.Find(data,uid);if pet and pet.Location=='Inventory' then M.Set(pet,'Sanctuary',slot)end
 end
 for _,uid in ipairs(held)do
  local pet=M.Find(data,uid);local slot=M.FirstFree(data,'Held',M.HeldSlots)
  if pet and slot and pet.Location=='Inventory' then M.Set(pet,'Held',slot)end
 end
 data.RecoveryData.PetLocationMigration={PreviousEquippedLimit=oldEquipped,PreviousEquippedPets=held,PreviousDisplayedPetIds=displayed}
 data.PetStorageCapacity=math.max(data.PetStorageCapacity,M.Count(data,'Inventory')+M.Count(data,'Garden'))
 data.PetDataVersion=M.Version;M.Rebuild(data)
end
return M
