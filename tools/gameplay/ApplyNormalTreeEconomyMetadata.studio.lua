-- Idempotent Edit-mode companion to the synced source changes. Never publishes.
-- The current authored place owns this Meadow registration Script outside src.
assert(game:GetService('RunService'):IsStudio() and not game:GetService('RunService'):IsRunning(),'Edit mode only')
local scriptInstance=assert(game.ServerScriptService:FindFirstChild('AK_NewMeadowTreeRuntimeRegister'))
local old='.. tostring(def.Cost)'
local replacement='.. require(RS.Shared.Gameplay.PetNumberFormat).Number(def.Cost)'
local source=scriptInstance.Source
local a,b=source:find(old,1,true)
if a then scriptInstance.Source=source:sub(1,a-1)..replacement..source:sub(b+1)
else assert(source:find(replacement,1,true),'Unexpected authored Meadow price display')end
local removed=0
for _,tree in ipairs(game.CollectionService:GetTagged('GatherableTree'))do
 if tree:IsDescendantOf(workspace) and (tree:GetAttribute('BiomeId')=='Meadow' or tree:GetAttribute('BiomeId')=='Forest') then
  if tree:GetAttribute('SearchCost')~=nil then tree:SetAttribute('SearchCost',nil);removed+=1 end
 end
end
print('Normal tree canonical-price metadata ready; removed stale per-copy prices:',removed)
