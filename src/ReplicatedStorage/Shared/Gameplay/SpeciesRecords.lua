-- Species history only; never another owned-pet collection.
local M={}
local function valid(n)return type(n)=="number" and n==n and n>0 and n<math.huge end
function M.Seed(data)
 data.WeightRecords=type(data.WeightRecords)=="table" and data.WeightRecords or {}
 for id,value in pairs(data.WeightRecords)do
  if type(id)~="string" or not valid(value)then
   data.RecoveryData=data.RecoveryData or {};data.RecoveryData.InvalidWeightRecords=data.RecoveryData.InvalidWeightRecords or {}
   data.RecoveryData.InvalidWeightRecords[tostring(id)]=tostring(value);data.WeightRecords[id]=nil
  end
 end
 for _,pet in ipairs(data.Pets or {})do
  local best=data.WeightRecords[pet.PetId]
  if valid(pet.Weight) and (not valid(best) or pet.Weight>best)then data.WeightRecords[pet.PetId]=pet.Weight end
  -- Existing ownership is not a new award on load.
  pet.AwardProgressApplied=true
 end
end
function M.Record(data,pet)
 if not valid(pet.Weight)then return nil end
 data.WeightRecords=data.WeightRecords or {}
 local previous=data.WeightRecords[pet.PetId]
 if valid(previous) and pet.Weight<=previous then return nil end
 data.WeightRecords[pet.PetId]=pet.Weight
 return {First=not valid(previous),Weight=pet.Weight,Previous=valid(previous) and previous or nil}
end
return M
