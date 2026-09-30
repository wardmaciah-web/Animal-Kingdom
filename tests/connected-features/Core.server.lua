-- Studio-only pure/model validation. Run as a temporary server Script after startup.
-- No production profile writes; mock restoration is NOT durable datastore testing.
assert(game:GetService('RunService'):IsStudio())
assert(game.ServerScriptService.ServerSource.Server.ProfileService:GetAttribute('AKUseMockProfiles')==true)
local G=game.ReplicatedStorage.Shared.Gameplay
local Eggs=require(G.Definitions.EggDefinitions)
local Families=require(G.Definitions.TreeFamilyDefinitions)
local Pets=require(G.Definitions.PetDefinitions)
local Models=require(G.PetModelResolver)
local Odds=require(G.NormalTreeOdds)
local Records=require(G.SpeciesRecords)
local Streak=require(G.SearchStreak)
local Mastery=require(G.BiomeMastery)
local Contracts=require(G.ContractProgress)
local Rules=require(G.LuckyTreeRules)
local Config=require(G.Definitions.LuckyTreeDefinitions)
local Http=game.HttpService
local result={Assertions=0,Pools={},Models=0}
local function check(value,message)assert(value,message);result.Assertions+=1 end
local seen={}
for _,biome in ipairs({'Meadow','Forest'})do
 check(#Families.ByBiome[biome]==5,'Five stable families')
 for _,family in ipairs(Families.ByBiome[biome])do
  local pool=Eggs[family.Id];local rows=Odds.Calculate(pool);local sum=0
  for _,row in ipairs(rows)do
   check(not seen[row.PetId],'One normal source per species');seen[row.PetId]=true
   check(Models.Resolve(row.PetId)~=nil,'Real model: '..row.PetId);result.Models+=1
   sum+=row.Probability
  end
  check(math.abs(sum-1)<1e-12,'Normalized base odds')
  local lucky=Odds.Calculate(pool,{Luck=2});local luckySum=0;for _,row in ipairs(lucky)do luckySum+=row.Probability end
  check(math.abs(luckySum-1)<1e-12,'Normalized effective odds')
  table.insert(result.Pools,{Id=family.Id,Name=family.DisplayName,Entries=rows})
 end
end
check(result.Models==25,'Actual released roster')
check(Odds.Chance(Eggs.Meadow_Shakeable_01,'MeadowBlossomBunny',{Luck=2})>Odds.Chance(Eggs.Meadow_Shakeable_01,'MeadowBlossomBunny'),'Mixed-rarity Luck improves higher rarity')
local same={Pets={{PetId='MeadowFieldMouse',DropWeight=1},{PetId='MeadowChick',DropWeight=1}}}
check(Odds.Chance(same,'MeadowFieldMouse',{Luck=10})==.5,'Equal-rarity pool unchanged')
for _,family in ipairs(Families.ByBiome.Jungle)do check(#family.PetIds==0,'No fabricated Jungle pool')end
check(not require(G.Definitions.BiomeDefinitions).IsContentReady('Jungle'),'Jungle unreleased')
local data={Pets={},WeightRecords={}}
check(Records.Record(data,{PetId='MeadowChick',Weight=2.4}).First,'First record')
check(Records.Record(data,{PetId='MeadowChick',Weight=3.12}).Previous==2.4,'Heavier record')
check(not Records.Record(data,{PetId='MeadowChick',Weight=3.12}),'Equal record rejected')
check(not Records.Record(data,{PetId='MeadowChick',Weight=1}),'Lighter record rejected')
Records.Seed(data);check(data.WeightRecords.MeadowChick==3.12,'Sold pet record retained')
for _,row in ipairs({{4,0},{5,.05},{9,.05},{10,.1},{19,.1},{20,.15},{100,.15}})do check(Streak.Bonus(row[1])==row[2],'Streak tier')end
check(Streak.Current({Count=25,LastSuccess=100},700)==0,'Inactivity resets at 600 seconds')
check(Streak.Current(nil,150)==0,'Fresh session resets')
check(#Mastery.Goals('Jungle')==0,'No unreleased mastery')
for _,biome in ipairs({'Meadow','Forest'})do
 local total=0;for _,goal in ipairs(Mastery.Goals(biome))do total+=goal.Coins end
 check(total<=Eggs[biome..'_Shakeable_01'].Cost*200*.1,'Mastery pays no more than 10% of 200 searches')
end
local fresh={Pets={},PetIndex={},UnlockedBiomes={Meadow=true}}
local state=Contracts.Ensure(fresh,100,Random.new(1),function()return Http:GenerateGUID(false)end)
check(#state.Entries==3,'Three active contracts')
for _,entry in ipairs(state.Entries)do check(entry.Biome=='Meadow','No locked/unreleased objectives');check(entry.Type~='Garden' and entry.Type~='Collector','No unavailable owned-pet activities')end
for id in pairs(seen)do fresh.PetIndex[id]={Count=1,Variants={Normal=true}}end
for _,entry in ipairs(Contracts.Candidates(fresh))do check(entry.Type~='Discovery','No impossible completed-roster discovery objective')end
for _,row in ipairs({{0,'Secret'},{.049999,'Secret'},{.05,'Coins'},{.449999,'Coins'},{.45,'Luck'},{.999999,'Luck'},{1,'Luck'}})do
 check(Rules.Roll({NextNumber=function()return row[1]end})==row[2],'Exact category boundary')
end
local boostData={Boosts={}}
Rules.AwardBoost(boostData,'Meadow',100);Rules.AwardBoost(boostData,'Forest',200);Rules.AwardBoost(boostData,'Meadow',350)
check(Rules.EffectiveBoost(boostData.Boosts,499).Multiplier==1.55,'Strongest only')
check(Rules.EffectiveBoost(boostData.Boosts,500).Multiplier==1.35,'Weaker resumes')
check(not Rules.EffectiveBoost(boostData.Boosts,650),'Timestamp expiry')
Rules.AwardBoost(boostData,'Meadow',600);check(boostData.Boosts.LuckyTree_Meadow.ExpiresAt==900,'Same boost refresh')
local journal={}
for i=1,Config.ReceiptEvents do local event=Rules.Event(journal,'active-'..i,true,400,100);event.Used=3;event.Receipts={{Committed=true}}end
check(not Rules.Event(journal,'extra-active',true,450,150),'Bounded journal rejects overflow')
check(Rules.Event(journal,'active-1',false).Used==3,'Server hopping cannot reset active event')
check(Rules.Event(journal,'later',true,800,401)~=nil and #journal.LuckyTreeParticipation.Events==1,'Expired settled receipts prune')
local a,b={},{};Rules.Event(a,'same',true,400,100).Used=3
check(Rules.Event(b,'same',true,400,100).Used==0,'Independent profile counters (not a multiplayer test)')
local copied=Http:JSONDecode(Http:JSONEncode(a));check(Rules.Event(copied,'same',false).Used==3,'Mock receipt restore')
local counts={Secret=0,Coins=0,Luck=0};local rng=Random.new(20260929)
for _=1,100000 do local category=Rules.Roll(rng);counts[category]+=1 end
result.Samples=100000;result.Observed=counts;result.AutomaticEnabled=Config.AutomaticEnabled
check(not Config.AutomaticEnabled,'Automatic events intentionally disabled')
script:SetAttribute('Result',Http:JSONEncode(result))
