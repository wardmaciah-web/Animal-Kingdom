-- Isolated mock regression for failed searches and the legacy rebate bypass.
assert(game:GetService('RunService'):IsStudio())
local K=require(game.ReplicatedStorage.Packages.Knit);K.OnStart():await()
local H=game.HttpService;local p=game.Players:GetPlayers()[1];local profile=K.GetService('ProfileService').Profiles[p]
assert(profile.is_mock);local original=profile.Data;local cf=p.Character:GetPivot()
local G=game.ReplicatedStorage.Shared.Gameplay;local P=K.GetService('PetService');local D=K.GetService('PlayerDataService');local R=K.GetService('ResourceService')
local result={Checks=0,Transactions={}};local function check(v,label)assert(v,label);result.Checks+=1 end
local connection=K.GetService('EconomyService').Changed:Connect(function(player,currency,amount,reason)if player==p then table.insert(result.Transactions,{Currency=currency,Amount=amount,Reason=reason})end end)
local ok,err=xpcall(function()
 local d=require(G.ProfileMigrations).Apply(H:JSONDecode(H:JSONEncode(require(game.ReplicatedStorage.SharedSource.Datas.ProfileTemplate))),function()error('No initial pets')end)
 profile.Data=d;d.TutorialCompleted=true;d.Currencies.Coins=0;d.Upgrades={Coins=4,ResourceRewards=4};d.Boosts={}
 local pet={UID='rebate-fixture',UniquePetId='rebate-fixture',PetId='ForestCrestedOwl',Weight=2.4,Level=1,XP=0,Mutation='Normal',Location='Held',LocationSlot=1,Shiny=false,Prismatic=false,Favorite=false,Locked=false,AwardProgressApplied=true}
 table.insert(d.Pets,pet);d.ActiveHeldPetUID=pet.UID;K.GetService('ChallengeService'):Ensure(p);P:Publish(p)
 local weather=K.GetService('WeatherEventService');weather:PauseAutomaticEvents();weather:EndCurrentEvent();weather:StartBreak()
 local record;for tree,r in pairs(R:GetRecords())do if tree:GetAttribute('RewardPoolId')=='Meadow_Shakeable_01'and r.State=='AVAILABLE'then record=r;break end end
 assert(record);local function near()p.Character:PivotTo(CFrame.new(record.InteractionPosition+Vector3.new(0,0,6)));p.Character.HumanoidRootPart.Anchored=true end
 near();local accepted,why=R:Gather(p,record.Object)
 check(not accepted and d.Currencies.Coins==0 and #d.Pets==1 and #result.Transactions==0,'Insufficient actual Gather request has no charge/reward')
 check(why:find('250',1,true)~=nil,'Insufficient message includes canonical cost')
 task.wait(.4);d.Currencies.Coins=250
 check(R:Gather(p,record.Object),'Begin cancellable search')
 p.Character:PivotTo(cf);task.wait(1.2)
 check(record.State=='AVAILABLE'and record.Prompt.Enabled and d.Currencies.Coins==250 and #d.Pets==1,'Out-of-range failed commit restores tree without charging')
 near();check(R:Gather(p,record.Object),'Begin upgraded normal search');task.wait(1.3)
 check(record.State=='RESPAWNING'and #d.Pets==2 and d.Currencies.Coins==0,'Upgraded normal search grants one pet and no coin refund')
 local charges=0;for _,entry in ipairs(result.Transactions)do if entry.Currency=='Coins' then check(entry.Amount==-250 and entry.Reason=='MeadowTreeSearch','Only canonical price transaction');charges+=1 end end
 check(charges==1,'Exactly one charge under gathering upgrades')
 result.FinalBalance=d.Currencies.Coins;result.FinalPetCount=#d.Pets
end,debug.traceback)
connection:Disconnect();profile.Data=original;P:Publish(p);for key in pairs(original)do D:Publish(p,key)end
K.GetService('WeatherEventService'):ResumeAutomaticEvents()
if p.Character then p.Character.HumanoidRootPart.Anchored=false;p.Character:PivotTo(cf)end
result.Passed=ok;result.Error=not ok and err or nil;result.RestoredOriginalMock=true
workspace:SetAttribute('AKEconomyGuards',H:JSONEncode(result));if not ok then warn(err)end
