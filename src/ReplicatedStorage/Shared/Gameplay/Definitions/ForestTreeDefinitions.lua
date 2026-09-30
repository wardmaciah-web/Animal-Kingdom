-- Base-family order comes from generate_v5_assets.py CURRENT.Forest, not alphabetic order.
-- Three later art variants share an existing reward tier; they are not extra economic tiers.
local Eggs=require(script.Parent.EggDefinitions)
local M={Ordered={},Families={Tree_Oak_1=1,Tree_Oak_2=2,Tree_Cedar_1=3,Tree_Pine_1=4,Tree_Pine_2=5,
 PineTree_3=3,tree_pineRoundA=4,Willow_5=5,
 ForestTreeType1=1,ForestTreeType2=2,ForestTreeType3=3,ForestTreeType4=4,ForestTreeType5=5}}
for tier=1,5 do local id=string.format("Forest_Shakeable_%02d",tier);M[id]=Eggs[id];table.insert(M.Ordered,Eggs[id]) end
function M.Get(tree,biome)
 if biome~="Forest" then return nil,"Not a Forest tree" end
 local source=tree:GetAttribute("SourceAssetName") or tree:GetAttribute("TreeType")
 local tier=M.Families[source]
 local id=tree:GetAttribute("RewardPoolId") or tree:GetAttribute("ShakeableId")
 if id then
  local def=M[id]
  if not def or def.Tier~=tier then return nil,"Forest tree reward mapping does not match its registered family: "..tree:GetFullName() end
  return def
 end
 if not tier then return nil,"Forest tree family is not registered: "..tree:GetFullName() end
 return M[string.format("Forest_Shakeable_%02d",tier)]
end
return M
