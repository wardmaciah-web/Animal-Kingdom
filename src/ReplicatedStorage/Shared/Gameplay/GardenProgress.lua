-- Pure, deterministic Garden accounting. No network, models, clocks or random globals.
local G=require(script.Parent.Definitions.GardenDefinitions)
local Pets=require(script.Parent.Definitions.PetDefinitions)
local Variants=require(script.Parent.Definitions.VariantDefinitions)
local P={}
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
local function archive(value,seen)
 local kind=typeof(value)
 if kind=="string" or kind=="boolean" or (kind=="number" and finite(value)) then return value end
 if kind~="table" then return {InvalidType=kind,Description=tostring(value)} end
 seen=seen or {};if seen[value] then return {InvalidType="cycle"} end;seen[value]=true
 local copy={};for k,v in pairs(value) do copy[tostring(k)]=archive(v,seen) end;seen[value]=nil;return copy
end
local function count(n) return finite(n) and math.clamp(math.floor(n),0,9e15) or 0 end
function P.EmptyCrops()
 local out={};for _,id in ipairs(G.CropNames) do out[id]=0 end;return out
end
function P.Migrate(data)
 local recovery=data.RecoveryData.GardenMigration or {};data.RecoveryData.GardenMigration=recovery
 for _,key in ipairs({"GardenCrops","GardenUpgrades","GardenBoosts"}) do
  if type(data[key])~="table" then
   if data[key]~=nil then recovery[key]=recovery[key] or archive(data[key]) end
   data[key]={}
  end
 end
 for _,id in ipairs(G.CropNames) do
  local value=data.GardenCrops[id]
  if value~=nil and (not finite(value) or value<0 or value%1~=0) then recovery["Crop:"..id]=recovery["Crop:"..id] or archive(value) end
  data.GardenCrops[id]=count(value)
 end
 for _,id in ipairs(G.UpgradeOrder) do
  local v=data.GardenUpgrades[id]
  if v~=nil and (not finite(v) or v<0 or v>5 or v%1~=0) then recovery["Upgrade:"..id]=recovery["Upgrade:"..id] or archive(v) end
  data.GardenUpgrades[id]=math.min(5,count(v))
 end
 for _,id in ipairs(G.SupplyOrder) do
  local v=data.GardenBoosts[id]
  if v~=nil and (not finite(v) or v<0 or v%1~=0) then recovery["Boost:"..id]=recovery["Boost:"..id] or archive(v) end
  data.GardenBoosts[id]=count(v)
 end
end
function P.Power(pet)
 local def=Pets[pet.PetId];local mutation=Variants.Mutations[pet.Mutation]
 return math.clamp(G.RarityMult(def and def.Rarity)*G.LevelMult(pet.Level or 1)*(mutation and mutation.Power or 1)*(pet.Shiny and 1.5 or 1)*(pet.Prismatic and 2 or 1),1,150)
end
function P.Modifiers(upgrades,boosts,at,power)
 local m={Luck=math.min(.3,math.max(0,(power or 1)-1)*.015)+(upgrades.RareCropAlmanac or 0)*.04,Yield=(upgrades.BountifulBeds or 0)*.05,Speed=(upgrades.QuickForager or 0)*.05,Harvest=1+(upgrades.HarvestSatchel or 0)*.05,XP=0,Starberry=0,Moonmelon=0,Radius=24+(upgrades.KeenNose or 0)*4}
 for id,def in pairs(G.Supplies) do if (boosts[id] or 0)>at then m[def.Stat]+=def.Bonus end end
 m.Luck=math.min(m.Luck,1.1);m.Yield=1+math.min(m.Yield,1);m.Speed=1+math.min(m.Speed,.75);m.XP=1+math.min(m.XP,.25)
 return m
end
function P.Weights(m)
 local weights={40,30,18,9*(1+m.Luck)*(1+m.Starberry),3*(1+m.Luck)*(1+m.Moonmelon)}
 -- Even the complete stack cannot make Moonmelon exceed 8% per event.
 local other=weights[1]+weights[2]+weights[3]+weights[4]
 weights[5]=math.min(weights[5],other*.08/.92)
 return weights
