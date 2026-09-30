-- Studio mock fixture, not mapped into the game. Restore returns the exact original profile.
local K=require(game.ReplicatedStorage.Packages.Knit);K.OnStart():await()
local p=game.Players:GetPlayers()[1]or game.Players.PlayerAdded:Wait();local profiles=K.GetService('ProfileService');profiles:WaitUntilProfileLoaded(p)
local profile=profiles.Profiles[p];assert(game:GetService('RunService'):IsStudio()and profile.is_mock)
local H=game.HttpService;local original=profile.Data;local cf=p.Character:GetPivot();local biome=p:GetAttribute('CurrentBiome')
local d=H:JSONDecode(H:JSONEncode(original));d.TutorialCompleted=true;d.Currencies.Coins=100000;d.UnlockedBiomes.Forest=true;d.Activities={};profile.Data=d
local c=K.GetService('ChallengeService');c:Ensure(p);c.Activities:Ensure(p);local routes=c.Activities.Routes
local function publish()K.GetService('PetService'):Publish(p);for key in pairs(d)do K.GetService('PlayerDataService'):Publish(p,key)end end
publish();local root=p.Character.HumanoidRootPart
local command=Instance.new('BindableFunction');command.Name='AKPolishFixture';command.Parent=workspace
local searches={};local report={Kind='Studio mock Play presentation/placement regression',Paw={},Searches={},InitialUIDs={},OriginalUncollected=original.UncollectedSanctuaryCoins}
for _,pet in ipairs(original.Pets)do report.InitialUIDs[pet.UID]={Weight=pet.Weight,Location=pet.Location,Slot=pet.LocationSlot}end
command.OnInvoke=function(action,id)
 if action=='Travel'then
  local at=id=='Meadow'and Vector3.new(183,13,-143)or id=='Forest'and Vector3.new(183,13,180)or Vector3.new(-235,12,230)
  root.CFrame=CFrame.new(at);p:SetAttribute('CurrentBiome',id);return true
 elseif action=='Paw'then
  d.Activities.Route=nil;d.Activities.PawReadyAt=0;local at=os.clock();local ok,why=routes:Accept(p,'Paw',id)
  if not ok then return {Accepted=false,Why=why}end
  local r=d.Activities.Route;local minimum=math.huge;local clear=true
  for i,t in ipairs(r.Targets)do
   if not routes:PawClear(Vector3.new(unpack(t.Position)),id,p)then clear=false end
   for j=1,i-1 do minimum=math.min(minimum,(Vector3.new(unpack(t.Position))-Vector3.new(unpack(r.Targets[j].Position))).Magnitude)end
  end
  local result={Accepted=true,Seconds=os.clock()-at,AllClear=clear,MinimumSeparation=minimum,Distance=r.Distance,Targets=r.Targets,Id=r.Id};report.Paw[id]=result;return result
 elseif action=='PawNext'then local r=d.Activities.Route;return {Position=r.Targets[r.Progress+1].Position,Progress=r.Progress,Id=r.Id}
 elseif action=='PawFinish'then
  local r=d.Activities.Route;local before=d.Currencies.Coins;local pets=#d.Pets
  while r.Progress<6 do local i=r.Progress+1;root.CFrame=CFrame.new(Vector3.new(unpack(r.Targets[i].Position))+Vector3.new(0,3,0));assert(routes:Discover(p,r.Id,i))end
  assert(r.Completed and d.Currencies.Coins==before and #d.Pets==pets);return true
 elseif action=='Rush'then d.Activities.Route=nil;return routes:Accept(p,'Rush:Speed',p:GetAttribute('CurrentBiome'))
 elseif action=='Search'or action=='SearchForest'then
  local searchBiome=action=='SearchForest'and 'Forest'or 'Meadow';local price=searchBiome=='Forest'and 6000 or 250
  local candidate
  for _,t in ipairs(routes:Candidates(searchBiome,searchBiome..'_Shakeable_01'))do if t.Record.State=='AVAILABLE'and not searches[t.Id]then candidate=t;break end end
  assert(candidate,'ready unique tree');local point=routes:WalkingPoint(candidate,root.Position,p);assert(point)
  root.CFrame=CFrame.new(point+Vector3.new(0,3,0));p:SetAttribute('CurrentBiome',searchBiome)
  local eggs=K.GetService('EggService');if id then eggs:StudioForceNext(p,id)end
  local before=#d.Pets;local coins=d.Currencies.Coins;local ok=K.GetService('ResourceService'):Gather(p,candidate.Tree);assert(ok,'accepted actual normal search')
  local deadline=os.clock()+8;repeat task.wait(.1)until #d.Pets>before or os.clock()>deadline
  assert(#d.Pets==before+1 and d.Currencies.Coins==coins-price,'one pet, canonical price')
  searches[candidate.Id]=true;local pet=d.Pets[#d.Pets];local result={UID=pet.UID,PetId=pet.PetId,Weight=pet.Weight,Price=price,JourneyStep=d.Activities.Journey.Step,JourneyProgress=d.Activities.Journey.Entries[1].Progress};table.insert(report.Searches,result);return result
 elseif action=='Hot'then
  local best;local distance=math.huge
  for _,t in ipairs(routes:Candidates(p:GetAttribute('CurrentBiome')))do local delta=(t.Record.InteractionPosition-root.Position).Magnitude;if delta<distance then distance=delta;best=t end end
  assert(best);return c.Activities.World:StartHot(id,best.Tree)
 elseif action=='Micro'then c.Activities.World.Micro={Id=id,Biome=p:GetAttribute('CurrentBiome'),EndsAt=workspace:GetServerTimeNow()+30};c.Activities.World.LastPublish=0;return true
 elseif action=='Lucky'then K.GetService('LuckyTreeService'):EndEvent();return K.GetService('LuckyTreeService'):Spawn(id)
 elseif action=='Notice'then K.GetService('NotificationService'):Announce('PolishNotice:'..H:GenerateGUID(false),id=='Shop'and 'The Kingdom Shop has restocked. Browse anywhere; purchase at the Town store.'or 'A Tree Rush challenge is available in Activities. Normal search costs apply.',id=='Shop'and 45 or 30,id=='Shop'and 'Shop'or 'Invitation');return true
 elseif action=='ClearRoute'then d.Activities.Route=nil;publish();return true
 elseif action=='Data'then return {Route=d.Activities.Route,Journey=d.Activities.Journey,Report=report}
 elseif action=='Restore'then
  K.GetService('LuckyTreeService'):EndEvent();c.Activities.World:ClearHot();profile.Data=original;K.GetService('PetService'):Publish(p);for key in pairs(original)do K.GetService('PlayerDataService'):Publish(p,key)end
  p.Character:PivotTo(cf);p:SetAttribute('CurrentBiome',biome);report.Restored=true;report.FinalOriginalUncollected=original.UncollectedSanctuaryCoins;workspace:SetAttribute('AKPolishResults',H:JSONEncode(report));command:Destroy();return report
 end
end
workspace:SetAttribute('AKPolishReady',true)
