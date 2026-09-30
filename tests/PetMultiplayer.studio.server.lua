-- Temporarily installed by QA; not mapped by Rojo and inert outside this Studio test.
local Test=game:GetService('StudioTestService')
if not game:GetService('RunService'):IsStudio() or Test:GetTestArgs()~='AK_PetWeight_20260923' then return end
local finished=false
local function finish(v)if not finished then finished=true;Test:EndTest(v)end end
task.delay(180,function()finish({Ok=false,Error='Multiplayer timeout'})end)
local ok,result=xpcall(function()
 assert(game.PlaceId==132313449035787 and game.ServerScriptService.ServerSource.Server.ProfileService:GetAttribute('AKUseMockProfiles')==true)
 local RS=game.ReplicatedStorage;local K=require(RS.Packages.Knit);K.OnStart():await()
 local D=K.GetService('PlayerDataService');local P=K.GetService('PetService');local G=K.GetService('GardenExpeditionService');local Plots=K.GetService('PlotService')
 local qa=Instance.new('RemoteFunction');qa.Name='AKPetMultiplayerQA';qa.Parent=RS
 repeat task.wait(.2)until #game.Players:GetPlayers()==2
 local players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 repeat task.wait(.2)until D:Get(players[1])and D:Get(players[2])and players[1].Character and players[2].Character and Plots:GetPlot(players[1])and Plots:GetPlot(players[2])
 local a,b=players[1],players[2];local da,db=D:Get(a),D:Get(b)
 assert(da~=db and da.Pets~=db.Pets and da.GardenExpeditions~=db.GardenExpeditions)
 local grants={}
 for i,player in ipairs(players)do
  local d=D:Get(player);d.Currencies.Coins=100000*i;d.UnlockedBiomes.Forest=true;d.TutorialCompleted=true
  local main=assert(P:Grant(player,'ForestBadger','Normal'));main.Weight=12*i
  local held=assert(P:Grant(player,'ForestBrownBat','Normal'))
  local forager=assert(P:Grant(player,'MeadowFluffyLop','Normal'))
  assert(Plots:Teleport(player));P:Publish(player)
  assert(P:Move(player,main.UID,'Sanctuary',1));assert(P:Move(player,forager.UID,'Inventory'))
  assert(G:Start(player,forager.UID,'SproutRun','qa-garden-'..i))
  assert(P:SwapSanctuary(player,2,1,held.UID,main.UID))
  assert(main.Location=='Held'and main.LocationSlot==2 and held.Location=='Sanctuary'and held.LocationSlot==1)
  grants[player]={Main=main,Held=held,Garden=forager};D:Publish(player,'Currencies','UnlockedBiomes','TutorialCompleted')
 end
 assert(Plots:GetPlot(a)~=Plots:GetPlot(b)and a:GetAttribute('GardenPlotId')~=b:GetAttribute('GardenPlotId'))
 assert(not P:Move(b,grants[a].Main.UID,'Inventory'),'Foreign move')
 assert(not P:QuoteSale(b,grants[a].Main.UID),'Foreign sale')
 assert(not P:SwapSanctuary(b,2,1,grants[a].Main.UID,grants[a].Held.UID),'Foreign swap')
 assert(not G:Start(b,grants[a].Garden.UID,'SproutRun','qa-foreign'),'Foreign Garden')
 local sale=assert(P:Grant(a,'ForestRaccoon','Normal'));assert(P:Move(a,sale.UID,'Inventory'))
 local ac,bc=da.Currencies.Coins,db.Currencies.Coins;local bCount=#db.Pets
 local quoted,q=P:QuoteSale(a);assert(quoted)
 local sold,s=P:Sell(a,q.Token);assert(sold and da.Currencies.Coins==ac+s.Total)
 assert(not P:Sell(a,q.Token)and db.Currencies.Coins==bc and #db.Pets==bCount,'Duplicate/foreign payout')
 local R=K.GetService('ResourceService');local E=K.GetService('EggService');local target,record
 for tree,r in pairs(R:GetRecords())do if r.Biome=='Forest'and tree:GetAttribute('TreeTier')==3 then target,record=tree,r;break end end
 assert(target);a.Character:PivotTo(CFrame.new(record.InteractionPosition+Vector3.new(0,3,-5)))
 local deadline=os.clock()+90
 repeat local ready=E:CheckTreeHatch(a,target);if ready then break end;task.wait(.4)until os.clock()>deadline
 local aCount=#da.Pets;E:StudioForceNext(a,'ForestBrownBat');assert(R:Gather(a,target));task.wait(3)
 assert(#da.Pets==aCount+1 and #db.Pets==bCount and db.Currencies.Coins==bc,'Personal tree reward')
 local sa=qa:InvokeClient(a);local sb=qa:InvokeClient(b)
 assert(sa.Pets[grants[a].Main.UID]and not sa.Pets[grants[b].Main.UID]and sb.Pets[grants[b].Main.UID]and not sb.Pets[grants[a].Main.UID],'Private client inventories')
 assert(sa.Pets[grants[a].Main.UID].Weight==12 and sb.Pets[grants[b].Main.UID].Weight==24,'Private individual stats')
 assert(sa.RevealPet=='ForestBrownBat'and sb.RevealPet==nil,'Personal reveal')
 assert(sa.Camera=='Custom'and sb.Camera=='Custom','Standard camera retained')
 assert(sa.Coins==da.Currencies.Coins and sb.Coins==db.Currencies.Coins,'Private currencies')
 return {Players=2,SeparateProfiles=true,SeparatePlots=true,SeparateGardens=true,CrossPlayerMoveSaleSwapRejected=true,SalePaidOnce=true,PersonalTreeReward=true,IndividualWeights=true,ClientA=sa,ClientB=sb}
end,debug.traceback)
finish({Ok=ok,Result=result})
