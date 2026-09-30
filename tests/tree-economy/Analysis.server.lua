-- Inject into Studio Play as a temporary Script. Exact calculations; no searches or writes.
assert(game:GetService('RunService'):IsStudio())
local H=game.HttpService
local G=game.ReplicatedStorage.Shared.Gameplay
local F=require(G.Definitions.TreeFamilyDefinitions)
local E=require(G.Definitions.EggDefinitions)
local P=require(G.Definitions.PetDefinitions)
local R=require(G.Definitions.RarityDefinitions)
local O=require(G.NormalTreeOdds)
local S=require(G.PetStats)
local Models=require(G.PetModelResolver)
local Catalog=require(G.IndexCatalog)
local B=require(G.Definitions.BiomeDefinitions)
local result={Checks=0,Pools={},Roster=0}
local function check(v,m)assert(v,m);result.Checks+=1 end
local ok,err=xpcall(function()
local seen={}
for _,biome in ipairs({'Meadow','Forest'})do
 local previousCost,previousIncome,previousTypical,previousRarity=0,0,0,0
 for _,f in ipairs(F.ByBiome[biome])do
  local pool=E[f.Id];local rows=O.Calculate(pool)
  local row={Biome=biome,Id=f.Id,Name=f.DisplayName,Tier=f.Tier,Cost=pool.Cost,Pets={},Rarities={},Min=math.huge,Max=0,Expected=0,MeanRarityOrder=0}
  local total,highest=0,0
  for _,entry in ipairs(rows)do
   local def=P[entry.PetId];local income=S.Income({PetId=def.PetId,Weight=def.BaseWeight})
   check(not seen[def.PetId],'Unique source '..def.PetId);seen[def.PetId]=true
   check(Models.Resolve(def.PetId)~=nil,'Real model '..def.PetId)
   check(entry.Probability>0,'Nonzero probability')
   check(income==def.BaseIncome and income>0,'Positive canonical base income')
   local sources=Catalog.SourcePools(def.PetId);check(#sources==1 and sources[1]==pool,'Index source identity')
   total+=entry.Probability;row.Expected+=entry.Probability*income
   row.MeanRarityOrder+=entry.Probability*R[def.Rarity].Order
   row.Rarities[def.Rarity]=(row.Rarities[def.Rarity] or 0)+entry.Probability
   row.Min=math.min(row.Min,income);row.Max=math.max(row.Max,income)
   if entry.Probability>highest then highest=entry.Probability;row.Typical=income;row.TypicalPet=def.PetId end
   table.insert(row.Pets,{Id=def.PetId,Name=def.DisplayName,Rarity=def.Rarity,Probability=entry.Probability,Income=income,BaseWeight=def.BaseWeight})
  end
  check(math.abs(total-1)<1e-12,'Normalized odds')
  for _,a in ipairs(row.Pets)do for _,b in ipairs(row.Pets)do if R[a.Rarity].Order>R[b.Rarity].Order then check(a.Probability<b.Probability,'Higher rarity is rarer')end end end
  for _,luck in ipairs({1,1.15,1.35,1.55,2})do
   local context={Luck=luck};local effective,weight=O.Calculate(pool,context)
   local sum=0
   for i,v in ipairs(effective)do
    local entry=pool.Pets[i];local expected=entry.DropWeight*luck^R[P[entry.PetId].Rarity].LuckExponent
    check(math.abs(v.Weight-expected)<1e-10,'Luck applied exactly once')
    check(math.abs(O.Chance(pool,v.PetId,context)-expected/weight)<1e-12,'Index probability equals selection weight')
    sum+=v.Probability
   end
   check(math.abs(sum-1)<1e-12,'Effective odds normalized')
  end
  check(pool.Cost==f.Cost and pool.Cost>previousCost,'Canonical strictly increasing price')
  check(row.Expected>previousIncome and row.Typical>previousTypical,'Expected and typical income increase')
  check(row.MeanRarityOrder>previousRarity,'Rarity composition improves within biome')
  previousCost,previousIncome,previousTypical,previousRarity=pool.Cost,row.Expected,row.Typical,row.MeanRarityOrder
  table.insert(result.Pools,row)
 end
end
for _ in pairs(seen)do result.Roster+=1 end
check(result.Roster==25,'14 Meadow plus 11 Forest real species')
local eligible=Catalog.Current();local count=0;for id in pairs(eligible)do count+=1;check(seen[id],'No unavailable Index species')end
check(count==25,'Current Index completion denominator')
check(E.Meadow_Shakeable_01.Cost==250,'Mandatory starter cost')
for _,b in ipairs(B.Ordered)do if b.Id~='Meadow' and b.Id~='Forest' then check(not b.ContentReady,'Future biome gated '..b.Id)end end
for _,f in ipairs(F.ByBiome.Jungle)do check(#f.PetIds==0 and #E[f.Id].Pets==0,'No placeholder pools')end
local L=require(G.Definitions.LuckyTreeDefinitions)
check(L.Attempts==3 and L.BoostSeconds==300 and L.Categories[1].DropWeight==5 and L.Categories[2].DropWeight==40 and L.Categories[3].DropWeight==55,'Lucky event table unchanged')
check(L.Biomes.Meadow.Coins==5000 and L.Biomes.Forest.Coins==20000 and L.Biomes.Meadow.LuckMultiplier==1.35 and L.Biomes.Forest.LuckMultiplier==1.55,'Lucky awards unchanged')
check(B.Forest.Cost==2500,'Existing Forest unlock unchanged')
end,debug.traceback)
result.Passed=ok;result.Error=not ok and err or nil
workspace:SetAttribute('AKEconomyAnalysis',H:JSONEncode(result))
if not ok then warn(err)end
