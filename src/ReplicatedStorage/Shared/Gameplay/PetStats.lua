local Definitions=require(script.Parent.Definitions.PetDefinitions)
local Weight=require(script.Parent.PetWeight)
local Config=require(script.Parent.Definitions.PetWeightDefinitions)
local M={}
-- Economic values are calculated by services; UI consumes their published snapshot.
function M.Income(pet)
 local def=Definitions[pet.PetId];if not def then return 0 end
 local base=def.BaseIncome or def.BaseIncomePerSecond or def.CoinsPerSecond or 0
 return math.min(1e12,math.floor(base*Weight.Ratio(pet,def)^Config.IncomeExponent*100+.5)/100)
end
return M
