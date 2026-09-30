-- A single weighted selection algorithm, with injectable RNG for deterministic tests.
local Weighted={}
function Weighted.Roll(entries,rng,weightFn)
 local total,weights=0,{}
 for i,entry in ipairs(entries) do
  local weight=weightFn and weightFn(entry) or entry.DropWeight or entry.Weight -- legacy non-pet loot
  if type(weight)~="number" or weight~=weight or weight<0 or weight==math.huge then error("Invalid drop weight") end
  weights[i]=weight;total+=weight
 end
 if total<=0 then return nil end
 local roll=rng:NextNumber()*total
 for i,entry in ipairs(entries) do roll-=weights[i];if roll<0 then return entry end end
 for i=#entries,1,-1 do if weights[i]>0 then return entries[i] end end
 return nil
end
return Weighted
