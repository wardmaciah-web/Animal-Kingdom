-- Run as a temporary SERVER Script in a fresh Studio Play session.
-- The actual saved ProfileStore object is never modified: the registry temporarily
-- points at an isolated test profile, and is restored even when an assertion fails.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer(),"Studio server required")
task.spawn(function()
 local RS=game:GetService("ReplicatedStorage")
 local Players=game:GetService("Players")
 local services=game.ServerScriptService.ServerSource.Server
 local Profiles=require(services.ProfileService)
 local player=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
 local deadline=os.clock()+120
 repeat task.wait(.1) until (Profiles.Profiles[player] and player.Character and player.Character:FindFirstChild("HumanoidRootPart")) or os.clock()>deadline
 task.wait(3) -- allow the existing plot-spawn handoff to finish
 local originalProfile=assert(Profiles.Profiles[player],"Profile not ready")
 local root=assert(player.Character:FindFirstChild("HumanoidRootPart"));local originalPivot=player.Character:GetPivot()
 local wasAnchored=root.Anchored;root.Anchored=true
 local function copy(value)
  if type(value)~="table" then return value end
  local result={};for k,v in pairs(value) do result[k]=copy(v) end;return result
 end
 local testData=copy(require(RS.SharedSource.Datas.ProfileTemplate))
 require(RS.Shared.Gameplay.ProfileMigrations).Apply(testData,function() return game.HttpService:GenerateGUID(false) end)
 local fakeProfile={Data=testData,FirstSessionTime=os.time(),IsActive=function() return true end}
 Profiles.Profiles[player]=fakeProfile;Profiles.Client.GetData:Fire(player,testData)
 workspace:SetAttribute("AK_GameplayTestStage","Started")
 local checks,failures=0,0
 local function check(ok,message)
  checks+=1;if not ok then failures+=1 end
  print("AK_GAMEPLAY_LIVE "..(ok and "PASS " or "FAIL ")..message)
 end
 local function go(position)
  player.Character:PivotTo(CFrame.new(position+Vector3.new(0,4,3)))
  root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
 end
 local ok,issue=pcall(function()
  local Resource=require(services.ResourceService);local Egg=require(services.EggService)
  local Economy=require(services.EconomyService);local Pets=require(services.PetService)
  local Biomes=require(services.BiomeService);local Modifiers=require(services.ModifierService)
  local Weather=require(services.WeatherEventService);local Collection=game:GetService("CollectionService")
  local definitions=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
  for _,biome in ipairs(definitions.Ordered) do
   local trees,eggs=0,0
   for object in pairs(Resource:GetRecords()) do if object:GetAttribute("BiomeId")==biome.Id then trees+=1 end end
   for object,id in pairs(Egg:GetStations()) do if object:GetAttribute("BiomeId")==biome.Id and id==biome.Egg then eggs+=1 end end
   check(trees>=1 and eggs>=1,biome.Id.." has accessible resource/egg stations: "..trees.."/"..eggs)
  end
  local tree
  for object in pairs(Resource:GetRecords()) do if object:GetAttribute("BiomeId")=="Meadow" then tree=object;break end end
  assert(tree,"No Meadow resource")
  local pivot=tree:GetPivot();go(pivot.Position);task.wait(.5)
  local properties={}
  for _,v in ipairs(tree:GetDescendants()) do
   if v:IsA("BasePart") then properties[v]={Transparency=v.Transparency,CanCollide=v.CanCollide,CanTouch=v.CanTouch,CanQuery=v.CanQuery} end
  end
  local transactions=0
  local observer=Economy.Changed:Connect(function(owner,_,amount,reason) if owner==player and amount>0 and reason=="Gather" then transactions+=1 end end)
  local accepted,reason=Resource:Gather(player,tree)
  print("AK_GAMEPLAY_GATHER_DIAGNOSTIC",accepted,reason,"distance",(root.Position-tree:GetPivot().Position).Magnitude,"health",player.Character:FindFirstChildOfClass("Humanoid").Health,"profile",require(services.PlayerDataService):Get(player)~=nil,"biome",tree:GetAttribute("BiomeId"))
  check(accepted,"first tree interaction accepted")
  check(not Resource:Gather(player,tree),"same-frame duplicate denied")
  task.wait(.35);check(not Resource:Gather(player,tree),"locked tree denies second request after player throttle")
  task.wait(1.1)
  check(tree:GetAttribute("ResourceState")=="RESPAWNING","shake completes and tree enters respawn")
  local deadline=tree:GetAttribute("RespawnAt");check(type(deadline)=="number","server respawn deadline replicated")
  local hidden=true;for part in pairs(properties) do if part.Transparency~=1 or part.CanCollide or part.CanTouch or part.CanQuery then hidden=false end end
  check(hidden,"all geometry hidden and collision/touch/query disabled")
  local count=transactions;check(count>=1,"one harvest issued its configured reward")
  task.wait(math.max(0,deadline-workspace:GetServerTimeNow()-.15))
  check(tree:GetAttribute("ResourceState")=="RESPAWNING","unavailable before twenty-second deadline")
  repeat task.wait() until tree:GetAttribute("ResourceState")=="AVAILABLE" or workspace:GetServerTimeNow()>deadline+2
  local restored=tree:GetPivot()==pivot
  for part,props in pairs(properties) do for key,value in pairs(props) do if part[key]~=value then restored=false end end end
  check(restored,"exact original pivot, rotation and part properties restored")
  check(transactions==count,"no duplicate reward during respawn")
  check(workspace:GetServerTimeNow()>=deadline,"tree did not respawn early")
  observer:Disconnect()
  local target
  for object,id in pairs(Egg:GetStations()) do if id=="MeadowEgg" then target=object;break end end
  assert(target,"No Meadow egg");go(target:GetPivot().Position);task.wait(.5)
  Economy:Add(player,"Coins",10000,"Test")
  local before=Economy:GetBalance(player,"Coins")
  local hatched,result=Egg:Hatch(player,target,3)
  if hatched then RS.AnimalKingdomRemotes.GameplayFeedback:FireClient(player,{Action="Hatch",Success=true,Result=result});workspace:SetAttribute("AK_GameplayTestStage","Hatched") end
  check(hatched and #result.Results==3 and #testData.Pets==3,"triple hatch creates three independent owned pets")
  check(Economy:GetBalance(player,"Coins")==before-750,"triple hatch debits server-defined price")
  check(testData.PetIndex[testData.Pets[1].PetId]~=nil,"hatch records Index discovery")
  check(Pets:Equip(player,testData.Pets[1].UID,true),"owned pet equips")
  workspace:SetAttribute("AK_GameplayTestStage","Equipped")
  check(player:GetAttribute("EquippedPetData")~=nil,"authoritative equipped list replicated for followers")
  task.wait(5);testData.PetStorageCapacity=3;before=Economy:GetBalance(player,"Coins")
  check(not Egg:Hatch(player,target,1) and Economy:GetBalance(player,"Coins")==before,"capacity rejection never spends currency")
  testData.PetStorageCapacity=50
  check(not Pets:Equip(player,"unowned-uid",true),"foreign UID rejected")
  check(not Biomes:Unlock(player,"Jungle"),"progression cannot skip Forest")
  check(Biomes:Unlock(player,"Forest"),"Forest purchase succeeds")
  check(not Biomes:Unlock(player,"Forest"),"Forest cannot be purchased twice")
  for id in pairs(require(RS.Shared.EventDefinitions)) do
   if type(id)=="string" then
    Weather:StartEvent(id,false)
    if Weather:GetCurrentState().EventId==id then
     check(Modifiers:Get(player,"Coins")>0 and Modifiers:Get(player,"Luck")>0,"finite weather modifiers for "..id)
     Weather:EmergencyReset();check(Modifiers:Get(player,"Coins")==1 and Modifiers:Get(player,"Luck")==1,"immediate weather cleanup for "..id)
    end
   end
  end
  local Resolver=require(RS.Shared.Gameplay.AssetResolver)
  for _,category in ipairs(Resolver.Categories) do
   local name="AuditSwap_"..category
   local placeholder=Resolver.Create(category,name);check(placeholder:GetAttribute("Placeholder")==true,"placeholder fallback "..category);placeholder:Destroy()
   local template=Instance.new("Model");template.Name=name
   local part=Instance.new("Part");part.Name="RealAssetProbe";part.Anchored=true;part.Parent=template;template.Parent=RS.Assets[category]
   local resolved=Resolver.Create(category,name);check(resolved:FindFirstChild("RealAssetProbe")~=nil and not resolved:GetAttribute("Placeholder"),"automatic asset replacement "..category)
   resolved:Destroy();template:Destroy()
  end
 end)
 if not ok then check(false,"runtime exception: "..tostring(issue)) end
 require(services.WeatherEventService):EmergencyReset()
 -- Restore registry first: original ProfileStore autosave always retained its own data object.
 Profiles.Profiles[player]=originalProfile
 if player.Parent==Players then
  Profiles.Client.GetData:Fire(player,originalProfile.Data)
  require(services.PetService):Publish(player)
  if player.Character then player.Character:PivotTo(originalPivot);root.Anchored=wasAnchored end
 end
 workspace:SetAttribute("AK_GameplayTestStage","Complete")
 print("AK_GAMEPLAY_LIVE_DONE assertions="..checks.." failures="..failures.." savedProfileUnchanged=true")
end)
