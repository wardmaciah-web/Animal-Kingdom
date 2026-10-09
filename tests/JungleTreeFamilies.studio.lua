-- Run in Studio Edit. Detached fixtures never enter the scene or change assets.
local F=require(game.ReplicatedStorage.Shared.Gameplay.Definitions.TreeFamilyDefinitions)
local cases={
 {"tree_palmDetailedTall","JungleRainTree",1},{"Tree_Palm_2","JungleKapok",2},
 {"CommonTree_5","JungleOrchid",3},{"PalmTree_1","JunglePalm",4},
 {"tree_palmDetailedShort","JungleFanPalm",4},{"tree_palmTall","JungleDragon",4},
 {"Tree_Oak_7","JungleBanyan",5},{"Tree_Oak_8","JungleFig",5},
}
local function fixture(source,visualName)
 local tree=Instance.new("Model")
 tree:SetAttribute("AuthoredGatherableTree",true);tree:SetAttribute("BiomeId","Jungle")
 tree:SetAttribute("SourceAssetName",source)
 if visualName then local visual=Instance.new("Model");visual.Name="AK_FutureTreeVisual";visual:SetAttribute("VisualTemplate",visualName);visual.Parent=tree end
 return tree
end
for _,row in cases do
 local tree=fixture(row[1],row[2]);local def=assert(F.BindJungle(tree))
 assert(def.Tier==row[3] and tree:GetAttribute("RewardPoolId")==def.Id)
 assert(F.BindJungle(tree)==def,"Binding must be idempotent")
 tree:SetAttribute("RewardPoolId","Jungle_Shakeable_99")
 assert(not F.ResolveJungle(tree),"Conflicting reward IDs must fail closed")
 tree:Destroy()
end
for _,row in {{"Unknown",nil},{"PalmTree_1","Unknown"},{"PalmTree_1","JungleOrchid"}} do
 local tree=fixture(row[1],row[2]);assert(not F.ResolveJungle(tree));tree:Destroy()
end
local tree=fixture("CommonTree_5","JungleOrchid")
tree:SetAttribute("BiomeId","Forest");assert(not F.BindJungle(tree));tree:Destroy()
local eggs=require(game.ReplicatedStorage.Shared.Gameplay.Definitions.EggDefinitions)
assert(eggs.Jungle_Shakeable_03.Pets[1].PetId=="JungleOcelot" and eggs.Jungle_Shakeable_03.Pets[1].DropWeight==12)
assert(eggs.Jungle_Shakeable_04.Pets[1].PetId=="JungleRedPanda" and eggs.Jungle_Shakeable_04.Pets[1].DropWeight==4)
assert(not require(game.ReplicatedStorage.Shared.Gameplay.Definitions.BiomeDefinitions).IsContentReady("Jungle"))
return "PASS: eight visual variants, idempotence, conflicting/unknown/cross-biome rejection, reward weights, Jungle lock"
