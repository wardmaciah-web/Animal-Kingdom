-- Focused mock Play regression for transaction-time Held identity and route/receipt edges.
local RS=game.ReplicatedStorage;local H=game.HttpService;local K=require(RS.Packages.Knit);K.OnStart():await()
local p=game.Players:GetPlayers()[1]or game.Players.PlayerAdded:Wait();local profiles=K.GetService('ProfileService');profiles:WaitUntilProfileLoaded(p)
local profile=profiles.Profiles[p];assert(game:GetService('RunService'):IsStudio()and profile.is_mock)
local original=profile.Data;local root=p.Character.HumanoidRootPart;local cf,anchored=root.CFrame,root.Anchored
local result={Kind='Mock Studio Play edge transactions and mock ProfileStore session restoration',Assertions=0,Failures={}}
local function check(v,m)result.Assertions+=1;assert(v,m)end
local function waitFor(f,seconds,label)local deadline=os.clock()+seconds;repeat if f()then return end;task.wait(.1)until os.clock()>deadline;error(label)end
local c=K.GetService('ChallengeService');local a=c.Activities;local world=a.World;local nextHot=world.NextHot
local ok,err=xpcall(function()
 local d=H:JSONDecode(H:JSONEncode(require(RS.SharedSource.Datas.ProfileTemplate)));require(RS.Shared.Gameplay.ProfileMigrations).Apply(d,function()return H:GenerateGUID(false)end)
 d.TutorialCompleted=true;d.Currencies.Coins=100000;d.Currencies.FriendshipTokens=100;d.UnlockedBiomes.Forest=true;profile.Data=d;c:Ensure(p);a:Ensure(p);world:ClearHot();world.NextHot=workspace:GetServerTimeNow()+1000
 local pets=K.GetService('PetService');local rsrc=K.GetService('ResourceService');local egg=K.GetService('EggService');local routes=a.Routes
 local owned={};for i=1,2 do local pet=pets:Create('MeadowFieldMouse','Normal',false,false,1);pets:Adopt(d,pet);table.insert(owned,pet)end
 pets:Publish(p);check(pets:Equip(p,owned[1].UID,true),'held mission pet selected');check(a:Mission(p,owned[1].UID,'HeldSearch'),'held mission started')
 local candidates=routes:Candidates('Meadow','Meadow_Shakeable_01');local first=candidates[1];root.Anchored=true;root.CFrame=CFrame.new(first.Record.InteractionPosition+Vector3.new(8,0,0))
 waitFor(function()return egg:CheckTreeHatch(p,first.Tree)end,20,'assets ready')
 local count=#d.Pets;check(rsrc:Gather(p,first.Tree),'accepted search while first pet held');check(pets:Equip(p,owned[2].UID,true),'change active UID before commit')
 waitFor(function()return #d.Pets==count+1 end,6,'first search commit');check(d.Activities.Mission.Progress==0,'mission uses active UID at committed outcome')
 task.wait(4);local second=candidates[2];root.CFrame=CFrame.new(second.Record.InteractionPosition+Vector3.new(8,0,0));check(rsrc:Gather(p,second.Tree),'second accepted search');check(pets:Equip(p,owned[1].UID,true),'restore mission UID before second commit')
 waitFor(function()return #d.Pets==count+2 end,6,'second commit');check(d.Activities.Mission.Progress==1,'exact current UID gets one credit')
 -- Full storage rejects the whole search before consuming coins or entitlement.
 for _=#d.Pets+1,6 do local pet=pets:Create('MeadowChick','Normal',false,false,1);pets:Adopt(d,pet)end;d.PetStorageCapacity=1;pets:Publish(p)
 task.wait(4);local third=candidates[3];root.CFrame=CFrame.new(third.Record.InteractionPosition+Vector3.new(8,0,0));local coins=d.Currencies.Coins;local n=#d.Pets
 d.Activities.Finale={RunId='capacity-final',FamilyId='Meadow_Shakeable_01',ExpiresAt=workspace:GetServerTimeNow()+60}
 check(not rsrc:Gather(p,third.Tree),'full Held and Inventory reject search');check(d.Currencies.Coins==coins and #d.Pets==n and d.Activities.Finale~=nil,'full storage consumes neither coins, pet nor entitlement')
 d.PetStorageCapacity=50;d.Activities.Finale=nil
 waitFor(function()local available=0;for _,candidate in ipairs(candidates)do if candidate.Record.State=='AVAILABLE'then available+=1 end end;return available>=5 end,25,'five route copies naturally regrow')
 check(routes:Accept(p,'Rush:Speed','Meadow'),'retarget test route accepted');local route=d.Activities.Route;local target=route.Targets[1];local saved=target.TreeId;local record
 for tree,r in pairs(rsrc:GetRecords())do if tree:GetAttribute('ActivityTreeId')==saved then record=r;break end end
 local oldState=record.State;record.State='RESPAWNING';routes:Tick(p,d,d.Activities)
 waitFor(function()return target.TreeId~=saved end,10,'equivalent route target replacement');record.State=oldState
 check(route.Progress==0 and target.FamilyId=='Meadow_Shakeable_01','retarget preserves progress and family')
 local before=#d.Pets;route.EndsAt=workspace:GetServerTimeNow()-1;a:Ensure(p);check(d.Activities.Route==nil and #d.Pets==before,'activity timeout keeps earned pets')
 check(routes:Accept(p,'PawFinale','Meadow'),'paid finale disclosed and accepted');route=d.Activities.Route
 for i=1,6 do root.CFrame=CFrame.new(Vector3.new(unpack(route.Targets[i].Position))+Vector3.new(0,3,0));check(routes:Discover(p,route.Id,i),'finale paw sequence '..i)end
 check(d.Activities.Finale and route.Progress==6 and not route.Completed,'six paws arm one paid finale')
 local target=route.Targets[7];local tree,record
 waitFor(function()for obj,r in pairs(rsrc:GetRecords())do if obj:GetAttribute('ActivityTreeId')==target.TreeId then tree,record=obj,r end end;root.CFrame=CFrame.new(Vector3.new(unpack(target.Position))+Vector3.new(0,3,0));return record.State=='AVAILABLE'and egg:CheckTreeHatch(p,tree)end,30,'finale target ready')
 local coins=d.Currencies.Coins;d.Currencies.Coins=0;check(not rsrc:Gather(p,tree),'unaffordable finale rejected');check(d.Activities.Finale~=nil,'failed finale keeps entitlement');d.Currencies.Coins=coins;task.wait(.4)
 local n=#d.Pets;check(rsrc:Gather(p,tree),'paid finale search accepted');check(record.Claim.Search.WeightBias==.1,'finale weight bias used once')
 waitFor(function()return #d.Pets==n+1 end,6,'finale award');check(d.Activities.Finale==nil and route.Completed,'successful search consumes benefit and completes route');check(d.Currencies.Coins==coins-250,'finale normal price charged once');check(a:Claim(p,route.Id),'bounded finale reward claim')
 -- Existing ProfileStore mock sessions persist stock/claims/UIDs and inbox data.
 local store=require(game.ServerScriptService.ServerSource.Externals.ProfileStore).New('OriginalData1',require(RS.SharedSource.Datas.ProfileTemplate)).Mock
 local key='Player_987650012';local saved=store:StartSessionAsync(key);check(saved and saved.is_mock,'isolated mock persistence session')
 saved.Data=H:JSONDecode(H:JSONEncode(d));saved.Data.KingdomShop.Rotations['test']={Counts={Clover=1},Receipts={copy={OfferId='Clover'}}};saved:EndSession();task.wait(.4)
 local restored=store:StartSessionAsync(key);check(restored~=nil,'mock session reopens');check(restored.Data.Pets[1].UID==d.Pets[1].UID and restored.Data.Pets[1].Weight==d.Pets[1].Weight,'UID/weight survive actual mock profile save/load');check(restored.Data.KingdomShop.Rotations.test.Counts.Clover==1 and restored.Data.Activities.Receipts[route.Id]~=nil,'purchases and activity claims survive mock sessions');restored:EndSession()
 local offline={Kind='KingdomCoop',Id='OfflineFixture:'..H:GenerateGUID(false),Coins=200,Tokens=3,CreatedAt=workspace:GetServerTimeNow(),ExpiresAt=workspace:GetServerTimeNow()+60}
 check(profiles:QueueKingdomReward(987650012,offline),'offline existing-store inbox accepts reward')
 local loaded=store:StartSessionAsync(key);local message
 loaded:MessageHandler(function(m,processed)message=m;processed()end);waitFor(function()return message~=nil end,3,'offline mock inbox delivered on load');check(message.Id==offline.Id,'stable cooperative receipt restored');loaded:EndSession()
 result.Acquisitions=3;result.RestoredUIDs=#d.Pets
end,debug.traceback)
world:ClearHot();world.NextHot=nextHot;profile.Data=original;root.CFrame=cf;root.Anchored=anchored
K.GetService('PetService'):Publish(p);K.GetService('PlayerDataService'):Publish(p,'Activities','KingdomShop','Currencies')
if not ok then table.insert(result.Failures,err)end;result.Passed=ok;workspace:SetAttribute('AKEdgeTests',H:JSONEncode(result))
