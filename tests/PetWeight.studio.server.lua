local RS=game.ReplicatedStorage
local Weight=require(RS.Shared.Gameplay.PetWeight)
local Stats=require(RS.Shared.Gameplay.PetStats)
local Sell=require(RS.Shared.Gameplay.SellValueCalculator)
local Locations=require(RS.Shared.Gameplay.PetLocations)
local Definitions=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Migrations=require(RS.Shared.Gameplay.ProfileMigrations)
local function copy(t)local n={};for k,v in pairs(t)do n[k]=type(v)=='table' and copy(v) or v end;return n end
local report={RollsPerSpecies=10000,Distributions={},Curves={},BaseWeights={},Assertions=0}
local function check(v,message)report.Assertions+=1;assert(v,message)end
for _,def in ipairs(Definitions.Ordered)do
 check(type(def.BaseWeight)=='number' and def.BaseWeight>0,'BaseWeight '..def.PetId)
 if def.IsForestPet or def.IsMeadowPet and not def.LegacyOnly then report.BaseWeights[def.PetId]=def.BaseWeight end
end
for i,id in ipairs({'MeadowFieldMouse','MeadowFluffyLop','MeadowPrismAntlerDeer','ForestBlackBearCub','ForestBrownBat','ForestEmeraldWing'})do
 local def=Definitions[id];local rng=Random.new(781+i);local counts={0,0,0,0};local low,high,sum,avgIncome=math.huge,0,0,0
 for _=1,10000 do
  local value=Weight.Roll(def,rng,1);local ratio=value/def.BaseWeight
  check(value>=def.BaseWeight and value<=def.BaseWeight*def.MaxWeightMultiplier and value==value,'Weight bounds '..id)
  local bin=ratio<1.15 and 1 or ratio<1.35 and 2 or ratio<1.75 and 3 or 4;counts[bin]+=1
  low=math.min(low,value);high=math.max(high,value);sum+=ratio
  avgIncome+=Stats.Income({PetId=id,Weight=value})/def.BaseIncome
 end
 check(counts[1]>7500 and counts[1]>counts[2] and counts[2]>counts[3] and counts[3]>counts[4],'Decreasing tail '..id)
 report.Distributions[id]={Minimum=low,Maximum=high,Bands=counts,MeanRatio=sum/10000,MeanIncomeMultiplier=avgIncome/10000}
 local curve={};local previousIncome,previousValue,previousScale=0,0,0
 for _,ratio in ipairs({1,1.25,1.5,2,3})do
  local pet={PetId=id,Weight=def.BaseWeight*ratio,Level=1,Mutation='Normal',Location='Inventory'}
  local income,price,scale=Stats.Income(pet),Sell.Calculate(pet),Weight.Scale(pet,def)
  check(income>=previousIncome and price>=previousValue and scale>previousScale,'Monotonic curves '..id)
  previousIncome,previousValue,previousScale=income,price,scale
  table.insert(curve,{Ratio=ratio,Income=income,SellValue=price,Scale=scale,Quality=Weight.Quality(pet,def)})
 end
 report.Curves[id]=curve
