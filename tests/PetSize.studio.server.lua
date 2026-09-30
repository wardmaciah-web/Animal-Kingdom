local RS=game.ReplicatedStorage
local K=require(RS.Packages.Knit)
local P=K.GetService('PetService');local D=K.GetService('PlayerDataService')
local p=game.Players:GetPlayers()[1];local data=D:Get(p)
local Def=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Appearance=require(RS.Shared.Gameplay.PetAppearance)
local Resolver=require(RS.Shared.Gameplay.PetModelResolver)
local Geometry=require(RS.Shared.Gameplay.PetVisualGeometry)
local Label=require(RS.Shared.Gameplay.PetLabel)
local report={Assertions=0,Species={}}
local function check(v,m)report.Assertions+=1;assert(v,m)end
local function vec(v)return {v.X,v.Y,v.Z}end
assert(K.GetService('PlotService'):Teleport(p))
local displaySlot=8
for _,id in ipairs({'MeadowFieldMouse','MeadowFluffyLop','MeadowPrismAntlerDeer','ForestBlackBearCub','ForestBrownBat','ForestEmeraldWing'})do
 local template=assert(Resolver.Resolve(id));local originalScale=template:GetScale();local originalPivot=template:GetPivot()
 local rows={};local previous=0
 for _,ratio in ipairs({1,1.25,1.5,2,3})do
  local pet=assert(P:Grant(p,id,'Normal'));pet.Weight=Def[id].BaseWeight*ratio;P:RefreshStats(pet)
  local row={Ratio=ratio,Weight=pet.Weight,Income=pet.CoinsPerSecond,Contexts={}}
  for _,context in ipairs({'Follower','Preview','Garden'})do
   local model=assert(Appearance.Create(pet,context));local bounds=assert(Geometry.Measure(model));row.Contexts[context]=vec(bounds.Size)
   check(model:GetAttribute('WeightVisualScale')>=1,'No weight shrink')
   if context=='Follower'then check(bounds.Size.Magnitude>previous,'Follower scale increases');previous=bounds.Size.Magnitude end
   for _,part in ipairs(model:GetDescendants())do if part:IsA('BasePart')then check(not part.CanCollide and not part.CanTouch,'Visual collision disabled')end end
   model:Destroy()
  end
  displaySlot+=1;check(P:Move(p,pet.UID,'Sanctuary',displaySlot),'Place size matrix companion')
  row.UID=pet.UID;row.DisplaySlot=displaySlot;table.insert(rows,row)
 end
 check(template:GetScale()==originalScale and template:GetPivot()==originalPivot,'Canonical template unchanged')
 report.Species[id]=rows
end
P:Publish(p);task.wait(1)
local folder=workspace.Sanctuaries:FindFirstChild(tostring(p.UserId)).DisplayedPets
for id,rows in pairs(report.Species)do
 local previous=0
 for _,row in ipairs(rows)do
  local model=assert(folder:FindFirstChild(row.UID));local b=Geometry.Measure(model);row.Sanctuary=vec(b.Size)
  check(b.Size.Magnitude+0.001>=previous,'Sanctuary grows then safely caps');previous=b.Size.Magnitude
  local world=Geometry.Measure(model,CFrame.new());row.GroundClearance=world.Min.Y-model:GetAttribute('DisplaySurfaceY')
  check(math.abs(row.GroundClearance-.04)<.025,'Feet clear shelf')
  local label=model:FindFirstChild('PetInformation',true);check(label~=nil,'Bounds-based overhead')
 end
end
report.VisibleSanctuaryPets=#folder:GetChildren();report.TotalIncome=data.SanctuaryIncomePerSecond
return report
