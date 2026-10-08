-- Stable identities; art copies keep their existing names and transforms.
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
 Jungle={{"Rainbloom",{}},{"Emerald Canopy",{}},{"Orchidwood",{"JungleOcelot"}},{"Sunvine",{}},{"Ancient Banyan",{}}},
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
