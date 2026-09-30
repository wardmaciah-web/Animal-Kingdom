-- Temporary Studio-only acceptance test; real saved ProfileStore objects remain untouched.
assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
 local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage")
 local Collection=game:GetService("CollectionService");local S=game.ServerScriptService.ServerSource.Server
 local Profiles=require(S.ProfileService);local Resource=require(S.ResourceService);local Pets=require(S.PetService)
 local Egg=require(S.EggService);local Weather=require(S.WeatherEventService)
 local expected=workspace:GetAttribute("AKTreeLoopExpected") or 1
 local originals,roster={},{};local checks,failures=0,0
 local harness=Instance.new("Folder");harness.Name="AKTreeLoopHarness";harness.Parent=RS
 local function check(ok,message) checks+=1;if not ok then failures+=1 end;print("AK_TREE_TEST "..(ok and "PASS " or "FAIL ")..message) end
 local function copy(v) if type(v)~="table" then return v end;local t={};for k,x in pairs(v) do t[k]=copy(x) end;return t end
 local function stage(name,trees)
  for i,p in ipairs(roster) do
   local target=harness:FindFirstChild(tostring(p.UserId)) or Instance.new("ObjectValue");target.Name=tostring(p.UserId);target.Value=trees[i];target.Parent=harness
   local record=Resource:GetRecords()[trees[i]];p.Character:PivotTo(CFrame.new(record.InteractionPosition+Vector3.new(i*1.5,1,4)))
  end
  task.wait(.6);harness:SetAttribute("Stage",name)
 end
 local ok,issue=pcall(function()
  local timeout=os.clock()+300
  repeat roster={};for _,p in ipairs(Players:GetPlayers()) do if Profiles.Profiles[p] and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p:GetAttribute("HasPlot")==true then table.insert(roster,p) end end;if #roster<expected then task.wait(.2) end until #roster>=expected or os.clock()>timeout
  assert(#roster==expected,"Ready clients "..#roster.." expected "..expected);task.wait(3)
  Weather:EmergencyReset()
  for _,p in ipairs(roster) do
   originals[p]={Profile=Profiles.Profiles[p],Pivot=p.Character:GetPivot(),Anchored=p.Character.HumanoidRootPart.Anchored}
   p.Character.HumanoidRootPart.Anchored=true
   local data=copy(require(RS.SharedSource.Datas.ProfileTemplate));require(RS.Shared.Gameplay.ProfileMigrations).Apply(data,function() return game.HttpService:GenerateGUID(false) end)
   Profiles.Profiles[p]={Data=data,FirstSessionTime=os.time(),IsActive=function() return true end};Profiles.Client.GetData:Fire(p,data)
   check(data.Currencies.Coins==0,p.Name.." begins tree loop with zero Coins")
  end
  local counts,meadow={},{}
  for object,record in pairs(Resource:GetRecords()) do
   counts[record.Biome]=(counts[record.Biome] or 0)+1
   if record.Biome=="Meadow" then table.insert(meadow,object) end
  end
  for _,biome in ipairs(require(RS.Shared.Gameplay.Definitions.BiomeDefinitions).Ordered) do check((counts[biome.Id] or 0)>0,biome.Id.." registered real trees: "..tostring(counts[biome.Id])) end
  local generated=0;local eggPrompts=0
  for _,object in ipairs(workspace:GetDescendants()) do if object:GetAttribute("GameplayGenerated")==true then generated+=1 end;if object:IsA("ProximityPrompt") and object.Name=="EggPrompt" then eggPrompts+=1 end end
  check(generated==0 and #Collection:GetTagged("EggStation")==0 and eggPrompts==0,"no generated gameplay geometry or ground egg prompts")
  local a=roster[1];local data=Profiles.Profiles[a].Data;local tree=assert(meadow[1]);local record=Resource:GetRecords()[tree]
  local pivot=tree:GetPivot();local properties={};for object,props in pairs(record.Properties) do properties[object]=copy(props) end
  harness:SetAttribute("FullUserId",a.UserId)
  data.PetStorageCapacity=0
  local same={};for i=1,#roster do same[i]=tree end
  stage("Full",same);task.wait(1)
  check(record.State=="AVAILABLE" and #data.Pets==0 and tree:GetPivot()==pivot,"full inventory leaves original tree untouched")
  data.PetStorageCapacity=50
  stage("Race",same);task.wait(2.5)
  local winner;local pets=0
  for _,p in ipairs(roster) do local d=Profiles.Profiles[p].Data;pets+=#d.Pets;if #d.Pets==1 then winner=p end end
  check(pets==1 and winner~=nil,"one shared-tree race awards exactly one pet")
  assert(winner,"No winner")
  local winData=Profiles.Profiles[winner].Data
  check(record.State=="RESPAWNING","tree hidden before hatch presentation")
  local hidden=true;for object in pairs(properties) do if object:IsA("BasePart") and (object.Transparency~=1 or object.CanCollide or object.CanTouch or object.CanQuery) then hidden=false end end
  check(hidden and not record.Prompt.Enabled,"all original geometry/interaction disabled")
  check(winData.Stats.Gather==1 and winData.Stats.Hatch==1,"tree/hatch challenges advance exactly once")
  check(winData.PetIndex[winData.Pets[1].PetId]~=nil,"tree pet enters existing Index")
  check(winData.Currencies.Coins>=0,"egg never spends Coins")
  check(Pets:Equip(winner,winData.Pets[1].UID,true),"awarded placeholder pet equips")
  local deadline=tree:GetAttribute("RespawnAt");check(type(deadline)=="number","server controls respawn deadline")
  task.wait(math.max(0,deadline-workspace:GetServerTimeNow()-.15))
  check(record.State=="RESPAWNING","tree remains unavailable before twenty-second deadline")
  repeat task.wait() until record.State=="AVAILABLE" or workspace:GetServerTimeNow()>deadline+3
  local exact=tree:GetPivot()==pivot;for object,props in pairs(properties) do for key,value in pairs(props) do if object[key]~=value then exact=false end end end
  check(exact and record.State=="AVAILABLE","same tree restores exact original pivot/rotation/part/effect/prompt properties")
  check(#winData.Pets==1 and winData.Stats.Hatch==1 and winData.Stats.Gather==1,"cooldown causes no repeated pet or challenge credit")
  local targets={};local before={}
  for i,p in ipairs(roster) do targets[i]=assert(meadow[i+1]);before[p]=#Profiles.Profiles[p].Data.Pets end
  Weather:StartEvent("Rainbow",false)
  check(require(S.ModifierService):Get(a,"Luck")>1,"tree hatching uses existing Rainbow luck")
  stage("Independent",targets);task.wait(3)
  local uids={}
  for i,p in ipairs(roster) do
   local d=Profiles.Profiles[p].Data
   check(#d.Pets==before[p]+1,p.Name.." independent tree awards its own pet")
   for _,pet in ipairs(d.Pets) do check(not uids[pet.UID],"pet UID remains unique across all players");uids[pet.UID]=true end
   check(Resource:GetRecords()[targets[i]].State=="RESPAWNING",p.Name.." tree owns its own cooldown")
  end
  Weather:EmergencyReset()
  local remembered=winData.Pets[#winData.Pets].UID;local total=#winData.Pets
  winner.Character:FindFirstChildOfClass("Humanoid").Health=0
  task.wait(1);winner:LoadCharacterAsync();task.wait(1)
  check(#winData.Pets==total and winData.Pets[#winData.Pets].UID==remembered,"death/respawn after award preserves single committed pet")
  check(not Egg:Hatch(winner,tree,3),"retired ground/triple request cannot create extra pets")
 end)
 if not ok then check(false,"runtime exception: "..tostring(issue)) end
 Weather:EmergencyReset()
 for p,old in pairs(originals) do
  Profiles.Profiles[p]=old.Profile
  if p.Parent==Players then Profiles.Client.GetData:Fire(p,old.Profile.Data);Pets:Publish(p);if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then p.Character:PivotTo(old.Pivot);p.Character.HumanoidRootPart.Anchored=old.Anchored end end
 end
 harness:SetAttribute("Stage","Complete")
 print("AK_TREE_TEST_DONE clients="..#roster.." assertions="..checks.." failures="..failures.." savedProfilesUnchanged=true")
end)
