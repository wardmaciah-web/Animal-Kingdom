local M={RotationSeconds=600,Distance=16,Order={"Clover","Heavy","Search","Blessing","Fertilizer","Mystery"},Discount=.25}
M.Clover={Name="Lucky Clover",Currency="Coins",Price=250,Seconds=300,Limit=1,Key="Luck",Multiplier=1.10,Effect="×1.10 normal-search Luck for 5 minutes. Rare odds are normalized; this is not +10 percentage points."}
M.Heavy={Name="Heavy Charm",Currency="Coins",Price=250,Seconds=300,Limit=1,Key="WeightBias",Bias=.15,Effect="For 5 minutes, higher weight bands gain 15% weighting per band step. New rolls only; no guaranteed heavy pet."}
M.Search={Name="Search Charm",Currency="Coins",Price=100,Seconds=300,Limit=1,Key="SearchRecovery",Multiplier=.70,Effect="30% shorter personal recovery after the normal reveal for 5 minutes (1.5s → 1.05s). Shared tree regrowth stays unchanged."}
M.Blessing={Name="Sanctuary Blessing",Currency="FriendshipTokens",Price=20,Seconds=600,Limit=1,Key="SanctuaryIncome",Multiplier=1.15,Effect="+15% newly accrued Sanctuary income for 10 minutes, including supported offline time. Saved coins are unchanged."}
M.Fertilizer={Name="Garden Fertilizer",Currency="FriendshipTokens",Price=8,Limit=1,Key="GardenHarvest",Multiplier=1.15,Effect="+15% Harvest on your next successfully started Garden expedition. One pending use maximum."}
M.Stacking="Different effects combine. An already-active effect cannot be bought again: no refresh, extension or duplicate Mystery stack. Fertilizer holds one pending use."
function M.Rotation(now)return math.floor(now/M.RotationSeconds)end
function M.Offers(rotation)
 local out={}
 for i=1,5 do local id=M.Order[i];local d=M[id];table.insert(out,{Id=id,EffectId=id,Price=d.Price,Currency=d.Currency,Limit=d.Limit})end
 -- Identical stock across servers for this UTC bucket. A deterministic PRNG
 -- chooses visible stock; it never rolls a reward after the player pays.
 local chosen=Random.new(rotation%2147483647):NextInteger(1,5);local id=M.Order[chosen];local d=M[id]
 table.insert(out,{Id="Mystery",EffectId=id,Price=math.max(1,math.floor(d.Price*(1-M.Discount))),OriginalPrice=d.Price,Currency=d.Currency,Limit=1})
 return out
end
return M
