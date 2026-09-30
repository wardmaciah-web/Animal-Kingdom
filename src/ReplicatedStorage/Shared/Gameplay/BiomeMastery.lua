local Biomes=require(script.Parent.Definitions.BiomeDefinitions)
local Pets=require(script.Parent.Definitions.PetDefinitions)
local Eggs=require(script.Parent.Definitions.EggDefinitions)
local Catalog=require(script.Parent.IndexCatalog)
local Config=require(script.Parent.Definitions.CollectionProgressionDefinitions).Mastery
local M={}
function M.Goals(biome)
 if not Biomes.IsContentReady(biome)then return {}end
 local eligible=Catalog.Current();local species=0;local cost
 for id in pairs(eligible)do if Pets[id].Biome==biome then species+=1 end end
 for _,pool in pairs(Eggs)do if pool.Biome==biome and not pool.Retired and #pool.Pets>0 then cost=math.min(cost or math.huge,pool.Cost)end end
 if not cost or species==0 then return {}end
 local goals={};for i,tier in ipairs(Config)do goals[i]={Level=i,Searches=tier.Searches,Discoveries=math.min(species,tier.Discoveries),Coins=math.floor(cost*tier.RewardSearches),Tokens=tier.Tokens}end
 return goals
end
function M.Ensure(data,biome)
 data.BiomeMastery=type(data.BiomeMastery)=="table" and data.BiomeMastery or {}
 local state=data.BiomeMastery[biome]
 if type(state)~="table"then state={Searches=0,Claims={}};data.BiomeMastery[biome]=state end
 state.Searches=type(state.Searches)=="number" and state.Searches==state.Searches and math.clamp(math.floor(state.Searches),0,1e12) or 0
 state.Claims=type(state.Claims)=="table" and state.Claims or {}
 return state
end
function M.Status(data,biome,level)
 local goal=M.Goals(biome)[level];if not goal then return nil end
 local state=M.Ensure(data,biome);local eligible=Catalog.Current();local discoveries=0
 for id in pairs(eligible)do if Pets[id].Biome==biome and data.PetIndex[id]then discoveries+=1 end end
 local ready=state.Searches>=goal.Searches and discoveries>=goal.Discoveries
 return {Goal=goal,Searches=state.Searches,Discoveries=discoveries,Ready=ready,Claimed=state.Claims[tostring(level)]==true,
  Fraction=math.min(1,state.Searches/goal.Searches,discoveries/goal.Discoveries)}
end
function M.Next(data,biome)
 for i in ipairs(M.Goals(biome))do local status=M.Status(data,biome,i);if not status.Claimed then return status end end
end
return M
