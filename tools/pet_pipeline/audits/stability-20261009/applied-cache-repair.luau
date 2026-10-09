assert(game.PlaceId==132313449035787 and game.GameId==10764288431,"Wrong place")
assert(not game:GetService("RunService"):IsRunning(),"Edit only")
local D=game.ReplicatedStorage.Shared.Gameplay.Definitions
local canonical={["EggDefinitions"]=[====[local Biomes=require(script.Parent.BiomeDefinitions)
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
]====],
["TreeFamilyDefinitions"]=[====[-- Stable identities; art copies keep their existing names and transforms.
-- Membership is explicit: one normal family source per real species.
local M={Ordered={},ByBiome={}}
local rows={
 Meadow={
  {"Blossombark",{"MeadowFieldMouse","MeadowPatchworkLop","MeadowBlossomBunny"},250},
  {"Honeybloom",{"MeadowChick","MeadowFawn","MeadowCloudtailFox"},500,{Common=40}},
  {"Clover Crown",{"MeadowRedSquirrel","MeadowFluffyLop","MeadowPrismAntlerDeer"},1000},
  {"Sunpetal",{"MeadowGoat","MeadowBuck","MeadowDaisyCrownBunny"},2000},
  {"Whisper Willow",{"MeadowDaisyHedgehog","MeadowCelestialLamb"},4000},
 },
 Forest={
  {"Mossheart",{"ForestRaccoon","ForestTreeFrog","ForestEmeraldWing"},6000},
  {"Fernwood",{"ForestBlackBearCub","ForestBrownBat"},10000,{Common=24}},
  {"Duskleaf",{"ForestSkunk","ForestWoodlandOwl"},17500},
  {"Elderbark",{"ForestBadger","ForestLeafAntler"},30000,{Uncommon=7}},
  {"Mooncap",{"ForestRiverOtter","ForestCrestedOwl"},50000},
 },
 Jungle={{"Rainbloom",{}},{"Emerald Canopy",{}},{"Orchidwood",{"JungleOcelot"}},{"Sunvine",{"JungleRedPanda"}},{"Ancient Banyan",{}}},
}
local jungleAssets={102129896464910,75371450572430,108493964560570,82147578184060,118350292207829}
-- A row owns its price and optional base rarity-weight overrides. Physical copies
-- resolve this stable ID; Luck is applied once by NormalTreeOdds after these weights.
-- Overrides improve the rarity mix without moving species or changing their rarity.
M.RarityWeights={Common=55,Uncommon=28,Rare=12,Epic=4,Legendary=.9,Mythical=.1,Secret=.001}
for _,biome in ipairs({"Meadow","Forest","Jungle"})do
 M.ByBiome[biome]={}
 for tier,row in ipairs(rows[biome])do
  local id=string.format("%s_Shakeable_%02d",biome,tier)
  local def={Id=id,Biome=biome,Tier=tier,DisplayName=row[1],PetIds=row[2],Cost=row[3],RarityWeights=row[4]}
  if biome=="Jungle" then def.TemplateName="JungleTreeType"..tier;def.SourceAssetId=jungleAssets[tier] end
  M[id]=def;table.insert(M.Ordered,def);table.insert(M.ByBiome[biome],def)
 end
end
return M
]====],
["ImportedPetDefinitions"]=[====[-- Additional real imports, from any configured biome, register here.
-- Each entry needs PetTypeId, DisplayName, Biome, Rarity, BaseIncome and ModelKey.
-- ModelKey resolves ReplicatedStorage.PetAssets; optional ModelAssets pins mesh/PBR provenance.
-- Add the registered species to its authoritative reward pool after validating the import.
return {
 {PetTypeId="JungleRedPanda",DisplayName="Red Panda",Biome="Jungle",Rarity="Epic",
  BaseWeight=7,BaseIncome=130,ModelKey="JungleRedPanda",ModelRotation=0,
  ProductionRun="red-panda-texture-001",ModelAssets={
   {MeshId="rbxassetid://101125666523290",ColorMap="rbxassetid://91899617902182",NormalMap="rbxassetid://86440326379848"},
   {MeshId="rbxassetid://114629416154775",TextureId="rbxassetid://91899617902182"},
  }},
 {PetTypeId="JungleOcelot",DisplayName="Ocelot",Biome="Jungle",Rarity="Rare",
  BaseWeight=12,BaseIncome=93,ModelKey="JungleOcelot",ModelRotation=0,
  ProductionRun="ocelot-d-reproduction-001",ModelAssets={
   {MeshId="rbxassetid://86956296653033",TextureId="rbxassetid://89955741043720"},
   {MeshId="rbxassetid://83705741042121",TextureId="rbxassetid://89955741043720"},
  }},
}
]====]}
local function stablePools()
 local e=require(D.EggDefinitions) local r={}
 for id,pool in pairs(e) do if pool.Biome=="Meadow" or pool.Biome=="Forest" then r[id]=pool end end
 return game.HttpService:JSONEncode(r)
end
local before={sunvine=require(D.TreeFamilyDefinitions).Jungle_Shakeable_04.PetIds,rewards=require(D.EggDefinitions).Jungle_Shakeable_04.Pets}
local baseline=stablePools()
-- Refresh instances, not just Source: Studio caches require by instance.
local replaced={}
for _,name in {"ImportedPetDefinitions","PetDefinitions","TreeFamilyDefinitions","EggDefinitions"} do
 local old=D[name] local fresh=old:Clone()
 fresh.Source=canonical[name] or old.Source
 old.Parent=nil fresh.Parent=D
 table.insert(replaced,name)
 old:Destroy()
end
local P=require(D.PetDefinitions) local F=require(D.TreeFamilyDefinitions) local E=require(D.EggDefinitions)
assert(stablePools()==baseline,"Existing Meadow/Forest pools changed")
assert(P.JungleRedPanda.BaseWeight==7 and P.JungleRedPanda.BaseIncome==130 and P.JungleRedPanda.Rarity=="Epic")
assert(#F.Jungle_Shakeable_04.PetIds==1 and F.Jungle_Shakeable_04.PetIds[1]=="JungleRedPanda")
assert(#E.Jungle_Shakeable_04.Pets==1 and E.Jungle_Shakeable_04.Pets[1].PetId=="JungleRedPanda" and E.Jungle_Shakeable_04.Pets[1].DropWeight==4)
assert(E.Jungle_Shakeable_03.Pets[1].PetId=="JungleOcelot" and E.Jungle_Shakeable_03.Pets[1].DropWeight==12)
assert(not require(D.BiomeDefinitions).IsContentReady("Jungle"))
return game.HttpService:JSONEncode({before=before,after={family=F.Jungle_Shakeable_04,rewards=E.Jungle_Shakeable_04.Pets},replaced=replaced,meadow_forest_unchanged=true,jungle_locked=true,passed=true})
