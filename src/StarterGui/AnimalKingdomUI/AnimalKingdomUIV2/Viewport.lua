local RS=game:GetService('ReplicatedStorage')
local Appearance=require(RS.Shared.Gameplay.PetAppearance)
local Geometry=require(RS.Shared.Gameplay.PetVisualGeometry)
local Definitions=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local PetWeight=require(RS.Shared.Gameplay.PetWeight)
local T=require(script.Parent.Theme)
local V={Budget=24}
-- A fixed authored-baseline camera makes the kg ladder visibly grow. This is
-- framing only: Appearance owns physical Model:ScaleTo, including huge pets.
-- Beyond the reference, emergency retreat permits increasing overscan rather
-- than fitting every owned specimen back to the same apparent dimensions.
-- The camera reference follows the canonical 10kg specimen; it is not a
-- second size curve and never changes the clone's physical dimensions.
local REFERENCE_CAMERA_SCALE=PetWeight.Scale({Weight=10})
local MAX_EMERGENCY_COVERAGE=1.7
local entries={}
local animated={}
local motionConnection
local RunService=game:GetService('RunService')
local ContentProvider=game:GetService('ContentProvider')
local loadedAssets={}
local function visible(view)
 if not view:IsDescendantOf(game) or view.AbsoluteSize.X<2 or view.AbsoluteSize.Y<2 then return false end
 local lo=view.AbsolutePosition;local hi=lo+view.AbsoluteSize
 local node=view
 while node do
  if node:IsA('GuiObject') then
   if not node.Visible then return false end
   if node.ClipsDescendants then
    local a=node.AbsolutePosition;local b=a+node.AbsoluteSize
    if hi.X<=a.X or hi.Y<=a.Y or lo.X>=b.X or lo.Y>=b.Y then return false end
   end
  elseif node:IsA('ScreenGui') and not node.Enabled then return false end
  node=node.Parent
 end
 return true
end
local function clear(e)
 if e.model then e.model:Destroy();e.model=nil end
 if e.world then e.world:Destroy();e.world=nil;e.model=nil end
 e.ready=false
end
local function frame(e)
 local model=e.model;if not model then return end
 local bounds=Geometry.Measure(model,CFrame.new());if not bounds then return end
 if e.period or e.showcase then
  local radius=Vector2.new(bounds.Size.X,bounds.Size.Z).Magnitude/2
  bounds={Center=Vector3.zero,Corners={}}
  local h=e.height or select(2,model:GetBoundingBox()).Y
  for _,x in ipairs({-radius,radius})do for _,y in ipairs({-h/2,h/2})do for _,z in ipairs({-radius,radius})do table.insert(bounds.Corners,Vector3.new(x,y,z))end end end
 end
 local weightScale=model:GetAttribute('WeightVisualScale')
 local ownedSpecimen=weightScale and (model:GetAttribute('OwnedPetInstanceId')~=nil or (e.pet and type(e.pet.Weight)=='number'))
 local aspect=math.max(e.view.AbsoluteSize.X,1)/math.max(e.view.AbsoluteSize.Y,1)
 local rotation=CFrame.lookAt(Vector3.new(.24,.13,-1),Vector3.zero).Rotation
 local tan=math.tan(math.rad(e.camera.FieldOfView/2));local distance=.1
 local referenceDistance=.1
 local coverage=ownedSpecimen and (1+(MAX_EMERGENCY_COVERAGE-1)*math.max(0,1-REFERENCE_CAMERA_SCALE/weightScale))or 1
 for _,corner in ipairs(bounds.Corners) do
  local p=rotation:VectorToObjectSpace(corner-bounds.Center)
  local extent=math.max(math.abs(p.X)/(tan*aspect),math.abs(p.Y)/tan)
  local fitted=p.Z+1.13*extent
  if ownedSpecimen then
   referenceDistance=math.max(referenceDistance,fitted*REFERENCE_CAMERA_SCALE/weightScale)
   -- p.Z stays physical so the camera cannot move inside the oversized model.
   distance=math.max(distance,p.Z+1.13*extent/coverage)
  else distance=math.max(distance,fitted)end -- species-only Index silhouettes
 end
 if ownedSpecimen then distance=math.max(distance,referenceDistance)end
 e.camera.CFrame=CFrame.new(bounds.Center+rotation.ZVector*distance)*rotation
 local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
 for _,corner in ipairs(bounds.Corners)do
  local p=rotation:VectorToObjectSpace(corner-bounds.Center)
  local depth=math.max(.001,distance-p.Z)
  local x,y=p.X/(depth*tan*aspect),p.Y/(depth*tan)
  minX=math.min(minX,x);maxX=math.max(maxX,x);minY=math.min(minY,y);maxY=math.max(maxY,y)
 end
 e.view:SetAttribute('FramedDistance',distance)
 e.view:SetAttribute('WeightVisualScale',weightScale)
 e.view:SetAttribute('ReferenceFramedDistance',ownedSpecimen and referenceDistance or nil)
 e.view:SetAttribute('EmergencyFraming',ownedSpecimen and distance>referenceDistance+.001 or false)
 e.view:SetAttribute('ProjectedWidthFraction',(maxX-minX)/2)
 e.view:SetAttribute('ProjectedHeightFraction',(maxY-minY)/2)
