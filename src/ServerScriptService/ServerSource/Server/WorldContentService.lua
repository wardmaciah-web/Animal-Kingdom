-- Bind existing authored trees only. Eggs exist exclusively in hatch presentation.
local RS=game:GetService("ReplicatedStorage")
local Collection=game:GetService("CollectionService")
local Knit=require(RS.Packages.Knit)
local Resolver=require(RS.Shared.Gameplay.AssetResolver)
local Discovery=require(script.Parent.Parent.Utilities.AuthoredTreeDiscovery)
local Biomes=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local World=Knit.CreateService({Name="WorldContentService",Client={}})
function World:RemoveGenerated()
 local removed=0
 for _,object in ipairs(workspace:GetDescendants()) do
  local category=object:GetAttribute("AssetCategory")
  -- The previous generator stamped all its output. Never delete by tree-like names.
  if object:GetAttribute("GameplayGenerated")==true and (category=="Trees" or category=="Resources" or category=="Eggs") then
   object:Destroy();removed+=1
  end
 end
 local runtime=workspace:FindFirstChild("AKGameplayRuntime")
 if runtime and #runtime:GetChildren()==0 then runtime:Destroy() end
 -- Retire legacy world egg interactions, preserving any unmarked authored geometry.
 for _,object in ipairs(Collection:GetTagged("EggStation")) do
  Collection:RemoveTag(object,"EggStation")
  for _,child in ipairs(object:GetDescendants()) do if child:IsA("ProximityPrompt") and child.Name=="EggPrompt" then child:Destroy() end end
 end
 return removed
end
function World:RegisterAuthoredTrees()
 local counts={};for _,biome in ipairs(Biomes.Ordered) do counts[biome.Id]=0 end
 for _,entry in ipairs(Discovery.Scan()) do
  local object=entry.Object
  object:SetAttribute("BiomeId",entry.Biome);object:SetAttribute("ResourceType","Tree")
  object:SetAttribute("AuthoredGatherableTree",true);object:SetAttribute("RespawnTime",20)
  object:SetAttribute("InteractionPosition",entry.InteractionPosition)
  if entry.Biome=="Meadow" then
   local def,issue=require(RS.Shared.Gameplay.Definitions.MeadowTreeDefinitions).Get(object,entry.Biome)
   object:SetAttribute("EggId",def and def.Id or nil)
   if not def then warn("[MeadowTrees] "..issue) end
  elseif entry.Biome=="Forest" then
   local def,issue=require(RS.Shared.Gameplay.Definitions.ForestTreeDefinitions).Get(object,entry.Biome)
   object:SetAttribute("EggId",def and def.Id or nil)
   if not def then warn("[ForestTrees] "..tostring(issue)) end
  elseif entry.Biome=="Jungle" then
   local def,issue=require(RS.Shared.Gameplay.Definitions.TreeFamilyDefinitions).BindJungle(object)
   if not def then warn("[JungleTrees] "..tostring(issue)..": "..object:GetFullName()) end
  else object:SetAttribute("EggId",Biomes[entry.Biome].EggId) end
  Collection:AddTag(object,"GatherableTree");counts[entry.Biome]+=1
 end
 self.Counts=counts
 for _,biome in ipairs(Biomes.Ordered) do
  print("[AuthoredTrees] "..biome.Id..": "..counts[biome.Id])
  if counts[biome.Id]==0 then warn("[AuthoredTrees] No confirmed authored trees found in "..biome.Id.."; no replacements generated") end
 end
 return counts
end
function World:KnitInit() Resolver.EnsureFolders() end
function World:KnitStart() self:RemoveGenerated();self:RegisterAuthoredTrees() end
return World
