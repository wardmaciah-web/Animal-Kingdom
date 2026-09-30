assert(game:GetService("RunService"):IsStudio(),"Studio only")
local RS=game.ReplicatedStorage
local Http=game.HttpService
local K=require(RS.Packages.Knit)
K.OnStart():await()
local p=game.Players:GetPlayers()[1]
local Profile=K.GetService("ProfileService")
assert(Profile.Profiles[p] and Profile.Profiles[p].is_mock,"Mock profile required")
local Data=K.GetService("PlayerDataService")
local Pets=K.GetService("PetService")
local Resource=K.GetService("ResourceService")
local Egg=K.GetService("EggService")
local Sanctuary=K.GetService("SanctuaryService")
local Economy=K.GetService("EconomyService")
local Loot=K.GetService("LootService")
local defs=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Models=require(RS.Shared.Gameplay.PetModelValidation)
local audit=RS.MeadowLiveAudit
local data=Data:Get(p)
local results,physical,owned={},{},{}
local initialEquipped=table.clone(data.EquippedPets)
local initialDisplayed=table.clone(data.DisplayedPetIds)
local originalRoll=Loot.Roll
local forced
Loot.Roll=function(self,pool,...)
 if forced then
  for _,entry in ipairs(pool) do if entry.PetId==forced then return entry end end
  for _,entry in ipairs(pool) do if entry.Id=="Normal" then return entry end end
 end
 return originalRoll(self,pool,...)
end
local charges={}
local changed=Economy.Changed:Connect(function(who,currency,amount,reason)
 if who==p and reason=="MeadowTreeSearch" then table.insert(charges,{amount=amount,currency=currency}) end
end)
local trees={}
for object,record in pairs(Resource:GetRecords()) do
 if record.Biome=="Meadow" then table.insert(trees,object) end
end
table.sort(trees,function(a,b)
 local at,bt=a:GetAttribute("TreeTier"),b:GetAttribute("TreeTier")
 if at~=bt then return at<bt end
 return tostring(a:GetPivot().Position)<tostring(b:GetPivot().Position)
end)
for i,tree in ipairs(trees) do tree:SetAttribute("MeadowTestTreeId",i) end
local function persist()
 audit:SetAttribute("SpeciesResults",Http:JSONEncode(results))
 audit:SetAttribute("PhysicalResults",Http:JSONEncode(physical))
end
local function gotoTree(tree)
 local r=Resource:GetRecords()[tree]
 p.Character:PivotTo(CFrame.new(r.InteractionPosition+Vector3.new(0,3,5)))
 p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
 task.wait(.25)
end
local function treeFor(tier)
 for _,tree in ipairs(trees) do
  local r=Resource:GetRecords()[tree]
  if tree:GetAttribute("TreeTier")==tier and r.State=="AVAILABLE" then return tree end
 end
end
local function award(tree,id)
 gotoTree(tree)
 local before=#data.Pets;local paid=#charges
 forced=id
 local ok,why=Resource:Gather(p,tree)
 if not ok then forced=nil;return nil,{error=why} end
 task.wait(1.5)
 local r=Resource:GetRecords()[tree]
 local result=r.HatchResult
 forced=nil
 local pet=result and result.Results[1].Pet
 if not pet then return nil,{error="No committed hatch"} end
 local row={tree=tree:GetAttribute("MeadowTestTreeId"),path=tree:GetFullName(),tier=tree:GetAttribute("TreeTier"),pet=pet.PetId,
  onePet=#data.Pets==before+1,oneCharge=#charges==paid+1,charge=charges[#charges] and charges[#charges].amount,
  index=data.PetIndex[pet.PetId]~=nil,pool=result.PoolId,claimed=r.Awarded==true}
 return pet,row