end
local function mount(e)
 local model=e.source
 if not model then model=Appearance.Create(e.pet,'Preview') end
 e.source=nil
 if not model then e.message.Text=e.silhouette and '?' or 'Preview unavailable';e.message.Visible=true;e.missing=true;return end
 local def=Definitions[model:GetAttribute('PetTypeId') or (e.pet and e.pet.PetId)]
 for _,p in ipairs(model:GetDescendants()) do
  if p:IsA('BillboardGui') or p:IsA('ParticleEmitter') or p:IsA('Trail') or p:IsA('Beam') then p:Destroy()
  elseif p:IsA('BasePart') then
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
   if e.silhouette then
    p.Color=T.Color.WoodDark;p.Material=Enum.Material.SmoothPlastic
    if p:IsA('MeshPart') then p.TextureID='' end
    for _,surface in ipairs(p:GetChildren()) do if surface:IsA('SurfaceAppearance') or surface:IsA('Decal') or surface:IsA('Texture') then surface:Destroy() end end
   end
  end
 end
 -- Authored SurfaceAppearance and MeshPart textures are preserved in normal previews.
 local rotation=Geometry.ContextRotation(def,'Preview')
 model:PivotTo(rotation)
 local b=Geometry.Measure(model,CFrame.new());if not b then model:Destroy();return end
 model:PivotTo(CFrame.new(-b.Center)*model:GetPivot())
 e.world=Instance.new('WorldModel');e.world.Name='PreviewWorld';e.world.Parent=e.view
 e.model=model;e.base=model:GetPivot();e.height=b.Size.Y;e.message.Visible=true
 local assets={}
 for _,part in ipairs(model:GetDescendants())do
  if part:IsA('MeshPart')then
   for _,id in ipairs({part.MeshId,part.TextureID})do if id~='' and not loadedAssets[id]then table.insert(assets,id)end end
  elseif part:IsA('SurfaceAppearance')then
   for _,property in ipairs({'ColorMap','NormalMap','MetalnessMap','RoughnessMap'})do
    local ok,id=pcall(function()return part[property..'Content'].Uri end)
    if ok and id~=''and not loadedAssets[id]then table.insert(assets,id)end
   end
  end
 end
 local world=e.world
 task.spawn(function()
  local failed=false
  if #assets>0 then
   local ok=pcall(function()ContentProvider:PreloadAsync({model},function(id,status)
    if status==Enum.AssetFetchStatus.Success then loadedAssets[id]=true else failed=true end
   end)end)
   failed=failed or not ok
  end
  if not entries[e.view] or e.world~=world or e.model~=model then return end
  if failed then
   e.message.Text='Preview temporarily unavailable';e.missing=true
   warn('[PetViewport] Asset loading failed for '..tostring(e.pet and e.pet.PetId or model.Name))
  else model.Parent=world;e.ready=true;e.message.Visible=false;e.view:SetAttribute('PreviewReady',true)end
 end)
 if e.showcase then
  local diameter=math.max(b.Size.X,b.Size.Z)/(model:GetAttribute('WeightVisualScale')or 1)*1.22
  for i,style in ipairs({{Size=diameter,Color=T.Color.Gold},{Size=diameter*.92,Color=T.Color.Wood}})do
   local disc=Instance.new('Part');disc.Name='ShowcaseStage';disc.Shape=Enum.PartType.Cylinder;disc.Size=Vector3.new(.06,style.Size,style.Size);disc.CFrame=CFrame.new(0,-b.Size.Y/2-.06+(i-1)*.035,0)*CFrame.Angles(0,0,math.pi/2);disc.Anchored=true;disc.CanCollide=false;disc.Color=style.Color;disc.Material=Enum.Material.SmoothPlastic;disc.Parent=e.world
  end
 end
 frame(e)
