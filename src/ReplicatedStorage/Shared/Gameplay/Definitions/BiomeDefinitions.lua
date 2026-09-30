local Legacy=require(script.Parent.Parent.Parent.Parent.SharedSource.Datas.AnimalKingdomConfig)
-- Release configuration: environments and saved unlocks do not imply playable content.
-- Enable a biome here after registering and validating its real pet reward pools.
local contentReady={Meadow=true,Forest=true}
local result={Ordered={}}
for order,biome in ipairs(Legacy.Biomes) do
 local def={Id=biome.Id,DisplayName=biome.DisplayName,Order=order,PreviousBiome=order>1 and Legacy.Biomes[order-1].Id or nil,
  ContentReady=contentReady[biome.Id]==true,
  Cost=biome.UnlockCost,Currency="Coins",EggId=biome.Id.."Egg",Egg=biome.Id.."Egg",ResourceTable=biome.Id.."Tree",
  BaseReward=order==1 and 90 or math.max(180,math.floor(biome.UnlockCost/12))}
 result[def.Id]=def;table.insert(result.Ordered,def)
end
function result.IsContentReady(id)
 local def=result[id]
 return type(def)=="table" and def.ContentReady==true
end
result.ComingSoonMessage="This biome is coming soon!"
return result