end
local function random(seed,cycle,salt)
 local n=(seed+cycle*104729+salt*15485863)%2147483647
 n=(n*48271)%2147483647;n=(n*48271)%2147483647
 return n/2147483647
end
function P.Roll(trip,cycle,m)
 local weights=P.Weights(m);local total=0;for _,w in ipairs(weights) do total+=w end
 -- Rotate five crop nodes: even at capped speed, each node has >14s to regrow.
 local roll=random(trip.Seed,cycle,1)*total
 for i,w in ipairs(weights) do roll-=w;if roll<0 then return G.CropNames[i],1+((cycle-1+trip.Seed%5)%5) end end
 return "Carrot",1
end
function P.Initialize(trip,pet,data,slot)
 if trip.ForagingVersion==1 then return end
 trip.ForagingVersion=1;trip.SlotId=slot;trip.PetInstanceId=trip.UID
 trip.EndsAt=trip.ReadyAt;trip.LastProcessedAt=trip.StartedAt
 local seed=17;for i=1,#trip.TripId do seed=(seed*31+string.byte(trip.TripId,i))%2147483647 end
 trip.Seed=seed;trip.ProcessedCycles=0;trip.CycleWork=0;trip.QuantityCarry=0
 trip.PendingCrops=P.EmptyCrops();trip.PendingHarvest=0;trip.PendingXP=0
 trip.Power=P.Power(pet);trip.Upgrades=table.clone(data.GardenUpgrades);trip.Boosts=table.clone(data.GardenBoosts)
end
function P.Advance(trip,now)
 local finish=math.min(now,trip.ReadyAt)
 local t=trip.LastProcessedAt;local before=trip.ProcessedCycles
 if finish<=t then return false end
 -- Split at boost expiry, so a boost never applies to elapsed time after it expires.
 while t<finish do
  local edge=finish
  for _,expiration in pairs(trip.Boosts) do if expiration>t and expiration<edge then edge=expiration end end
  local m=P.Modifiers(trip.Upgrades,trip.Boosts,t,trip.Power)
  local dt=edge-t;local cycleSeconds=G.CycleSeconds/m.Speed
  local available=trip.CycleWork+dt/cycleSeconds
  local cycles=math.floor(available+1e-8)
  for i=1,cycles do
   trip.ProcessedCycles+=1
   local crop,node=P.Roll(trip,trip.ProcessedCycles,m)
   local quantity=math.sqrt(trip.Power)*m.Yield+trip.QuantityCarry
   local amount=math.floor(quantity+1e-8);trip.QuantityCarry=quantity-amount
   trip.PendingCrops[crop]+=amount
   trip.LastHarvest={Crop=crop,Node=node,Amount=amount,At=t+(i-trip.CycleWork)*cycleSeconds,Cycle=trip.ProcessedCycles}
  end
  trip.CycleWork=math.max(0,available-cycles)
  trip.PendingHarvest+=dt/60*8*trip.Power*m.Harvest*math.clamp(trip.KingdomFertilizer or 1,1,1.15)
  trip.PendingXP+=dt/60*10*m.XP
  t=edge
 end
 trip.LastProcessedAt=finish
 return trip.ProcessedCycles~=before or finish>=trip.ReadyAt
end
function P.Next(trip,now)
 local m=P.Modifiers(trip.Upgrades,trip.Boosts,now,trip.Power)
 local crop,node=P.Roll(trip,trip.ProcessedCycles+1,m)
 return {Crop=crop,Node=node,At=trip.LastProcessedAt+(1-trip.CycleWork)*G.CycleSeconds/m.Speed,Radius=m.Radius}
end
function P.Breakdown(crops)
 local out={};for _,id in ipairs(G.CropNames) do table.insert(out,{Name=id,Amount=crops[id] or 0}) end;return out
end
return P
