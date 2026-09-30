-- Pure contract state helpers, owned and invoked by the existing ChallengeService.
local Biomes=require(script.Parent.Definitions.BiomeDefinitions)
local Pets=require(script.Parent.Definitions.PetDefinitions)
local Eggs=require(script.Parent.Definitions.EggDefinitions)
local Catalog=require(script.Parent.IndexCatalog)
local Weight=require(script.Parent.PetWeight)
local Config=require(script.Parent.Definitions.CollectionProgressionDefinitions).Contracts
local M={}
function M.Key(entry)return entry.Type..":"..(entry.Biome or "")..":"..(entry.PoolId or "")end
function M.Candidates(data)
 local candidates={};local eligible=Catalog.Current()
 local function add(kind,biome,cost,pool)
  local config=Config[kind];local e={Type=kind,Biome=biome,PoolId=pool and pool.Id,Target=config.Target,Coins=config.Coins or math.floor(cost*config.CostFactor),Tokens=config.Tokens,WeightRatio=config.WeightRatio}
  if kind=="Search"then e.Description="Search "..e.Target.." "..biome.." trees."
  elseif kind=="Family"then e.Description="Search "..pool.DisplayName.." "..e.Target.." times."
  elseif kind=="Variety"then e.Description="Search "..e.Target.." different "..biome.." tree families."
  elseif kind=="Heavy"then e.Description="Find a "..biome.." pet at least "..e.WeightRatio.."× its base weight."
  elseif kind=="Discovery"then e.Description="Discover a new "..biome.." species."
  elseif kind=="Collector"then e.Description="Collect "..e.Target.." Forest Coins from your Sanctuary."
  elseif kind=="Garden"then e.Description="Complete a Garden expedition."end
  table.insert(candidates,e)
 end
 for _,biome in ipairs(Biomes.Ordered)do if Biomes.IsContentReady(biome.Id) and data.UnlockedBiomes[biome.Id]then
  local pools={};local missing,heavy=0,false
  for id in pairs(eligible)do if Pets[id].Biome==biome.Id then
   if not data.PetIndex[id]then missing+=1 end
   if Weight.Maximum(Pets[id])>=Config.Heavy.WeightRatio then heavy=true end
  end end
  for _,pool in pairs(Eggs)do if pool.Biome==biome.Id and not pool.Retired and #pool.Pets>0 then
   local valid=true;for _,entry in ipairs(pool.Pets)do if not eligible[entry.PetId]then valid=false;break end end
   if valid then table.insert(pools,pool)end
  end end
  table.sort(pools,function(a,b)return a.Id<b.Id end)
  if #pools>0 then
   local cost=pools[1].Cost
   add("Search",biome.Id,cost)
   if #pools>=Config.Variety.Target then add("Variety",biome.Id,cost)end
   if heavy then add("Heavy",biome.Id,cost)end
   if missing>0 then add("Discovery",biome.Id,cost)end
   for _,pool in ipairs(pools)do add("Family",biome.Id,pool.Cost,pool)end
  end
 end end
 if #data.Pets>0 then add("Collector",nil,0);add("Garden",nil,0)end
 return candidates
end
function M.Ensure(data,now,rng,guid)
 data.Contracts=type(data.Contracts)=="table" and data.Contracts or {}
 local state=data.Contracts;state.Version=1
 state.Entries=type(state.Entries)=="table" and state.Entries or {}
 state.Receipts=type(state.Receipts)=="table" and state.Receipts or {}
 local candidates=M.Candidates(data);local byKey={};for _,e in ipairs(candidates)do byKey[M.Key(e)]=e end
 local used={}
 for i=1,Config.Active do
  local e=state.Entries[i]
  -- Preserve valid identities/progress. Replace an unfinished impossible objective.
  if type(e)=="table" and type(e.Id)=="string" and type(e.Progress)=="number" and type(e.Target)=="number" and (byKey[M.Key(e)] or e.Progress>=e.Target)then used[M.Key(e)]=true
  else state.Entries[i]=false end
 end
 for i=1,Config.Active do if not state.Entries[i]then
  local choices={};for _,e in ipairs(candidates)do if not used[M.Key(e)]then table.insert(choices,e)end end
  if #choices==0 then choices=candidates end
  if #choices>0 then
   local e=table.clone(choices[rng:NextInteger(1,#choices)]);e.Id=guid();e.CreatedAt=now;e.Progress=0;e.Families={}
   state.Entries[i]=e;used[M.Key(e)]=true
  end
 end end
 return state
end
function M.Track(data,event,detail)
 local state=data.Contracts;if not state then return false end
 local changed=false
 for _,e in ipairs(state.Entries)do if type(e)=="table" and e.Progress<e.Target then
  local amount=0
  if event=="Pet"then
   local pet=detail.Pet;local def=Pets[pet.PetId];local normal=detail.Source=="NormalTree"
   if def and e.Biome==def.Biome then
    if e.Type=="Search" and normal then amount=1
    elseif e.Type=="Family" and normal and e.PoolId==detail.PoolId then amount=1
    elseif e.Type=="Variety" and normal and detail.PoolId then
     e.Families=e.Families or {};if not e.Families[detail.PoolId]then e.Families[detail.PoolId]=true;amount=1 end
    elseif e.Type=="Heavy" and pet.Weight>=Weight.Base(def)*e.WeightRatio then amount=1
    elseif e.Type=="Discovery" and detail.NewDiscovery then amount=1 end
   end
  elseif e.Type=="Collector" and event=="Collector"then amount=detail.Amount
  elseif e.Type=="Garden" and event=="Garden"then amount=1 end
  if amount>0 then e.Progress=math.min(e.Target,e.Progress+amount);changed=true end
 end end
 return changed
end
return M
