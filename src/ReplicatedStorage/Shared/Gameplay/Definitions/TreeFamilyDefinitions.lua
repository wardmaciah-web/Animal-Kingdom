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
-- Explicitly group the eight existing Jungle visual variants into five reward
-- families. Never infer tiers from sorting, positions, or similarly named trees.
M.JungleVisualFamilies={JungleRainTree=1,JungleKapok=2,JungleOrchid=3,
 JunglePalm=4,JungleFanPalm=4,JungleDragon=4,JungleBanyan=5,JungleFig=5}
M.JungleSourceFamilies={tree_palmDetailedTall=1,Tree_Palm_2=2,CommonTree_5=3,
 PalmTree_1=4,tree_palmDetailedShort=4,tree_palmTall=4,Tree_Oak_7=5,Tree_Oak_8=5,
 JungleTreeType1=1,JungleTreeType2=2,JungleTreeType3=3,JungleTreeType4=4,JungleTreeType5=5}
function M.ResolveJungle(tree)
 if tree:GetAttribute("BiomeId")~="Jungle" or tree:GetAttribute("AuthoredGatherableTree")~=true then
  return nil,"Not an authored Jungle tree"
 end
 local source=tree:GetAttribute("SourceAssetName") or tree:GetAttribute("TreeType")
 local sourceTier=M.JungleSourceFamilies[source]
 local visual=tree:FindFirstChild("AK_FutureTreeVisual")
 local visualName=visual and visual:GetAttribute("VisualTemplate")
 local tier=visualName and M.JungleVisualFamilies[visualName] or sourceTier
 if visualName and not M.JungleVisualFamilies[visualName] then return nil,"Unregistered Jungle visual" end
 if not tier or (sourceTier and tier~=sourceTier) then return nil,"Unregistered or conflicting Jungle family" end
 local def=M[string.format("Jungle_Shakeable_%02d",tier)]
 for _,key in {"RewardPoolId","ShakeableId"} do
  local existing=tree:GetAttribute(key)
  if existing and existing~=def.Id then return nil,"Jungle reward mapping conflicts with authored family" end
 end
 return def
end
function M.BindJungle(tree)
 local def,issue=M.ResolveJungle(tree)
 if not def then return nil,issue end
 -- Metadata only. Geometry, prices, probabilities and release gates are untouched.
 tree:SetAttribute("TreeTier",def.Tier)
 tree:SetAttribute("RewardPoolId",def.Id)
 tree:SetAttribute("ShakeableId",def.Id)
 tree:SetAttribute("EggId",def.Id)
 return def
end
return M
