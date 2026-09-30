-- Run in Studio Play server. Clones remain unparented and are destroyed after each case.
-- Does not grant pets, modify templates, change profiles, or edit world geometry.
local RS = game:GetService("ReplicatedStorage")
local Geometry = require(RS.Shared.Gameplay.PetVisualGeometry)
local Appearance = require(RS.Shared.Gameplay.PetAppearance)
local Resolver = require(RS.Shared.Gameplay.PetModelResolver)
local Definitions = require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local report = { Checks = 0, Species = {}, Unavailable = {}, Failures = {} }
local function check(condition, message)
 report.Checks += 1
 if not condition then table.insert(report.Failures, message) end
end
local function close(a, b) return math.abs(a-b) < 0.002 end
local limits = Vector3.new(3.3722, 4.756, 3.3722)
for _, def in ipairs(Definitions.MeadowOrdered) do
 local source, issue = Resolver.Resolve(def.PetId)
 if not source then
  report.Unavailable[def.PetId] = issue
  continue
 end
 local original = source:GetPivot()
 local scale = source:GetScale()
 local pet = {PetId=def.PetId,Mutation="Normal",Level=1}
 local species = {}
 for _, context in ipairs({"Follower","Garden","Display"}) do
  local model = Appearance.Create(pet,context)
  check(model~=nil,def.PetId.." failed "..context.." clone")
  if model then
   for _, part in ipairs(model:GetDescendants()) do
    if part:IsA("BasePart") then check(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch,def.PetId.." clone collision") end
   end
   local bounds=Geometry.Measure(model)
   local before=bounds.Size
   if context=="Display" then bounds=Geometry.Fit(model,limits,CFrame.new(),def.DisplayScale) end
   for _, rotation in ipairs({CFrame.new(),CFrame.Angles(0,math.pi/2,0),CFrame.Angles(.06,1.3,.015)}) do
    model:PivotTo(Geometry.GroundCFrame(bounds,Vector3.new(7,10,-3),rotation,.04))
    local world=Geometry.Measure(model,CFrame.new())
    -- Rotating cached AABB is conservative: actual corners may sit higher, never below.
    check(world.Min.Y>=10.038,def.PetId.." bottom clipping "..context)
    check(close(world.Center.X,7) and close(world.Center.Z,-3),def.PetId.." center drift "..context)
   end
   species[context]={X=bounds.Size.X,Y=bounds.Size.Y,Z=bounds.Size.Z,BeforeLongest=math.max(before.X,before.Y,before.Z)}
   if context=="Display" then check(bounds.Size.X<=limits.X+.002 and bounds.Size.Z<=limits.Z+.002 and bounds.Size.Y<=limits.Y+.002,def.PetId.." display exceeds footprint") end
   check(model:GetAttribute("CanonicalMeadowPet")==true,def.PetId.." lost viewport texture tag")
   model:Destroy()
  end
 end
 report.Species[def.PetId]=species
 check(source:GetPivot()==original and close(source:GetScale(),scale),def.PetId.." template modified")
end
-- Off-center visible body + invisible root exercises imported pivots independently of the roster.
local model=Instance.new("Model")
local body=Instance.new("Part");body.Size=Vector3.new(2,4,3);body.CFrame=CFrame.new(3,6,-2)*CFrame.Angles(0,.6,0);body.Parent=model
local hidden=Instance.new("Part");hidden.Size=Vector3.new(100,100,100);hidden.Transparency=1;hidden.CFrame=CFrame.new(-20,30,9);hidden.Parent=model;model.PrimaryPart=hidden
local bounds=Geometry.Measure(model)
check(math.max(bounds.Size.X,bounds.Size.Y,bounds.Size.Z)<5,"Invisible pivot root inflated visible bounds")
model:PivotTo(Geometry.GroundCFrame(bounds,Vector3.zero,CFrame.Angles(.12,1.1,0),.04,-3))
check(Geometry.Measure(model,CFrame.new()).Min.Y>=.038,"Negative override caused clipping")
model:Destroy()
check(Resolver.Clone("__missing_pet__")==nil,"Missing pet manufactured a placeholder")
return report