end
local legacy=copy(require(RS.SharedSource.Datas.ProfileTemplate));legacy.DataVersion=3;legacy.MaxEquippedPets=12
for i=1,8 do table.insert(legacy.Pets,{PetId='ForestBadger',UID='legacy-'..i,UniquePetId='legacy-'..i,Level=3,XP=4,Mutation='Golden',Favorite=i==2})end
legacy.EquippedPets={'legacy-1','legacy-2','legacy-3','legacy-4','legacy-5','legacy-6','legacy-7','legacy-8'}
legacy.DisplayedPetIds={'legacy-1'};legacy.PetIndex.ForestBadger={Count=8,Variants={Golden=true}}
legacy.Currencies.Coins=8765;legacy.Pets[8].Weight=24
Migrations.Apply(legacy,function()error('Valid legacy UIDs must survive')end)
check(#legacy.Pets==8 and legacy.Pets[1].UID=='legacy-1' and legacy.Pets[1].Location=='Sanctuary','Preserve display/owned IDs')
check(#legacy.EquippedPets==5 and legacy.MaxEquippedPets==5 and legacy.Pets[7].Location=='Inventory','Five Held / preserve excess')
check(legacy.Pets[1].Weight==12 and legacy.Pets[8].Weight==24 and legacy.Currencies.Coins==8765,'Additive weight/currency migration')
local once=game.HttpService:JSONEncode(legacy)
Migrations.Apply(legacy,function()error('Repeat migration must not change UIDs')end)
check(legacy.Pets[1].Weight==12 and legacy.Pets[8].Weight==24 and legacy.PetDataVersion==1 and legacy.DataVersion==4,'Idempotent weights/version')
local restored=game.HttpService:JSONDecode(once);Migrations.Apply(restored,function()error('Serialized UIDs must persist')end)
check(restored.HeldPetSlots[1]=='legacy-2' and restored.SanctuaryPetSlots[1]=='legacy-1' and restored.Pets[8].Weight==24,'Save/load roundtrip')
local p=restored.Pets[8];local base=Sell.Calculate(p);p.Weight=36;check(Sell.Calculate(p)>base,'Heavier is worth more');base=Sell.Calculate(p);p.Mutation='Rainbow';check(Sell.Calculate(p)>base,'Mutation value')
for _,location in ipairs({'Held','Sanctuary','Garden'})do p.Location=location;check(not Sell.Eligible(p),'Protect '..location)end
p.Location='Inventory';p.Favorite=true;check(not Sell.Eligible(p),'Protect favorites');p.Favorite=false;p.Locked=true;check(not Sell.Eligible(p),'Protect locked')
report.Migration='Eight owned UIDs, previous displays, currencies and individual weights preserved; serialized reload passed.'
-- Simulate resale against all ten active tree prices (weight + existing variants).
local Eggs=require(RS.Shared.Gameplay.Definitions.EggDefinitions)
local Variants=require(RS.Shared.Gameplay.Definitions.VariantDefinitions)
local mutations,totalMutation={},0
for id,variant in pairs(Variants.Mutations)do
 if variant.Weight>0 then totalMutation+=variant.Weight;table.insert(mutations,{Id=id,Chance=variant.Weight})end
end
table.sort(mutations,function(a,b)return a.Id<b.Id end)
report.Resale={}
for id,egg in pairs(Eggs)do
 if not egg.CanonicalPool then continue end
 local rng=Random.new(853+egg.Tier);local totalDrop=0;local sum,profit=0,0
 for _,entry in ipairs(egg.Pets)do totalDrop+=entry.DropWeight end
 for _=1,10000 do
  local draw=rng:NextNumber()*totalDrop;local species
  for _,entry in ipairs(egg.Pets)do draw-=entry.DropWeight;if draw<=0 then species=entry.PetId;break end end
  local def=Definitions[species];draw=rng:NextNumber()*totalMutation;local mutation='Normal'
  for _,entry in ipairs(mutations)do draw-=entry.Chance;if draw<=0 then mutation=entry.Id;break end end
  local price=Sell.Calculate({PetId=species,Weight=Weight.Roll(def,rng,1),Level=1,Mutation=mutation,Shiny=rng:NextNumber()<Variants.ShinyChance,Prismatic=def.Prismatic or rng:NextNumber()<Variants.PrismaticChance})
  sum+=price;if price>egg.Cost then profit+=1 end
 end
 report.Resale[id]={Samples=10000,Cost=egg.Cost,MeanSellValue=sum/10000,MeanCostRecovered=sum/10000/egg.Cost,ProfitableRolls=profit}
 check(sum/10000<egg.Cost,'Routine search/resale must not generate profit: '..id)
end
return report