end
local function perform()
 audit:SetAttribute("RunPhase","Deterministic awards")
 -- Cycle tiers so authored trees have their normal twenty-second respawn.
 for member=1,3 do for tier=2,5 do
  local def=defs.MeadowOrdered[(tier-1)*3+member]
  audit:SetAttribute("CurrentPet",def.PetId)
  local tree=treeFor(tier)
  local deadline=os.clock()+25
  while not tree and os.clock()<deadline do task.wait(.2);tree=treeFor(tier) end
  assert(tree,"No available physical tree")
  local pet,row=award(tree,def.PetId)
  results[def.PetId]=row
  if pet then owned[def.PetId]=pet;row.uid=pet.UID;row.forcedCorrect=pet.PetId==def.PetId end
  persist()
  task.wait(5.1)
 end end
 -- Tree 1 is deliberately blocked; direct mock grants exercise the two available visuals.
 for _,id in ipairs({"MeadowFieldMouse","MeadowChick"}) do
  local pet=Pets:Grant(p,id,"Normal",false,false)
  assert(pet,"Mock grant failed")
  owned[id]=pet;results[id]={uid=pet.UID,visualOnly=true,awardBlockedBy="Honey Lop Bunny",index=data.PetIndex[id]~=nil}
  RS.AnimalKingdomRemotes.GameplayFeedback:FireClient(p,{Action="StudioVisualCheck",Success=true,Result={Kind="Hatch",EggId="Meadow_Shakeable_01",Duration=1,Results={{Pet=pet,AutoDeleted=false,NewDiscovery=false}}}})
  persist();task.wait(5)
 end
 results.MeadowHoneyLop={error="No identified real model; pool unavailable"}
 audit:SetAttribute("RunPhase","Followers and Sanctuary")
 local plot=K.GetService("PlotService"):GetPlot(p)
 local plotCF=plot:IsA("BasePart") and plot.CFrame or plot:GetPivot()
 p.Character:PivotTo(plotCF+Vector3.new(0,8,0))
 task.wait(1)
 -- Only this disposable mock session changes equipped/displayed test selections.
 for _,uid in ipairs(table.clone(data.EquippedPets)) do Pets:Equip(p,uid,false) end
 for _,uid in ipairs(table.clone(data.DisplayedPetIds)) do Sanctuary.Client:SetPetDisplayed(p,uid,false);task.wait(.2) end
 for _,def in ipairs(defs.MeadowOrdered) do
  local pet=owned[def.PetId]
  if pet then
   audit:SetAttribute("CurrentPet",def.PetId)
   local row=results[def.PetId]
   row.inventoryOnlyIncome=Sanctuary:GetIncome(data)==0
   row.equipAccepted=Pets:Equip(p,pet.UID,true)
   row.equippedOnlyIncome=Sanctuary:GetIncome(data)==0
   row.displayAccepted=Sanctuary.Client:SetPetDisplayed(p,pet.UID,true)
   task.wait(.4)
   row.income=Sanctuary:GetIncome(data)
   row.incomePass=row.income==def.BaseIncomePerSecond
   local root=workspace:FindFirstChild("Sanctuaries")
   local folder=root and root:FindFirstChild(tostring(p.UserId))
   local display=folder and folder:FindFirstChild("DisplayedPets")
   local model=display and display:FindFirstChild(pet.UID)
   row.sanctuary=model and model:GetAttribute("PetTypeId")==def.PetId or false
   audit:SetAttribute("DisplayCheck",def.PetId)
   persist();task.wait(1)
   Sanctuary.Client:SetPetDisplayed(p,pet.UID,false)
   Pets:Equip(p,pet.UID,false)
   task.wait(.3)
  end
 end
 for _,uid in ipairs(initialEquipped) do Pets:Equip(p,uid,true) end
 for _,uid in ipairs(initialDisplayed) do Sanctuary.Client:SetPetDisplayed(p,uid,true);task.wait(.2) end
 audit:SetAttribute("RunPhase","Physical trees")
 for _,tree in ipairs(trees) do
  local tier=tree:GetAttribute("TreeTier")
  local r=Resource:GetRecords()[tree]
  while r.State~="AVAILABLE" do task.wait(.2) end
  gotoTree(tree)
  if tier==1 then
   local before=#data.Pets;local balance=data.Currencies.Coins;local n=#charges
   local ok,why=Resource:Gather(p,tree)
   table.insert(physical,{tree=tree:GetAttribute("MeadowTestTreeId"),tier=tier,path=tree:GetFullName(),blocked=not ok,reason=why,noCharge=#charges==n and data.Currencies.Coins==balance,noPet=#data.Pets==before,pool=tree:GetAttribute("EggId")})
   task.wait(.4)
  else
   local pet,row=award(tree,nil)
   row.validPool=pet and math.ceil(table.find(defs.MeadowOrdered,defs[pet.PetId])/3)==tier or false
   table.insert(physical,row)
   task.wait(5.1)
  end
  persist()
 end
 audit:SetAttribute("RunPhase","Complete")
end
local ok,err=xpcall(perform,debug.traceback)
Loot.Roll=originalRoll;changed:Disconnect();forced=nil
persist()
if not ok then audit:SetAttribute("Error",err);warn("[MeadowTest] "..err) end
audit:SetAttribute("Done",true)
