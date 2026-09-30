-- Resolves existing authored reward tiers; physical copies are not new tiers.
local Eggs=require(script.Parent.EggDefinitions)
local M={Ordered={}}
for tier=1,5 do local id=string.format("Meadow_Shakeable_%02d",tier);M[id]=Eggs[id];table.insert(M.Ordered,Eggs[id]) end
function M.Get(tree,biome)
 if biome~="Meadow" then return nil,"Not a Meadow tree" end
 local tier=tree:GetAttribute("TreeTier")
 local id=tree:GetAttribute("RewardPoolId") or tree:GetAttribute("ShakeableId")
 local def=type(id)=="string" and M[id]
 if not def or def.Tier~=tier then return nil,"Meadow tree has no valid authored tier: "..tree:GetFullName() end
 return def
end
return M

