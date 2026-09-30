-- Validate the entire advertised pool before a charge or reward. Never prune odds.
local RS=game:GetService("ReplicatedStorage")
local Pets=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Rarities=require(RS.Shared.Gameplay.Definitions.RarityDefinitions)
local Models=require(RS.Shared.Gameplay.PetModelResolver)
local M={}
local logged={}
function M.Check(def)
 local issue
 if not def or type(def.Pets)~="table" or #def.Pets==0 then issue="Empty reward pool"
 else
  local seen={}
  for _,entry in ipairs(def.Pets) do
   local pet=Pets[entry.PetId]
   local income=pet and (pet.BaseIncomePerSecond or pet.CoinsPerSecond)
   if not pet or not Rarities[pet.Rarity] or type(income)~="number" or income~=income or income<=0 or income>=math.huge then issue="Invalid definition, rarity or income: "..tostring(entry.PetId);break end
   if seen[entry.PetId] or type(entry.DropWeight)~="number" or entry.DropWeight~=entry.DropWeight or entry.DropWeight<=0 or entry.DropWeight>=math.huge then issue="Invalid reward weights: "..entry.PetId;break end
   seen[entry.PetId]=true
   local model,why=Models.Resolve(entry.PetId)
   if not model then issue=why;break end
  end
 end
 if issue then
  local key=tostring(def and def.Id)..": "..issue
  if not logged[key] then logged[key]=true;warn("[RewardPool] "..key) end
  return false,"This tree is temporarily unavailable. Please try another tree."
 end
 return true
end
return M
