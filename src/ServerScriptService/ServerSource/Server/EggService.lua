local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local Signal=require(RS.Packages.Signal)
local Eggs=require(RS.Shared.Gameplay.Definitions.EggDefinitions)
local BiomeDefinitions=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local Definitions=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Variants=require(RS.Shared.Gameplay.Definitions.VariantDefinitions)
local PetMath=require(RS.Shared.Gameplay.PetMath)
local Odds=require(RS.Shared.Gameplay.NormalTreeOdds)
local Format=require(RS.Shared.Gameplay.PetNumberFormat)
local Guard=require(script.Parent.Parent.Utilities.GameplayGuard)
local Egg=Knit.CreateService({Name="EggService",Client={},Hatched=Signal.new()})
local MeadowTrees=require(RS.Shared.Gameplay.Definitions.MeadowTreeDefinitions)
local ForestTrees=require(RS.Shared.Gameplay.Definitions.ForestTreeDefinitions)
local PoolValidation=require(script.Parent.Parent.Utilities.RewardPoolValidation)
local MeadowReady=require(script.Parent.Parent.Utilities.MeadowPoolReadiness)
local studioReward=setmetatable({},{__mode="k"})
local lastHatch=setmetatable({},{__mode="k"});local rng=Random.new()
local Data,Biomes,Pets,Modifiers,Loot
local function insufficient(def,data)
 local missing=math.max(0,def.Cost-data.Currencies.Coins)
 return def.DisplayName.." costs "..Format.Number(def.Cost).." Forest Coins. You need "..Format.Number(missing).." more; collect income from your Sanctuary."
end
-- Called only by server resource flow. No client-supplied egg ID, pet ID or price.
function Egg:CheckTreeHatch(player,tree)
 local record=Knit.GetService("ResourceService"):GetRecords()[tree]
 local biome=record and record.IsTree and BiomeDefinitions[record.Biome]
 if biome and not BiomeDefinitions.IsContentReady(record.Biome) then return false,BiomeDefinitions.ComingSoonMessage end
 local id=biome and (tree:GetAttribute("RewardPoolId") or biome.EggId);local def=id and Eggs[id]
 if record and record.Biome=="Meadow" then
  local issue;def,issue=MeadowTrees.Get(tree,record.Biome)
  if not def then return false,issue end
  id=def.Id
 end
 if record and record.Biome=="Forest" then
  local issue;def,issue=ForestTrees.Get(tree,record.Biome)
  if not def then warn("[ForestRewards] "..tostring(issue));return false,"This tree is temporarily unavailable. Please try another tree." end
  id=def.Id
 end
 if record and record.Biome=="Jungle" then
  local family,issue=require(RS.Shared.Gameplay.Definitions.TreeFamilyDefinitions).ResolveJungle(tree)
  if not family then return false,issue end
  id=family.Id;def=Eggs[id]
 end
 if not record or not def or def.Biome~=record.Biome or not tree:IsDescendantOf(workspace) then return false,"Invalid tree egg" end
 local ready,why=PoolValidation.Check(def)
 if not ready then return false,why end
 if def.CanonicalPool then
  local loaded,issue=MeadowReady.Check(def,player)
  if not loaded then
   warn('[RewardAssets] '..tostring(id)..': '..tostring(issue))
   return false,'These companions are still loading. Please try again shortly.'
  end
 end
 local data=Data:Get(player);local root=Guard.Alive(player)
 if not data or not root or (root.Position-record.InteractionPosition).Magnitude>18 then return false,"Move closer to the tree" end
 if not Biomes:IsUnlocked(player,record.Biome) then return false,"Biome locked" end
 if def.Season and not Knit.GetService("SeasonalService"):IsActive(def.Season) then return false,"Season is inactive" end
 if not Pets:HasSpace(player,1) then return false,"PET STORAGE FULL — manage or sell pets before searching." end
 if lastHatch[player] and os.clock()<lastHatch[player] then return false,"Your companion reveal is still in progress." end
 if def.CanonicalPool and not Knit.GetService("EconomyService"):CanAfford(player,"Coins",def.Cost) then return false,insufficient(def,data) end
 return true,def,id,data
end
-- Deliberately server-only and absent outside Studio. QA cannot be requested over a Remote.
if game:GetService("RunService"):IsStudio() then
 function Egg:StudioForceNext(player,petId)
  assert(script.Parent.ProfileService:GetAttribute("AKUseMockProfiles")==true,"QA requires mock profiles")
  assert(Definitions[petId],"Unknown QA species")
  studioReward[player]=petId
 end
