-- Run in Studio Edit mode. Uses disposable data and a cloned pure module only.
local source=game.ReplicatedStorage.Shared.Gameplay.GardenProgress
local module=source:Clone();module.Parent=source.Parent
local P=require(module)
local G=require(source.Parent.Definitions.GardenDefinitions)
local H=game:GetService("HttpService")
local function copy(t) return H:JSONDecode(H:JSONEncode(t)) end
local function same(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~="table" then return a==b end
 for k,v in pairs(a) do if not same(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
local report={}
local missing={RecoveryData={}}
P.Migrate(missing)
assert(missing.GardenCrops.Moonmelon==0 and missing.GardenUpgrades.KeenNose==0)
report.MissingFields="PASS"
local data={RecoveryData={},GardenCrops={Carrot=81,FutureCrop=99},GardenUpgrades={KeenNose=2},GardenBoosts={SwiftPaws=1167,LuckySprout=1123,ForagerTea=1207}}
P.Migrate(data);local once=copy(data);P.Migrate(data)
assert(same(once,data) and data.GardenCrops.Carrot==81 and data.GardenCrops.FutureCrop==99)
report.AdditiveIdempotentMigration="PASS"
local invalid={RecoveryData={},GardenCrops={Tomato="bad"},GardenUpgrades={QuickForager="bad"},GardenBoosts={LuckySprout=-3}}
P.Migrate(invalid)
assert(invalid.GardenCrops.Tomato==0 and invalid.RecoveryData.GardenMigration["Crop:Tomato"]=="bad")
assert(invalid.RecoveryData.GardenMigration["Boost:LuckySprout"]==-3)
report.MalformedFieldRecovery="PASS"
local pet={PetId="MeadowBuck",Level=3,Mutation="Leafy",Shiny=true,Prismatic=true}
local original={TripId="offline-expiry-boundaries",UID="audit-only",StartedAt=1000,ReadyAt=1900}
P.Initialize(original,pet,data,1)
local online,offline=copy(original),copy(original)
for t=1001,1900 do P.Advance(online,t) end
P.Advance(offline,1900)
assert(same(online.PendingCrops,offline.PendingCrops))
assert(online.ProcessedCycles==offline.ProcessedCycles)
assert(math.abs(online.PendingHarvest-offline.PendingHarvest)<1e-6)
assert(math.abs(online.PendingXP-offline.PendingXP)<1e-6)
report.OfflineExpiryBoundaries={Result="PASS",Cycles=online.ProcessedCycles,Crops=online.PendingCrops}
local finished=copy(offline);P.Advance(offline,100000)
assert(same(finished,offline));report.NoProgressAfterCompletion="PASS"
report.Durations={};local previous=0
for _,id in ipairs(G.DurationOrder) do
 local t={TripId="duration-check",UID="audit-only",StartedAt=1000,ReadyAt=1000+G.Durations[id].Seconds}
 P.Initialize(t,pet,missing,1);P.Advance(t,t.ReadyAt)
 assert(t.PendingHarvest>previous);previous=t.PendingHarvest
 report.Durations[id]={Cycles=t.ProcessedCycles,Harvest=t.PendingHarvest}
end
local upgrades,boosts={},{}
for _,id in ipairs(G.UpgradeOrder) do upgrades[id]=5 end
for _,id in ipairs(G.SupplyOrder) do boosts[id]=9999 end
local mods=P.Modifiers(upgrades,boosts,1000,150)
local weights=P.Weights(mods);local total=0
for _,w in ipairs(weights) do total+=w end
assert(mods.Radius==44 and mods.Speed<=1.75 and mods.Yield<=2 and weights[5]/total<=.080001)
report.Caps={Radius=mods.Radius,Speed=mods.Speed,Yield=mods.Yield,Moonmelon=weights[5]/total}
assert(P.Modifiers({},{LuckySprout=1600},1000,1).Luck==P.Modifiers({},{LuckySprout=2200},1000,1).Luck)
report.ExtendedPotionDoesNotDoubleLuck="PASS"
local seen={}
for i=1,20 do
 local _,node=P.Roll({Seed=19238},i,mods)
 if seen[node] then assert((i-seen[node])*G.CycleSeconds/mods.Speed>=G.Crops.Moonmelon.Regrow) end
 seen[node]=i
end
report.CropRegrowthBeforeNodeReuse="PASS"
local base=P.Modifiers({},{},0,1);local counts=P.EmptyCrops()
for i=1,10000 do local crop=P.Roll({Seed=314159},i,base);counts[crop]+=1 end
report.BaseWeights=P.Weights(base);report.Events10000=counts
module:Destroy()
return report
