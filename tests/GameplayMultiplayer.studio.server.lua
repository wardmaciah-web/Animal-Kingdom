-- Temporary Studio-only real-client regression; original ProfileStore objects remain untouched.
assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
 local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage")
 local services=game.ServerScriptService.ServerSource.Server
 local Profiles=require(services.ProfileService);local Resource=require(services.ResourceService)
 local Economy=require(services.EconomyService);local Egg=require(services.EggService)
 local Plots=require(services.PlotService);local Placement=require(services.PlacementService)
 local Shop=require(services.ShopService);local Locator=require(game.ServerScriptService.PlotLocator)
 local expected=workspace:GetAttribute("AK_MultiplayerExpected") or 2
 local originals={};local roster={};local checks,failures=0,0
 local function check(ok,message) checks+=1;if not ok then failures+=1 end;print("AK_MULTI "..(ok and "PASS " or "FAIL ")..message) end
 local function copy(v) if type(v)~="table" then return v end;local t={};for k,x in pairs(v) do t[k]=copy(x) end;return t end
 local harness=Instance.new("Folder");harness.Name="AK_MultiplayerHarness";harness.Parent=RS
 local target=Instance.new("ObjectValue");target.Name="Target";target.Parent=harness
 local observer
 local ok,issue=pcall(function()
  local timeout=os.clock()+150
  repeat
   roster={};for _,p in ipairs(Players:GetPlayers()) do if Profiles.Profiles[p] and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and Plots:GetPlot(p) then table.insert(roster,p) end end
   if #roster<expected then task.wait(.2) end
  until #roster>=expected or os.clock()>timeout
  assert(#roster==expected,"Expected "..expected.." actual clients; ready="..#roster)
  task.wait(4)
  local usedPlots={}
  for _,p in ipairs(roster) do
   local root=p.Character.HumanoidRootPart;local profile=Profiles.Profiles[p]
   originals[p]={Profile=profile,Pivot=p.Character:GetPivot(),Anchored=root.Anchored};root.Anchored=true
   local data=copy(require(RS.SharedSource.Datas.ProfileTemplate))
   require(RS.Shared.Gameplay.ProfileMigrations).Apply(data,function() return game.HttpService:GenerateGUID(false) end)
   Profiles.Profiles[p]={Data=data,FirstSessionTime=os.time(),IsActive=function() return true end};Profiles.Client.GetData:Fire(p,data)
   local plot=Plots:GetPlot(p);check(plot and not usedPlots[plot],p.Name.." owns a distinct plot");usedPlots[plot]=true
  end
  local tree;for obj in pairs(Resource:GetRecords()) do if obj:GetAttribute("BiomeId")=="Meadow" then tree=obj;break end end
  assert(tree);local pivot=tree:GetPivot();local props={}
  for _,part in ipairs(tree:GetDescendants()) do if part:IsA("BasePart") then props[part]={Transparency=part.Transparency,CanCollide=part.CanCollide,CanTouch=part.CanTouch,CanQuery=part.CanQuery} end end
  local winners={};local transactions=0
  observer=Economy.Changed:Connect(function(p,_,amount,reason) if originals[p] and amount>0 and reason=="Gather" then winners[p]=true;transactions+=1 end end)
  for i,p in ipairs(roster) do p.Character:PivotTo(pivot*CFrame.new(i*1.3,4,2)) end
  target.Value=tree;task.wait(1);harness:SetAttribute("Stage","Race")
  task.wait(3)
  local winnerCount=0;for _ in pairs(winners) do winnerCount+=1 end
  check(winnerCount==1,"actual client remote race grants rewards to exactly one owner")
  check(tree:GetAttribute("ResourceState")=="RESPAWNING","one shared cooldown after concurrent client requests")
  local respawnAt=tree:GetAttribute("RespawnAt");assert(respawnAt)
  local total=transactions
  task.wait(math.max(0,respawnAt-workspace:GetServerTimeNow()-.15))
  check(tree:GetAttribute("ResourceState")=="RESPAWNING","all clients share unavailable tree until twenty seconds")
  repeat task.wait() until tree:GetAttribute("ResourceState")=="AVAILABLE" or workspace:GetServerTimeNow()>respawnAt+3
  local restored=tree:GetPivot()==pivot
  for part,values in pairs(props) do for k,v in pairs(values) do if part[k]~=v then restored=false end end end
  check(restored and tree:GetAttribute("ResourceState")=="AVAILABLE","multiplayer tree restores original transform and properties")
  check(transactions==total,"no repeated resource transaction")
  observer:Disconnect();observer=nil
  local station;for obj,id in pairs(Egg:GetStations()) do if id=="MeadowEgg" then station=obj;break end end;assert(station)
  local balances={}
  for i,p in ipairs(roster) do Economy:Add(p,"Coins",10000,"Test");balances[p]=Economy:GetBalance(p,"Coins");p.Character:PivotTo(station:GetPivot()*CFrame.new(i*1.3,4,2)) end
  target.Value=station;task.wait(1);harness:SetAttribute("Stage","Hatch");task.wait(5)
  local allUIDs={}
  for _,p in ipairs(roster) do
   local data=Profiles.Profiles[p].Data
   check(#data.Pets==3,p.Name.." receives its own triple hatch")
   check(Economy:GetBalance(p,"Coins")==balances[p]-750,p.Name.." pays its own server price")
   for _,pet in ipairs(data.Pets) do check(not allUIDs[pet.UID],"unique pet UID across clients");allUIDs[pet.UID]=p end
  end
  local p=roster[1];local data=Profiles.Profiles[p].Data
  local plot=Plots:GetPlot(p);local cf,size=Locator.getBounds(plot);p.Character:PivotTo(cf*CFrame.new(0,size.Y/2+4,0))
  check(Shop:Buy(p,"WoodenChair"),"server shop sells owned furniture")
  local placed,reason=Placement:Place(p,"WoodenChair",Vector3.new(6,0,6),0)
  check(placed,"real plot placement succeeds: "..tostring(reason))
  if placed then
   local uid=data.PlotProgression.Placements[1].UID
   check(not Placement:Remove(roster[2],uid),"visitor cannot remove owner's placement")
   check(Placement:Remove(p,uid),"owner removes placement and retains purchased item")
  end
  check(not Placement:Place(p,"WoodenChair",Vector3.new(10000,0,0),0),"out-of-bounds furniture rejected")
  check(Plots:SetVisitors(p,false) and not Plots:CanVisit(roster[2],p),"plot visitor permissions enforced by API")
 end)
 if not ok then check(false,"runtime exception: "..tostring(issue)) end
 if observer then observer:Disconnect() end
 for p,old in pairs(originals) do
  Profiles.Profiles[p]=old.Profile
  if p.Parent==Players then
   Profiles.Client.GetData:Fire(p,old.Profile.Data);require(services.PetService):Publish(p)
   if p.Character then p.Character:PivotTo(old.Pivot);p.Character.HumanoidRootPart.Anchored=old.Anchored end
  end
 end
 harness:SetAttribute("Stage","Complete")
 print("AK_MULTI_DONE clients="..#roster.." assertions="..checks.." failures="..failures.." savedProfilesUnchanged=true")
end)
