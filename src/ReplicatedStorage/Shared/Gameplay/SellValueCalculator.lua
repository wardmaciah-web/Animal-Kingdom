local Definitions=require(script.Parent.Definitions.PetDefinitions)
local Variants=require(script.Parent.Definitions.VariantDefinitions)
local Weight=require(script.Parent.PetWeight)
local PetMath=require(script.Parent.PetMath)
local M={RarityMultiplier={Common=1,Uncommon=1.1,Rare=1.25,Epic=1.45,Legendary=1.75,Mythical=2,Secret=2.2}}
function M.Calculate(pet)
 local def=Definitions[pet.PetId];if not def then return 0 end
 local mutation=Variants.Mutations[pet.Mutation or 'Normal']
 local level=1+(math.clamp(pet.Level or 1,1,100)-1)*.02
 local value=def.BaseSellValue*M.RarityMultiplier[def.Rarity]*Weight.Ratio(pet,def)^.8*level
  *(mutation and mutation.Power or 1)*(pet.Shiny and 1.5 or 1)*(pet.Prismatic and 2 or 1)
 return math.clamp(math.floor(value+.5),1,1e12)
end
-- Prevent the only onboarding companion being sold below the cost of replacing it.
-- This is temporary guidance safety, not another saved lock flag.
function M.OnboardingProtected(data,pet,remainingCount,proceeds)
 local p=data and data.TutorialProgress
 return p and not data.TutorialCompleted and p.FlowVersion==2 and p.Step>=2 and p.Step<=5 and p.PetUID==pet.UID and (remainingCount or #data.Pets-1)==0
  and data.Currencies.Coins+(proceeds or M.Calculate(pet))<require(script.Parent.Definitions.MeadowTreeDefinitions).Ordered[1].Cost
end
function M.Eligible(pet,location,data)
 location=location or 'Inventory'
 return (location=='Inventory' or location=='Held') and Definitions[pet.PetId]~=nil and pet.Location==location and not PetMath.Protected(pet) and not M.OnboardingProtected(data,pet)
end
return M
