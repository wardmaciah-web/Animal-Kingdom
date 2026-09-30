local Config=require(script.Parent.Definitions.LuckyTreeDefinitions)
local Weighted=require(script.Parent.WeightedRandom)
local M={}
function M.Roll(rng)return Weighted.Roll(Config.Categories,rng).Id end -- deliberately no Luck argument
function M.EffectiveBoost(boosts,now)
 local best
 for _,boost in pairs(boosts or {})do
  if type(boost)=="table" and boost.Group=="LuckyTree" and boost.Key=="Luck" and type(boost.ExpiresAt)=="number" and boost.ExpiresAt>now and type(boost.Multiplier)=="number"then
   if not best or boost.Multiplier>best.Multiplier or boost.Multiplier==best.Multiplier and boost.ExpiresAt>best.ExpiresAt then best=boost end
  end
 end
 return best
end
function M.AwardBoost(data,biome,now)
 local def=assert(Config.Biomes[biome]);data.Boosts=data.Boosts or {}
 data.Boosts["LuckyTree_"..biome]={Key="Luck",Group="LuckyTree",Biome=biome,Multiplier=def.LuckMultiplier,ExpiresAt=now+Config.BoostSeconds}
 return data.Boosts["LuckyTree_"..biome]
end
function M.Event(data,id,create,endsAt,timestamp)
 data.LuckyTreeParticipation=type(data.LuckyTreeParticipation)=="table" and data.LuckyTreeParticipation or {Version=1,Events={}}
 local journal=data.LuckyTreeParticipation;journal.Version=1;journal.Events=journal.Events or {}
 for _,event in ipairs(journal.Events)do if event.EventId==id then return event end end
 if not create then return nil end
 -- Never evict a still-active server event: hopping servers and returning must
 -- not restore its tries. Full journals reject new participation until a slot expires.
 timestamp=timestamp or workspace:GetServerTimeNow()
 for i=#journal.Events,1,-1 do
  local old=journal.Events[i];local settled=true
  for _,receipt in ipairs(old.Receipts)do if not receipt.Committed then settled=false;break end end
  if settled and (old.EndsAt or math.huge)<=timestamp then table.remove(journal.Events,i)end
 end
 if #journal.Events>=Config.ReceiptEvents then return nil,"Your recent Lucky events are still active. Try again when one ends."end
 local event={EventId=id,EndsAt=endsAt or timestamp+Config.Lifetime,Used=0,Receipts={}};table.insert(journal.Events,event);return event
end
return M