end
local function create(p,pet,model,size,pos,silhouette)
 local view=Instance.new('ViewportFrame');view.Name='PetPreview';view.BackgroundTransparency=1;view.Size=size;view.Position=pos or UDim2.new();view.Ambient=Color3.fromRGB(210,210,210);view.LightColor=Color3.fromRGB(255,247,228);view.LightDirection=Vector3.new(-.6,-.8,-1);view.Parent=p
 local camera=Instance.new('Camera');camera.FieldOfView=35;camera.Parent=view;view.CurrentCamera=camera
 local msg=Instance.new('TextLabel');msg.Name='PreviewState';msg.Size=UDim2.fromScale(1,1);msg.BackgroundTransparency=1;msg.Font=T.Font;msg.TextSize=14;msg.TextColor3=T.Color.Muted;msg.TextWrapped=true;msg.Text='Loading companion…';msg.Parent=view
 local e={view=view,camera=camera,pet=pet,source=model,message=msg,silhouette=silhouette};entries[view]=e
 if pet then view:SetAttribute('PetTypeId',pet.PetId) end
 local connection=view:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()frame(e)end)
 view.Destroying:Once(function()connection:Disconnect();clear(e);if e.source then e.source:Destroy()end;entries[view]=nil;animated[view]=nil end)
 return view
end
function V.Pet(p,pet,size,pos,silhouette) return create(p,pet,nil,size,pos,silhouette) end
function V.Model(p,model,size,pos) return create(p,nil,model,size,pos,false) end
local function startMotion()
 if motionConnection then return end
 motionConnection=RunService.RenderStepped:Connect(function(dt)
  local active=false
  for view,e in pairs(animated)do
   if not entries[view] then animated[view]=nil
   else
    active=true
    if e.model and visible(view)then
     e.elapsed=(e.elapsed or 0)+math.min(dt,.1)
     if e.animation then
      if e.animation(e.model,e.base,e.elapsed)==false then e.animation=nil;if not e.period then animated[view]=nil end end
     elseif e.period then e.model:PivotTo(CFrame.Angles(0,e.elapsed*math.pi*2/e.period,0)*e.base)end
    end
   end
  end
  if not active then motionConnection:Disconnect();motionConnection=nil end
 end)
end
function V.Showcase(view)local e=entries[view];if e then e.showcase=true end end
function V.Ready(view)local e=entries[view];return e and e.ready==true end
function V.Turntable(view,seconds)
 local e=entries[view];if not e then return end
 e.period=seconds;e.elapsed=0;animated[view]=seconds and e or nil;frame(e);if seconds then startMotion()end
end
function V.Animate(view,callback)
 local e=entries[view];if not e then return end
 e.animation=callback;e.elapsed=0;animated[view]=e;startMotion()
end
function V.Stats() local live,total=0,0;for _,e in pairs(entries) do total+=1;if e.model then live+=1 end end;return {Live=live,Registered=total,Budget=V.Budget} end
-- One low-rate visibility scheduler; static previews never use RenderStepped.
local alive=true
script.Destroying:Once(function()alive=false;if motionConnection then motionConnection:Disconnect()end;for _,e in pairs(entries) do clear(e) end end)
task.spawn(function()
 while alive do
  local count=0
  for _,e in pairs(entries) do
   if visible(e.view) and count<V.Budget then
    count+=1;if not e.model and not e.missing then mount(e) end
   elseif e.model and e.pet then clear(e) end
  end
  task.wait(.2)
 end
end)
return V
