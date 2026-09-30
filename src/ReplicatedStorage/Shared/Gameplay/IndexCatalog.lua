-- One collection rule shared by Index presentation and the authoritative claim service.
-- Eligibility requires released content and a complete, non-retired pool with real models.
local Eggs=require(script.Parent.Definitions.EggDefinitions)
local Pets=require(script.Parent.Definitions.PetDefinitions)
local Models=require(script.Parent.PetModelResolver)
local Biomes=require(script.Parent.Definitions.BiomeDefinitions)
local M={}
function M.Current()
 local eligible,sources={},{}
 for _,pool in pairs(Eggs)do
  if Biomes.IsContentReady(pool.Biome) and not pool.Retired and #pool.Pets>0 then
   local available=true
   for _,entry in ipairs(pool.Pets)do
    local def=Pets[entry.PetId]
    if not def or not Biomes.IsContentReady(def.Biome) or def.RetiredFromRewards or def.LegacyOnly or not Models.Resolve(entry.PetId) then available=false;break end
   end
   if available then
    for _,entry in ipairs(pool.Pets)do if (entry.DropWeight or 0)>0 then
     eligible[entry.PetId]=true;sources[entry.PetId]=sources[entry.PetId] or {}
     table.insert(sources[entry.PetId],pool.DisplayName or (pool.Biome..' tree'))
    end end
   end
  end
 end
 for _,list in pairs(sources)do table.sort(list)end
 return eligible,sources
end
function M.SourcePools(petId)
 local eligible=M.Current();local pools={}
 if not eligible[petId]then return pools end
 for _,pool in pairs(Eggs)do if not pool.Retired and Biomes.IsContentReady(pool.Biome)then
  for _,entry in ipairs(pool.Pets)do if entry.PetId==petId then table.insert(pools,pool);break end end
 end end
 table.sort(pools,function(a,b)return a.Id<b.Id end);return pools
end
return M