end
function Egg:CreateRewardPet(player,petId,biome,search)
  local mutationPool={}
  for mutation,v in pairs(Variants.Mutations) do
   local dropWeight=v.Weight
   if mutation=="Spirit" and Knit.GetService("WeatherGameplayService"):GetEventId()=="SpiritNight" then dropWeight=150 end
   table.insert(mutationPool,{Id=mutation,DropWeight=dropWeight*(mutation=="Normal" and 1 or Modifiers:Get(player,"MutationChance",biome))})
  end
  table.sort(mutationPool,function(a,b) return a.Id<b.Id end)
  local mutation=Loot:Roll(mutationPool).Id
  local shiny=rng:NextNumber()<math.min(.5,Variants.ShinyChance*Modifiers:Get(player,"Shiny",biome))
  local luck=search and search.Odds.Luck or Modifiers:Get(player,"Luck",biome)
  local prismatic=rng:NextNumber()<math.min(.05,Variants.PrismaticChance*luck)
  return Pets:Create(petId,mutation,shiny,prismatic,luck,search and search.WeightBias)
end
local function roll(player,def,data,count,search)
 local results={}
 -- Shared weighted RNG and existing variant modifiers remain server-owned.
 for _=1,count do
  local selection
  local context=search and search.Odds or Modifiers:GetOddsContext(player,def.Biome)
  selection=Loot:Roll(def.Pets,function(entry)return Odds.Weight(entry,context)end)
  if game:GetService("RunService"):IsStudio() and studioReward[player] then
   local forced=studioReward[player];studioReward[player]=nil
   local found=false;for _,entry in ipairs(def.Pets)do if entry.PetId==forced then selection=entry;found=true;break end end
   if not found then return false,"Studio QA species is outside this tree pool" end
  end
  if not selection then return false,"Egg is unavailable" end
  local pet=Egg:CreateRewardPet(player,selection.PetId,def.Biome,search)
  if not pet then return false,"Pet definition unavailable" end
  table.insert(results,{Pet=pet,AutoDeleted=false})
 end
 return true,results
end
function Egg:CommitTree(player,tree,claim)
 local record=Knit.GetService("ResourceService"):GetRecords()[tree]
 if not record or record.State~="SHAKING" or record.Player~=player or record.Claim~=claim or not claim or record.Awarded then return false,"Tree claim unavailable" end
 local valid,def,id,data=self:CheckTreeHatch(player,tree)
 if not valid then return false,def end
 local search=claim.Search
 local ok,results=roll(player,def,data,1,search)
 if not ok then return false,results end
 -- Prepare the index change before charging. Commit is synchronous under the resource claim.
 if def.CanonicalPool then
  local result=results[1]
  local candidate={PetIndex=table.clone(data.PetIndex)}
  local previous=candidate.PetIndex[result.Pet.PetId]
  if previous then
   candidate.PetIndex[result.Pet.PetId]=table.clone(previous)
   candidate.PetIndex[result.Pet.PetId].Variants=table.clone(previous.Variants)
  end
  result.NewDiscovery=Pets:Discover(candidate,result.Pet)
  if not Knit.GetService("EconomyService"):Spend(player,"Coins",def.Cost,def.Biome.."TreeSearch") then return false,insufficient(def,data) end
  result.Destination=Pets:Adopt(data,result.Pet)
  data.PetIndex=candidate.PetIndex
 else
  for _,result in ipairs(results) do
   result.NewDiscovery=Pets:Discover(data,result.Pet)
   if not result.AutoDeleted then result.Destination=Pets:Adopt(data,result.Pet) end
  end
 end
 local duration=math.max(.6,def.HatchSeconds/Modifiers:Get(player,"HatchSpeed"))
 record.HatchResult={Kind="Hatch",Source="Tree",EggId=id,PoolId=def.CanonicalPool and id or nil,Cost=def.CanonicalPool and def.Cost or 0,Results=results,Duration=duration}
 record.Awarded=true
 for _,result in ipairs(results)do Pets:RecordAward(player,result.Pet,result,{Source="NormalTree",Biome=def.Biome,PoolId=id,Search=search})end
 lastHatch[player]=os.clock()+duration+(search and search.Recovery or 1.5) -- never shorten the reveal or shared transaction lock
 Pets:Publish(player)
 for _,result in ipairs(results) do Pets.Granted:Fire(player,result.Pet,result.NewDiscovery) end
 self.Hatched:Fire(player,1,record.Biome,record.HatchResult)
 return true,record.HatchResult
end
function Egg:HatchFromTree(player,tree,claim)
 return Pets:Transaction(player,function()return self:CommitTree(player,tree,claim)end)
end
-- Retired compatibility entry: arbitrary world egg requests cannot produce a reward.
function Egg:Hatch() return false,"Search a biome tree to find a companion" end
function Egg:KnitInit()
 Data=Knit.GetService("PlayerDataService");Biomes=Knit.GetService("BiomeService")
 Pets=Knit.GetService("PetService");Modifiers=Knit.GetService("ModifierService");Loot=Knit.GetService("LootService")
end
function Egg:KnitStart() MeadowReady.Start() end
return Egg
