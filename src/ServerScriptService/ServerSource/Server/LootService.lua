local RS=game:GetService("ReplicatedStorage")
local Knit=require(RS.Packages.Knit)
local Weighted=require(RS.Shared.Gameplay.WeightedRandom)
local Tables=require(RS.Shared.Gameplay.Definitions.DropTables)
local Loot=Knit.CreateService({Name="LootService",Client={}})
local rng=Random.new()
function Loot:Roll(entries,weight) return Weighted.Roll(entries,rng,weight) end
function Loot:Reward(player,tableId,multiplier,reason)
 local entries=Tables[tableId];if not entries then return false end
 local drop=self:Roll(entries);if not drop then return false end
 local data=Knit.GetService("PlayerDataService"):Get(player);if not data then return false end
 local amount=math.max(1,math.floor(rng:NextInteger(drop.Min,drop.Max)*(multiplier or 1)))
 if drop.Currency then
  local currencyMultiplier=Knit.GetService("ModifierService"):Get(player,drop.Currency)
  amount=math.max(1,math.floor(amount*currencyMultiplier))
  Knit.GetService("EconomyService"):Add(player,drop.Currency,amount,reason or "Gather")
 end
 if drop.Coins then Knit.GetService("EconomyService"):Add(player,"Coins",math.floor(drop.Coins*(multiplier or 1)*Knit.GetService("ModifierService"):Get(player,"Coins")),reason or "Gather") end
 if drop.ItemId then
  data.Items[drop.ItemId]=(data.Items[drop.ItemId] or 0)+amount
  Knit.GetService("PlayerDataService"):Publish(player,"Items")
 end
 if drop.PetId then Knit.GetService("PetService"):Grant(player,drop.PetId,"Normal") end
 return true,drop,amount
end
return Loot
