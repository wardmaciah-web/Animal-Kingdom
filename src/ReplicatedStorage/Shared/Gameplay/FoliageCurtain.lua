-- Camera-relative, client-only clones. Authored world foliage is never moved.
local RS=game:GetService("ReplicatedStorage")
local F={}
function F.Create(parent,initialCamera)
 local folder=Instance.new("Folder");folder.Name="OpeningFoliage";folder.Parent=parent
 local templates={}
 local env=workspace:FindFirstChild("BiomeEnvironments")
 local forest=env and env:FindFirstChild("ForestEnvironment")
 local plants=forest and forest:FindFirstChild("Scenery")and forest.Scenery:FindFirstChild("Plants")
 if plants then for _,model in plants:GetChildren()do
  if model:IsA("Model")and model.Name:find("bushDetailed",1,true)then table.insert(templates,model)end
 end end
 assert(#templates>0,"Existing foliage templates unavailable")
 local pieces={}
 for layer=1,2 do for row=-1,1 do for col=-1,1 do
  local model=templates[(#pieces%#templates)+1]:Clone();model.Name="LeafCluster"
  for _,x in model:GetDescendants()do
   if x:IsA("BasePart")then x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=false;x.CastShadow=false;x.Material=Enum.Material.SmoothPlastic
   elseif x:IsA("LuaSourceContainer")or x:IsA("Constraint")then x:Destroy()end
  end
  local _,size=model:GetBoundingBox();model:ScaleTo(model:GetScale()*8/math.max(size.X,size.Y,size.Z))
  model.Parent=folder
  local center=model:GetBoundingBox();local correction=model:GetPivot():ToObjectSpace(center):Inverse()
  table.insert(pieces,{Model=model,Offset=Vector3.new(col*3.8+(layer-1)*.4,row*2.65,-5.8-(layer-1)*2.2),Side=col==0 and(row%2==0 and 1 or -1)or col,Top=row==1,Correction=correction,Phase=#pieces*1.71})
 end end end
 -- Reuse the authored forest root mesh as branching silhouettes overhead.
 local branches={};local branchTemplate=plants and plants:FindFirstChild("Forest_Decor_Root_1_46")
 if branchTemplate and branchTemplate:IsA("Model")then
  for i=1,3 do
   local model=branchTemplate:Clone();model.Name="CanopyBranch"
   for _,x in model:GetDescendants()do if x:IsA("BasePart")then x.Anchored=true;x.CanCollide=false;x.CanQuery=false;x.CanTouch=false;x.CastShadow=false elseif x:IsA("LuaSourceContainer")then x:Destroy()end end
   local _,size=model:GetBoundingBox();model:ScaleTo(model:GetScale()*8/math.max(size.X,size.Y,size.Z));model.Parent=folder
   local center=model:GetBoundingBox()
   branches[i]={Model=model,Correction=model:GetPivot():ToObjectSpace(center):Inverse()}
  end
 end
 local leaves={}
 for i=1,8 do
  local leaf=Instance.new("Part");leaf.Name="DriftingLeaf";leaf.Shape=Enum.PartType.Ball;leaf.Size=Vector3.new(.16,.4,.045);leaf.Color=Color3.fromRGB(137+i*5,174+i*4,80);leaf.Material=Enum.Material.SmoothPlastic;leaf.Anchored=true;leaf.CanCollide=false;leaf.CanQuery=false;leaf.CanTouch=false;leaf.CastShadow=false;leaf.Parent=folder;leaves[i]=leaf
 end
 local mote=Instance.new("Part");mote.Name="PollenAnchor";mote.Size=Vector3.new(.1,.1,.1);mote.Transparency=1;mote.Anchored=true;mote.CanCollide=false;mote.CanQuery=false;mote.CanTouch=false;mote.Parent=folder
 local pollen=Instance.new("ParticleEmitter");pollen.Name="OpeningPollen";pollen.Texture="rbxasset://textures/particles/sparkles_main.dds";pollen.Rate=12;pollen.Lifetime=NumberRange.new(1.5,3);pollen.Speed=NumberRange.new(.3,1);pollen.SpreadAngle=Vector2.new(160,160);pollen.Size=NumberSequence.new(.065);pollen.Color=ColorSequence.new(Color3.fromRGB(244,228,151));pollen.LightEmission=.7;pollen.Parent=mote
 local light=Instance.new("PointLight");light.Color=Color3.fromRGB(255,231,174);light.Range=22;light.Brightness=.2;light.Parent=mote
 local state={Folder=folder}
 function state.Update(camera,seconds)
  local a=math.clamp((seconds-.35)/3.65,0,1);a=a*a*(3-2*a)
  for _,v in pieces do
   local shake=math.sin(seconds*6+v.Phase)*.035*(1-a)
   local offset=v.Offset+Vector3.new(v.Side*a*(v.Top and 5 or 12),v.Top and a*10 or -a*.9,-a*2)
   v.Model:PivotTo(camera*CFrame.new(offset)*CFrame.Angles(math.rad(65)+shake,v.Phase*.55+math.sin(seconds*2+v.Phase)*.045,v.Side*a*.35+shake)*v.Correction)
  end
  for i,v in branches do v.Model:PivotTo(camera*CFrame.new((i-2)*4,1.8+a*10,-7)*CFrame.Angles(.2,0,(i-2)*.25+a*.2)*v.Correction)end
  for i,leaf in leaves do leaf.CFrame=camera*CFrame.new(math.sin(i*2.4+seconds*.8)*4,2.5-((seconds*.8+i*.7)%5),-3-(i%3))*CFrame.Angles(seconds+i,i,seconds*.6)end
  mote.CFrame=camera*CFrame.new(0,0,-4);light.Brightness=.2+a*2
  folder:SetAttribute("OpenFraction",a)
 end
 function state.Destroy()folder:Destroy()end
 state.Update(initialCamera,0)
 return state
end
return F
