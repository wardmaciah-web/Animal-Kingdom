-- Additive profile state, shared with the existing challenges and mastery ledgers.
-- Does not rewrite ownership, accumulated income, legacy challenges or contracts.
local Config=require(script.Parent.Definitions.KingdomActivityDefinitions)
local Families=require(script.Parent.Definitions.TreeFamilyDefinitions)
local Pets=require(script.Parent.Definitions.PetDefinitions)
local Weight=require(script.Parent.PetWeight)
local Rarities=require(script.Parent.Definitions.RarityDefinitions)
local M={}
local function dictionary(parent,key)if type(parent[key])~="table"then parent[key]={}end;return parent[key]end
function M.Ensure(data)
 local a=dictionary(data,"Activities");a.Version=1
 for _,key in ipairs({"BiomeGoals","Pending","Receipts","Seen","SeenOrder","CompletedAdventures","MissionDays"})do dictionary(a,key)end
 dictionary(data,"TreeMastery")
 local s=dictionary(data,"KingdomShop");s.Version=1
 for _,key in ipairs({"Active","Rotations","Receipts"})do dictionary(s,key)end
 s.Fertilizer=math.clamp(tonumber(s.Fertilizer)or 0,0,1)
 return a,s
end
function M.Family(data,id)
 M.Ensure(data);if not Families[id]then return nil end
 local f=data.TreeMastery[id]
 if type(f)~="table"then f={Searches=0,Species={},Heaviest=0};data.TreeMastery[id]=f end
 return f
end
function M.Rank(searches)
 local rank=0;for i,n in ipairs(Config.FamilyRanks)do if (searches or 0)>=n then rank=i end end;return rank
end
function M.FamilyLuck(data,id)
 local f=data.TreeMastery and data.TreeMastery[id]
 return 1+math.min(Config.FamilyLuckCap,M.Rank(f and(f.Points or f.Searches))*Config.FamilyLuckPerRank)
end
function M.RecordFamily(data,id,pet,extra)
 local family=Families[id];if not family or not table.find(family.PetIds,pet.PetId)then return end
 local f=M.Family(data,id);f.Points=(f.Points or f.Searches)+1+math.clamp(extra or 0,0,1);f.Searches+=1;f.Species[pet.PetId]=true
 if pet.Weight>f.Heaviest then f.Heaviest=pet.Weight;f.HeaviestPetId=pet.PetId end
end
function M.FirstEvent(data,id)
 local a=M.Ensure(data)
 if a.Seen[id]then return false end
 a.Seen[id]=true;table.insert(a.SeenOrder,id)
 while #a.SeenOrder>Config.Limits.EventReceipts do a.Seen[table.remove(a.SeenOrder,1)]=nil end
 return true
end
function M.Detail(pet)
 local def=Pets[pet.PetId]
 return {UID=pet.UID,PetId=pet.PetId,Weight=pet.Weight,Ratio=Weight.Ratio(pet,def),Rarity=def and Rarities[def.Rarity].Order or 0,Biome=def and def.Biome}
end
function M.Active(data,id,now)
 local s=data.KingdomShop;local b=s and s.Active and s.Active[id]
 return b and b.StartedAt<=now and b.ExpiresAt>now and b or nil
end
-- Integrate the blessing against the existing weather-weighted clock. Offline
-- segments deliberately use unit weather, matching existing Sanctuary semantics.
function M.IncomeSeconds(data,startAt,endAt,weather)
 if endAt<=startAt then return 0 end
 local b=data.KingdomShop and data.KingdomShop.Active and data.KingdomShop.Active.Blessing
 local integrate=weather or function(a,z)return z-a end
 if not b then return integrate(startAt,endAt)end
 local a=math.max(startAt,b.StartedAt);local z=math.min(endAt,b.ExpiresAt)
 return integrate(startAt,endAt)+(z>a and .15*integrate(a,z)or 0)
end
function M.Advance(goal,event,detail)
 if goal.Claimed or goal.Progress>=goal.Target then return false end
 if goal.Biome and goal.Biome~=detail.Biome then return false end
 local amount=0
 if goal.Kind=="Search" and event=="Search"then amount=1
 elseif goal.Kind=="Rarity" and event=="Search" and detail.Rarity>=goal.Rarity then amount=1
 elseif goal.Kind=="Heavy" and event=="Search" and detail.Ratio>=goal.Ratio then amount=1
 elseif goal.Kind=="Collect" and event=="Collect"then amount=detail.Amount
 elseif goal.Kind=="Garden" and event=="Garden"then amount=1
 elseif goal.Kind=="Place" and event=="Place"then amount=1 end
 if amount<=0 then return false end
 goal.Progress=math.min(goal.Target,goal.Progress+amount);return true
end
function M.Complete(entries)
 for _,e in ipairs(entries)do if e.Progress<e.Target then return false end end;return #entries>0
end
return M
