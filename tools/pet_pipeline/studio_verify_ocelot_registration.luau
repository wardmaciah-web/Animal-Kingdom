-- Fresh module snapshot avoids Edit-mode require caches; never releases content.
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Edit only")
assert(game.PlaceId==132313449035787, "Wrong place")
local shared=game.ReplicatedStorage.Shared
assert(not shared:FindFirstChild("_AKFactoryVerification"), "Previous verification was not cleaned up")
local baseline=require(shared.Gameplay.Definitions.TreeFamilyDefinitions)
local snapshot=shared.Gameplay:Clone()
snapshot.Name="_AKFactoryVerification"; snapshot.Parent=shared
local ok,result=pcall(function()
 local definitions=require(snapshot.Definitions.PetDefinitions)
 local families=require(snapshot.Definitions.TreeFamilyDefinitions)
 local pools=require(snapshot.Definitions.EggDefinitions)
 local biomes=require(snapshot.Definitions.BiomeDefinitions)
 local def=assert(definitions.JungleOcelot)
 assert(def.Rarity=="Rare" and def.BaseWeight==12 and def.BaseIncome==93, "Incorrect Ocelot economy")
 local family=assert(families.Jungle_Shakeable_03)
 assert(#family.PetIds==1 and family.PetIds[1]=="JungleOcelot", "Incorrect family")
 local pool=pools[family.Id]
 assert(#pool.Pets==1 and pool.Pets[1].PetId=="JungleOcelot" and pool.Pets[1].DropWeight==12, "Incorrect pool")
 for _,biome in ipairs({"Meadow","Forest"}) do
  for i,before in ipairs(baseline.ByBiome[biome]) do
   local after=families.ByBiome[biome][i]
   assert(before.Id==after.Id and before.Cost==after.Cost and before.DisplayName==after.DisplayName, "Existing family changed")
   assert(table.concat(before.PetIds,"|")==table.concat(after.PetIds,"|"), "Existing reward membership changed")
  end
 end
 for _,biome in ipairs(biomes.Ordered) do
  if biome.Id~="Meadow" and biome.Id~="Forest" then assert(not biomes.IsContentReady(biome.Id), "Future biome released") end
 end
 assert(not require(snapshot.IndexCatalog).Current().JungleOcelot, "Locked Ocelot exposed in released index")
 local resolver=require(snapshot.PetModelResolver)
 local model,reason=resolver.Resolve("JungleOcelot");assert(model,reason)
 local clone,issue=resolver.Clone("JungleOcelot");assert(clone,issue)
 local meshes=0
 for _,part in clone:GetDescendants() do
  if part:IsA("MeshPart") then meshes+=1;assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery) end
 end
 local _,size=clone:GetBoundingBox();clone:Destroy()
 assert(meshes==2 and math.abs(size.Y-2.8)<.02, "Incorrect production geometry")
 return {passed=true,pet="JungleOcelot",family=family.Id,rarity=def.Rarity,base_weight=def.BaseWeight,
  base_income=def.BaseIncome,drop_weight=pool.Pets[1].DropWeight,meshes=meshes,
  meadow_forest_unchanged=true,future_gates_locked=true,interaction_qa="pending",published=false}
end)
snapshot:Destroy()
assert(ok,result)
return result
