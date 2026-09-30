-- Live service calls with a replaced, disposable mock/copy profile. No production writes.
local RS=game.ReplicatedStorage;local H=game.HttpService;local K=require(RS.Packages.Knit)
K.OnStart():await();assert(game:GetService('RunService'):IsStudio())
assert(game.ServerScriptService.ServerSource.Server.ProfileService:GetAttribute('AKUseMockProfiles')==true)
local p=game.Players:GetPlayers()[1]or game.Players.PlayerAdded:Wait()
local profiles=K.GetService('ProfileService');profiles:WaitUntilProfileLoaded(p)
local profile=profiles.Profiles[p];assert(profile.is_mock)
local original=profile.Data;local report={Kind='Stage2 mock service simulation',Assertions=0,Failures={}}
local function check(v,m)report.Assertions+=1;if not v then table.insert(report.Failures,m)end end
local ok,err=xpcall(function()
 local d=H:JSONDecode(H:JSONEncode(require(RS.SharedSource.Datas.ProfileTemplate)))
 require(RS.Shared.Gameplay.ProfileMigrations).Apply(d,function()return H:GenerateGUID(false)end)
 d.DailyChallenges={Entries={Hatch5={Progress=4,Claimed=false},Coins5000={Progress=5000,Claimed=false}}}
 d.WeeklyChallenges={PeriodStart=0,Entries={Hatch100={Progress=99,Claimed=false},Coins250000={Progress=250000,Claimed=true}}}
 d.TutorialCompleted=true;d.UnlockedBiomes.Forest=true;profile.Data=d
 local c=K.GetService('ChallengeService');c:Ensure(p);local a=c.Activities;a:Ensure(p)
 check(d.Activities.LegacyDaily.Entries.Hatch5.Progress==4,'partial legacy daily preserved')
 c:Track(p,'Hatch',1,'Meadow')
 check(d.Activities.LegacyWeekly.Entries.Hatch100.Progress==100,'stale pre-migration Weekly progress can finish')
 local weeklyBalance=d.Currencies.Coins;check(c:Claim(p,'LegacyWeekly','Hatch100'),'retained Weekly claim succeeds')
 c:Claim(p,'LegacyWeekly','Hatch100');check(d.Currencies.Coins==weeklyBalance+50000,'retained Weekly pays original reward once')
 check(d.Activities.LegacyWeekly.Entries.Coins250000.Claimed,'already-claimed Weekly preserved without paying twice')
 check(d.WeeklyChallenges.Entries.Hatch100.Progress==1,'current Weekly has distinct period progress')
 check(d.Activities.LegacyDaily.Entries.Hatch5.Progress==5,'retained legacy can finish')
 local balance=d.Currencies.Coins;check(c:Claim(p,'LegacyDaily','Hatch5'),'legacy claim succeeds')
 check(d.Currencies.Coins==balance+1000,'legacy pays exact old reward')
 c:Claim(p,'Daily','Hatch5');check(d.Currencies.Coins==balance+1000,'old alias cannot pay legacy twice')
 local pet=K.GetService('PetService'):Create('MeadowFieldMouse','Normal',false,false,1)
 K.GetService('PetService'):Adopt(d,pet);K.GetService('PetService'):Discover(d,pet);d.ActiveHeldPetUID=pet.UID
 check(a:Mission(p,pet.UID,'HeldSearch'),'UID mission accepted')
 for i=1,3 do c:Committed(p,'Search','fixture'..i,{UID=pet.UID,PetId=pet.PetId,FamilyId='Meadow_Shakeable_01',Biome='Meadow',Rarity=1,Ratio=1,Weight=.1,HeldUID='other'})end
 check(d.Activities.Journey.Step==2,'journey advances exactly one step')
 check(d.Activities.Mission.Progress==0,'other active Held UID gets no mission credit')
 c:Committed(p,'Search','fixture3',{UID=pet.UID,FamilyId='Meadow_Shakeable_01',Biome='Meadow',Rarity=7,Ratio=3,HeldUID=pet.UID})
 check(d.Activities.BiomeGoals.Meadow.Entries[1].Progress==3,'duplicate committed identity ignored')
 for i=4,11 do c:Committed(p,'Search','fixture'..i,{UID=pet.UID,PetId=pet.PetId,FamilyId='Meadow_Shakeable_01',Biome='Meadow',Rarity=3,Ratio=1.25,Weight=.1,HeldUID=pet.UID})end
 check(d.Activities.Mission.Progress==8,'only exact UID earns held-search credit')
 local missionId=d.Activities.Mission.Id;local oldXP=pet.XP;check(a:ClaimMission(p,missionId),'mission XP claim')
 local level,xp=pet.Level,pet.XP;a:ClaimMission(p,missionId);check(pet.Level==level and pet.XP==xp,'XP claim replay is harmless')
 check(not a:Mission(p,pet.UID,'HeldSearch'),'same pet daily mission limit')
 local set=d.Activities.BiomeGoals.Meadow;local coins=d.Currencies.Coins
 check(a:Claim(p,set.Id),'three biome goals claim');check(d.Currencies.Coins==coins+200,'biome set pays once')
 a:Claim(p,set.Id);check(d.Currencies.Coins==coins+200,'biome claim replay harmless')
 c:Committed(p,'Collect','collection1',{Amount=100});check(d.Activities.Journey.Step==3,'actual collection event advances journey')
 c:Committed(p,'Garden','trip1',{UID=pet.UID});check(d.Activities.Journey.Step==4,'settled expedition advances journey')
 c:Committed(p,'Search','fixture12',{UID=pet.UID,PetId=pet.PetId,FamilyId='Meadow_Shakeable_01',Biome='Meadow',Rarity=3,Ratio=1,Weight=.1,HeldUID=pet.UID})
 check(d.Activities.Journey.Step==5,'journey final reward ready')
 d.Currencies.Coins=9e15
 check(not a:Claim(p,d.Activities.Journey.Id) and not d.Activities.Journey.Claimed,'currency cap retains claim')
 d.Currencies.Coins=1000;check(a:Claim(p,d.Activities.Journey.Id),'retained claim succeeds after cap cleared')
 local restored=H:JSONDecode(H:JSONEncode(d));require(RS.Shared.Gameplay.KingdomProgress).Ensure(restored)
 check(restored.Pets[1].UID==pet.UID and restored.Pets[1].Weight==pet.Weight,'mock serialization preserves exact UID and weight')
 check(restored.Activities.Journey.Claimed and restored.Activities.Receipts[missionId]~=nil,'claims survive mock serialization')
end,debug.traceback)
profile.Data=original
K.GetService('PetService'):Publish(p);K.GetService('ChallengeService'):Ensure(p);K.GetService('ChallengeService').Activities:Ensure(p);K.GetService('PlayerDataService'):Publish(p,'Activities','Currencies','Contracts','DailyChallenges','WeeklyChallenges')
if not ok then table.insert(report.Failures,err)end
report.Passed=#report.Failures==0;workspace:SetAttribute('AKActivitiesGoals',H:JSONEncode(report))
