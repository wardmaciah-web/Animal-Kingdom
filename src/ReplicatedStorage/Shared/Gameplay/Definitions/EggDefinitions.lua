local Biomes=require(script.Parent.BiomeDefinitions)
local Pets=require(script.Parent.PetDefinitions)
local Families=require(script.Parent.TreeFamilyDefinitions)
local weights=Families.RarityWeights
local eggs={}
for _,biome in ipairs(Biomes.Ordered) do
 local pool={}
 for _,pet in ipairs(Pets.Ordered) do
  if pet.Biome==biome.Id and not pet.LegacyOnly then table.insert(pool,{PetId=pet.PetId,DropWeight=weights[pet.Rarity]}) end
 end
 eggs[biome.EggId]={Id=biome.EggId,DisplayName=biome.DisplayName.." Egg",ModelName=biome.EggId,Currency="Coins",
  Cost=biome.Order==1 and 250 or math.max(750,math.floor(biome.Cost/10)),Biome=biome.Id,Pets=pool,AllowTriple=true,HatchSeconds=2}
end
-- Dedicated families share the existing reward engine, currency and timing.
for biome,families in pairs(Families.ByBiome)do
 local legacy=eggs[biome.."Egg"]
 -- Future generated definitions are retained; empty future family pools stay unavailable.
 if Biomes.IsContentReady(biome) then legacy.Pets={};legacy.Retired=true end
 for _,family in ipairs(families)do
  assert(not Biomes.IsContentReady(biome) or (type(family.Cost)=="number" and family.Cost>0 and family.Cost%1==0),"Released tree needs a canonical price: "..family.Id)
  local pool={}
  for _,petId in ipairs(family.PetIds)do
   local pet=assert(Pets[petId],"Unknown configured tree species: "..petId)
   assert(pet.Biome==biome and not pet.LegacyOnly and not pet.RetiredFromRewards,"Invalid tree species: "..petId)
   table.insert(pool,{PetId=petId,DropWeight=(family.RarityWeights and family.RarityWeights[pet.Rarity]) or assert(weights[pet.Rarity])})
  end
  eggs[family.Id]={Id=family.Id,DisplayName=family.DisplayName,ModelName=biome.."Egg",Currency="Coins",
   Cost=family.Cost or legacy.Cost,Biome=biome,Tier=family.Tier,Pets=pool,AllowTriple=false,
   HatchSeconds=biome=="Forest" and 1.4 or 2,MeadowPool=biome=="Meadow",ForestPool=biome=="Forest",CanonicalPool=true}
 end
end
return eggs
