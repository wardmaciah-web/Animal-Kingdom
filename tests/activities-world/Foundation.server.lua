-- Studio-only: pure copied profile calculations plus live service wiring.
local RS=game:GetService('ReplicatedStorage')
local H=game:GetService('HttpService')
local result={Kind='Stage1 foundations',Assertions=0,Failures={}}
local function check(ok,message)result.Assertions+=1;if not ok then table.insert(result.Failures,message)end end
local ok,err=xpcall(function()
 assert(game:GetService('RunService'):IsStudio())
 assert(game.ServerScriptService.ServerSource.Server.ProfileService:GetAttribute('AKUseMockProfiles')==true)
 local K=require(RS.Packages.Knit);K.OnStart():await()
 local P=require(RS.Shared.Gameplay.KingdomProgress)
 local F=require(RS.Shared.Gameplay.Definitions.KingdomShopDefinitions)
 local W=require(RS.Shared.Gameplay.PetWeight)
 local defs=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
 local original={Pets={{UID='existing-uid',PetId='MeadowFieldMouse',Weight=.27,XP=38,Locked=true,Location='Inventory'}},UncollectedSanctuaryCoins=912.25,DailyChallenges={Entries={old={Progress=7,Claimed=false}}},Currencies={Coins=731},Contracts={Entries={{Id='old-contract',Progress=9}}}}
 local before=H:JSONEncode(original);local copy=H:JSONDecode(before)
 P.Ensure(copy);P.Ensure(copy)
 local same=#copy.Pets==#original.Pets
 for i,pet in ipairs(original.Pets)do for key,value in pairs(pet)do same=same and copy.Pets[i][key]==value end end
 check(same,'ownership unchanged')
 check(copy.UncollectedSanctuaryCoins==912.25 and copy.Currencies.Coins==731,'earned money unchanged')
 check(copy.Contracts.Entries[1].Progress==9 and copy.DailyChallenges.Entries.old.Progress==7,'legacy progress unchanged')
 check(P.FirstEvent(copy,'Search:uid') and not P.FirstEvent(copy,'Search:uid'),'event replay does not count')
 P.RecordFamily(copy,'Meadow_Shakeable_01',{PetId='MeadowFieldMouse',Weight=.27})
 check(copy.TreeMastery.Meadow_Shakeable_01.Searches==1,'family records begin with observed searches')
 check(P.FamilyLuck(copy,'Meadow_Shakeable_02')==1,'other family unaffected')
 copy.TreeMastery.Meadow_Shakeable_01.Searches=120
 check(P.FamilyLuck(copy,'Meadow_Shakeable_01')==1.05,'family cap five percent')
 copy.KingdomShop.Active.Blessing={StartedAt=100,ExpiresAt=700}
 check(math.abs(P.IncomeSeconds(copy,0,800)-890)<1e-6,'offline integrates boost start and expiry')
 local weather=function(a,z)return (math.min(z,400)-math.min(a,400))+2*(math.max(z,400)-math.max(a,400))end
 check(math.abs(P.IncomeSeconds(copy,0,800,weather)-1335)<1e-6,'weather and blessing integrate in the same intervals')
 check(P.IncomeSeconds(copy,700,900)==200,'expired boost changes no future accrual')
 check(P.IncomeSeconds(copy,0,100)==100,'boost does not multiply earlier earnings')
 local t=F.Rotation(10000);local offers=F.Offers(t)
 check(#offers==6 and offers[6].Price<offers[6].OriginalPrice,'all six stock slots and visible discount')
 check(H:JSONEncode(offers)==H:JSONEncode(F.Offers(t)),'same rotation on every server')
 local r1,r2=Random.new(73),Random.new(73)
 check(W.Roll(defs.MeadowFieldMouse,r1,1)==W.Roll(defs.MeadowFieldMouse,r2,1,0),'unmodified weight roll preserved')
 local p=game.Players:GetPlayers()[1]or game.Players.PlayerAdded:Wait()
 K.GetService('ProfileService'):WaitUntilProfileLoaded(p)
 task.wait(3)
 local m=K.GetService('ModifierService');local resources=K.GetService('ResourceService'):GetRecords();local count=0
 for tree,r in pairs(resources)do if r.IsTree and (r.Biome=='Meadow'or r.Biome=='Forest')then
  local s=m:SearchSnapshot(p,tree,r.Biome,tree:GetAttribute('RewardPoolId'))
  check(s.TreeCooldown==20 and s.Recovery>=.75 and s.WeightBias==0,'unbuffed search snapshot '..tree.Name)
  check(type(tree:GetAttribute('ActivityTreeId'))=='string','stable target identity '..tree.Name)
  count+=1
 end end
 check(count>=10,'released tree registration')
 result.Trees=count
end,debug.traceback)
if not ok then table.insert(result.Failures,tostring(err))end
result.Passed=#result.Failures==0
workspace:SetAttribute('AKActivitiesFoundation',H:JSONEncode(result))
