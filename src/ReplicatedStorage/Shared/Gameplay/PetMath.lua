local Pets=require(script.Parent.Definitions.PetDefinitions)
local Variants=require(script.Parent.Definitions.VariantDefinitions)
local M={}
function M.RequiredXP(level) return math.floor(25*level^1.65) end
function M.Power(pet)
 local def=Pets[pet.PetId];if not def then return 0 end
 local mutation=Variants.Mutations[pet.Mutation]
 return math.floor(def.BasePower*(1+(pet.Level-1)*.08)*(mutation and mutation.Power or 1)*(pet.Shiny and 1.5 or 1)*(pet.Prismatic and 2 or 1))
end
function M.Protected(pet)
 local def=Pets[pet.PetId]
 return pet.Favorite or pet.Locked or pet.Prismatic or (def and (def.Protected or def.Rarity=="Secret"))
end
return M
