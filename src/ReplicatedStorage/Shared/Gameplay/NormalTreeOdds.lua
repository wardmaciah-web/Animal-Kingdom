-- One pure calculation for server selection and Index display. Context is server-owned.
local Pets=require(script.Parent.Definitions.PetDefinitions)
local Rarities=require(script.Parent.Definitions.RarityDefinitions)
local M={}
function M.Weight(entry,context)
 local pet=Pets[entry.PetId];if not pet then return 0 end
 context=context or {};local rarity=Rarities[pet.Rarity]
 local value=entry.DropWeight*(context.Luck or 1)^(rarity and rarity.LuckExponent or 0)
 value*=context.Rarities and context.Rarities[pet.Rarity] or 1
 if rarity and rarity.Order>=3 then value*=context.RareDrops or 1 end
 if pet.Rarity=="Secret" then value*=context.SecretChance or 1 end
 return value*(context.BiomeMultiplier or 1)
end
function M.Calculate(pool,context)
 local rows,total={},0
 for _,entry in ipairs(pool.Pets)do
  local weight=M.Weight(entry,context);assert(weight>=0 and weight<math.huge,"Invalid normal tree weight")
  total+=weight;table.insert(rows,{PetId=entry.PetId,Weight=weight})
 end
 for _,row in ipairs(rows)do row.Probability=total>0 and row.Weight/total or 0 end
 return rows,total
end
function M.Chance(pool,petId,context)
 for _,row in ipairs(M.Calculate(pool,context))do if row.PetId==petId then return row.Probability end end
 return 0
end
function M.Format(probability)
 local percent=probability*100
 if percent==0 then return "0%" end
 if percent<.000001 then return "<0.000001%" end
 local places=percent>=1 and 2 or math.min(8,math.max(2,2-math.floor(math.log10(percent))))
 return string.format("%."..places.."f%%",percent)
end
return M
