local D=game.ReplicatedStorage.Shared.Gameplay.Definitions
local P=require(D.PetDefinitions) local F=require(D.TreeFamilyDefinitions) local E=require(D.EggDefinitions) local B=require(D.BiomeDefinitions)
local report={context="runtime Server Script",families={},physical={},jungle_locked=not B.IsContentReady("Jungle")}
assert(P.JungleRedPanda.BaseWeight==7 and P.JungleRedPanda.BaseIncome==130 and P.JungleRedPanda.Rarity=="Epic")
for _,f in F.Ordered do
 local pool=assert(E[f.Id]) local wanted={} for _,id in f.PetIds do wanted[id]=true end
 for _,entry in pool.Pets do assert(wanted[entry.PetId],"Unexpected member "..entry.PetId) wanted[entry.PetId]=nil end
 assert(next(wanted)==nil,"Missing member "..f.Id)
 report.families[f.Id]={pets=pool.Pets,cost=pool.Cost}
end
assert(#E.Jungle_Shakeable_04.Pets==1 and E.Jungle_Shakeable_04.Pets[1].PetId=="JungleRedPanda" and E.Jungle_Shakeable_04.Pets[1].DropWeight==4)
assert(E.Jungle_Shakeable_03.Pets[1].PetId=="JungleOcelot" and E.Jungle_Shakeable_03.Pets[1].DropWeight==12)
assert(report.jungle_locked)
local total=0
for _,obj in workspace:GetDescendants() do
 if obj:IsA("Model") and obj:GetAttribute("AuthoredGatherableTree") then
  local biome=obj:GetAttribute("BiomeId") or obj:GetAttribute("Biome")
  if biome=="Jungle" then
   total+=1
   table.insert(report.physical,{path=obj:GetFullName(),attributes=obj:GetAttributes()})
  end
 end
end
report.jungle_physical_count=total report.passed=true report.interaction_qa="No grants or profile writes; physical mapping inspected separately"
return report
