-- Installed temporarily by the Studio harness; never mapped into the production place.
local Run=game:GetService('RunService');local Test=game:GetService('StudioTestService')
if not Run:IsStudio() or Test:GetTestArgs()~='AK_Production_20260923' then return end
local finished=false
local function finish(value)if finished then return end;finished=true;Test:EndTest(value)end
task.delay(240,function()finish({Ok=false,Error='Multiplayer QA timeout'})end)
local ok,result=xpcall(function()
 assert(game.PlaceId==132313449035787 and game.GameId==10764288431,'Unexpected test place')
 assert(game.ServerScriptService.ServerSource.Server.ProfileService:GetAttribute('AKUseMockProfiles')==true,'Mock profiles required')
 local Players=game:GetService('Players');local RS=game.ReplicatedStorage;local H=game:GetService('HttpService');local K=require(RS.Packages.Knit)
 K.OnStart():await();local D=K.GetService('PlayerDataService');local P=K.GetService('PetService');local S=K.GetService('SanctuaryService');local G=K.GetService('GardenExpeditionService');local Plots=K.GetService('PlotService');local E=K.GetService('EggService');local R=K.GetService('ResourceService')
 local qa=Instance.new('RemoteFunction');qa.Name='AKMultiplayerQA';qa.Parent=RS
 repeat task.wait(.25)until #Players:GetPlayers()==2
 local players=Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end);local a,b=players[1],players[2]
 repeat task.wait(.25)until D:Get(a)and D:Get(b)and a.Character and b.Character and Plots:GetPlot(a)and Plots:GetPlot(b)
 local da,db=D:Get(a),D:Get(b);assert(da~=db and da.Pets~=db.Pets and da.GardenExpeditions~=db.GardenExpeditions,'Shared profile tables')
 local grants={};for i,p in ipairs(players)do
  local d=D:Get(p);d.PetStorageCapacity=100;d.Currencies.Coins=i*100000;d.Currencies.FriendshipTokens=i*100;d.UnlockedBiomes.Forest=true
  local species=i==1 and 'ForestRaccoon' or 'MeadowFieldMouse';local pet=assert(P:Grant(p,species,'Normal',false,false));local forager=assert(P:Grant(p,i==1 and 'ForestRiverOtter'or 'ForestTreeFrog','Normal',false,false))
  grants[p]={Pet=pet,Forager=forager};assert(P:Equip(p,pet.UID,true));assert(Plots:Teleport(p));task.wait(.2);assert(S.Client:SetPetDisplayed(p,pet.UID,true));assert(G:Start(p,forager.UID,'SproutRun','qa-send-'..p.UserId))
  D:Publish(p,'Currencies','UnlockedBiomes','PetStorageCapacity')
 end
 assert(Plots:GetPlot(a)~=Plots:GetPlot(b),'Shared plot');assert(a:GetAttribute('GardenPlotId')~=b:GetAttribute('GardenPlotId'),'Shared Garden')
 assert(not P:Equip(b,grants[a].Pet.UID,true),'Cross-profile equip accepted');assert(not S.Client:SetPetDisplayed(b,grants[a].Pet.UID,true),'Cross-profile display accepted')
 assert(not G:Start(b,grants[a].Forager.UID,'SproutRun','qa-cross-garden'),'Cross-profile Garden accepted')
 local target,record;for tree,r in pairs(R:GetRecords())do if r.Biome=='Forest'and tree:GetAttribute('TreeTier')==3 then target,record=tree,r;break end end;assert(target)
 a.Character:PivotTo(CFrame.new(record.InteractionPosition+Vector3.new(0,3,-6)));b.Character:PivotTo(CFrame.new(record.InteractionPosition+Vector3.new(12,3,-6)))
 local untilAt=os.clock()+120;repeat local ready=E:CheckTreeHatch(a,target);if ready then break end;task.wait(.5)until os.clock()>untilAt
 local bCoins=db.Currencies.Coins;local bCount=#db.Pets;local aCount=#da.Pets;E:StudioForceNext(a,'ForestBrownBat');assert(R:Gather(a,target));task.wait(3.5)
 assert(#da.Pets==aCount+1 and #db.Pets==bCount and db.Currencies.Coins==bCoins,'Reward leaked between players')
 local sa=qa:InvokeClient(a,'Snapshot');local sb=qa:InvokeClient(b,'Snapshot')
 assert(sa.RevealPet=='ForestBrownBat' and sb.RevealPet==nil,'Reveal is not personal')
 assert(sa.Currencies.Coins==da.Currencies.Coins and sb.Currencies.Coins==db.Currencies.Coins,'Client currency mismatch')
 assert(sa.Owned[grants[a].Pet.UID]and not sa.Owned[grants[b].Pet.UID],'A inventory leak')
 assert(sb.Owned[grants[b].Pet.UID]and not sb.Owned[grants[a].Pet.UID],'B inventory leak')
 assert(sa.Garden[grants[a].Forager.UID]and not sa.Garden[grants[b].Forager.UID],'A Garden leak')
 assert(sb.Garden[grants[b].Forager.UID]and not sb.Garden[grants[a].Forager.UID],'B Garden leak')
 assert(sa.Camera=='Enum.CameraType.Custom'and sb.Camera=='Enum.CameraType.Custom','Reward camera changed')
 local beforeB=H:JSONEncode(db.GardenCrops);local bHarvest=db.Currencies.GardenHarvest
 local trip=da.GardenExpeditions[1];trip.ReadyAt=os.time()-1;trip.PendingHarvest=20;trip.PendingCrops.Carrot=3
 local claimed=G:Claim(a,trip.UID,'qa-claim-a');assert(claimed);assert(H:JSONEncode(db.GardenCrops)==beforeB and db.Currencies.GardenHarvest==bHarvest,'Garden claim leaked')
 return {PlaceId=game.PlaceId,GameId=game.GameId,Players=2,ProfilesSeparate=true,PlotsSeparate=true,GardensSeparate=true,CrossOwnershipRejected=true,PersonalReward=true,ClientA=sa,ClientB=sb,ForestReward='ForestBrownBat',GardenClaimIsolated=true,Plots={Plots:GetPlot(a).Name,Plots:GetPlot(b).Name},GardenPlots={a:GetAttribute('GardenPlotId'),b:GetAttribute('GardenPlotId')}}
end,debug.traceback)
finish({Ok=ok,Result=result})
