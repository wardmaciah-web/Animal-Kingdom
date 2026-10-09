-- Manual, temporary Studio harness. Never Rojo-map this into production.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
local S=game.ServerScriptService.ServerSource.Server
assert(S.ProfileService:GetAttribute("AKJungleQAStore")=="AKJungleTreeQA_4e9674b_20261009","Isolated datastore required")
assert(S.ProfileService:GetAttribute("AKUseMockProfiles")==false,"Durable isolated QA store required")
local RS=game.ReplicatedStorage
local result=Instance.new("StringValue");result.Name="AKJungleQAResult";result.Parent=RS
local report={store="AKJungleTreeQA_4e9674b_20261009",checks={},stage="starting"}
local function emit() result.Value=game.HttpService:JSONEncode(report) end
local function check(ok,message) assert(ok,message);table.insert(report.checks,message);emit() end
local Profiles=require(S.ProfileService);local Pets=require(S.PetService)
local Resource=require(S.ResourceService);local Egg=require(S.EggService)
local B=require(RS.Shared.Gameplay.Definitions.BiomeDefinitions)
local F=require(RS.Shared.Gameplay.Definitions.TreeFamilyDefinitions)
local E=require(RS.Shared.Gameplay.Definitions.EggDefinitions)
local player=game.Players:GetPlayers()[1]
local deadline=os.clock()+60
while not player or not Profiles.Profiles[player] or not player.Character or not player:GetAttribute("HasPlot") do
 assert(os.clock()<deadline,"Player readiness timed out");task.wait(.25);player=game.Players:GetPlayers()[1]
end
local profile=Profiles.Profiles[player];local data=profile.Data
local originalReady=B.Jungle.ContentReady;local originalUnlock=data.UnlockedBiomes.Jungle
local originalPivot=player.Character:GetPivot()
local root=player.Character:FindFirstChild("HumanoidRootPart");local anchored=root.Anchored
local ok,issue=xpcall(function()
 check(not originalReady,"Jungle publicly locked before test")
 local trees={};local count=0
 for tree,record in Resource:GetRecords() do if record.Biome=="Jungle" then
  count+=1;local f=assert(F.ResolveJungle(tree));trees[f.Id]=trees[f.Id] or tree
  check(not record.Prompt.Enabled and record.Prompt.ActionText=="COMING SOON","Locked prompt "..count)
 end end
 check(count==35,"All 35 physical Jungle trees registered")
 if data.AKJungleTreeQA then
  local saved=data.AKJungleTreeQA;report.session=2
  for id,expected in saved.pets do
   local p=Pets:FindOwned(data,expected.uid)
   check(p and p.PetId==id and p.UniquePetId==expected.uid and p.Weight==expected.weight and p.Location==expected.location,"Rejoin identity/weight/location "..id)
  end
  check(data.ActiveHeldPetUID==saved.active,"Rejoin active follower UID")
  report.pets=saved.pets;report.stage="rejoin_pass";report.passed=true;return
 end
 report.session=1
 data.Currencies.Coins=50000;data.UnlockedBiomes.Jungle=true
 root.Anchored=true
 local received={};local uids={}
 for _,row in {{"Jungle_Shakeable_03","JungleOcelot"},{"Jungle_Shakeable_04","JungleRedPanda"}} do
  local tree=assert(trees[row[1]]);local record=Resource:GetRecords()[tree]
  player.Character:PivotTo(CFrame.new(record.InteractionPosition+Vector3.new(0,1,3)))
  local before=#data.Pets;local coins=data.Currencies.Coins
  local denied=Resource:Gather(player,tree)
  check(not denied and #data.Pets==before and data.Currencies.Coins==coins,"Coming Soon rejects actual gather "..row[2])
  task.wait(.5) -- Respect the existing server gather rate limiter after rejection.
  -- Only the running private Studio server's in-memory table changes. No source
  -- release configuration or public datastore is modified; finally restores it.
  B.Jungle.ContentReady=true
  local ready,why=Egg:CheckTreeHatch(player,tree)
  check(ready,"Actual pool/client assets ready "..row[2]..": "..tostring(why))
  local accepted,message=Resource:Gather(player,tree);check(accepted,"Physical tree gather accepted "..tostring(message))
  check(not Resource:Gather(player,tree),"Duplicate gather rejected")
  local timeout=os.clock()+8
  repeat task.wait(.1) until record.State~="SHAKING" or os.clock()>timeout
  B.Jungle.ContentReady=false
  check(record.State=="RESPAWNING" and #data.Pets==before+1,"Exactly one committed tree payout "..row[2])
  local pet=data.Pets[#data.Pets]
  check(pet.PetId==row[2] and pet.UID==pet.UniquePetId and not uids[pet.UID],"Server-owned unique species UID "..row[2]);uids[pet.UID]=true
  check(record.HatchResult.PoolId==row[1] and record.HatchResult.Cost==E[row[1]].Cost,"Canonical pool/cost retained")
  check(not Pets:Equip(player,"foreign-forged-uid",true),"Forged ownership UID rejected")
  check(Pets:Equip(player,pet.UID,true),"Held transition "..row[2])
  check(Pets:Move(player,pet.UID,"Inventory") and pet.Location=="Inventory","Inventory transition "..row[2])
  received[row[2]]=pet
  task.wait(5)
 end
 local ocelot=received.JungleOcelot;local panda=received.JungleRedPanda
 check(Pets:Equip(player,ocelot.UID,true),"Ocelot active Held/follower")
 local slot=assert(require(S.Parent.Utilities.MeadowSanctuaryDisplay).GetSlot(player,1),"Owned Sanctuary slot missing")
 player.Character:PivotTo(CFrame.new(slot.Surface+Vector3.new(0,2,3)))
 check(Pets:SwapSanctuary(player,ocelot.LocationSlot,1,ocelot.UID,""),"Physical owned Sanctuary placement")
 check(Pets:Equip(player,panda.UID,true),"Red Panda active Held/follower")
 report.pets={}
 for id,p in received do report.pets[id]={uid=p.UID,weight=p.Weight,location=p.Location,slot=p.LocationSlot} end
 data.AKJungleTreeQA={pets=report.pets,active=data.ActiveHeldPetUID}
 report.stage="save_requested";profile:Save();report.passed=true
end,debug.traceback)
B.Jungle.ContentReady=originalReady;data.UnlockedBiomes.Jungle=originalUnlock
root.Anchored=anchored;player.Character:PivotTo(originalPivot)
report.restored_jungle_lock=not B.IsContentReady("Jungle")
if not ok then report.passed=false;report.error=issue;report.stage="failed" end
emit()
