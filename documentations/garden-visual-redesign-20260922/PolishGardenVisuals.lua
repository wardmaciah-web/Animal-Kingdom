assert(not game:GetService('RunService'):IsRunning())
local g=workspace.PetGardenRealm
local d=g.GardenLandscape
local CS=game:GetService('CollectionService')
-- Remove the copied decorative trim that accompanied the fourth plot template.
local trim={}
for _,v in g.GardenPlot4:GetChildren() do if v.Name=='VisualTrim' then table.insert(trim,v) end end
if #trim>1 then trim[1]:Destroy() end
for _,v in g:GetDescendants() do
 if v:IsA('SurfaceGui') then
  v.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;v.PixelsPerStud=45;v.LightInfluence=.2
  for _,t in v:GetDescendants() do if t:IsA('TextLabel') then t.TextScaled=true;t.TextWrapped=true;t.Size=UDim2.fromScale(.92,.8);t.Position=UDim2.fromScale(.04,.1) end end
 end
end
local function cloneAt(src,name,x,z,bottom,h,yaw,parent)
 local m=src:Clone()
 for _,v in {m,table.unpack(m:GetDescendants())} do
  for _,t in CS:GetTags(v) do CS:RemoveTag(v,t) end
  for k in v:GetAttributes() do v:SetAttribute(k,nil) end
  if v:IsA('LuaSourceContainer') or v:IsA('ProximityPrompt') or v:IsA('ClickDetector') then v:Destroy()
  elseif v:IsA('BasePart') then v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false end
 end
 m.Name=name;m.Parent=parent
 local _,s=m:GetBoundingBox();m:ScaleTo(m:GetScale()*h/s.Y)
 m:PivotTo(CFrame.new(2000+x,0,2000+z)*CFrame.Angles(0,math.rad(yaw),0))
 local cf,sz=m:GetBoundingBox();m:PivotTo(m:GetPivot()+Vector3.new(2000+x-cf.Position.X,bottom-(cf.Position.Y-sz.Y/2),2000+z-cf.Position.Z))
 m:SetAttribute('GardenVisualOnly',true);m:SetAttribute('SourceAssetName',src.Name);return m
end
-- Broader variation: branchy oaks and the existing layered common-tree mesh.
for _,m in d.Planting:GetChildren() do
 local i=tonumber(m.Name:match('^PerimeterOak_(%d+)$'))
 if i and i%3~=0 then
  local cf,s=m:GetBoundingBox();local x,z=cf.Position.X-2000,cf.Position.Z-2000
  local src=i%3==1 and workspace.Tree_Oak_7_V5_001 or workspace.CommonTree_5_V5_040
  cloneAt(src,m.Name,x,z,31,s.Y,i*71,d.Planting);m:Destroy()
 end
end
local old=d.Planting.CourtOak
cloneAt(workspace.Tree_Oak_7_V5_001,'CourtOak',0,-1,33.1,21,42,d.Planting);old:Destroy()
-- Low planted borders soften the back of each plot while leaving all fronts open.
local borders=Instance.new('Folder');borders.Name='PlotFlowerBorders';borders.Parent=d
for i,p in {{-37,-11.8},{37,-11.8},{-37,-58.8},{37,-58.8}} do
 local soil=Instance.new('Part');soil.Name='MulchedFlowerBorder';soil.Size=Vector3.new(29,.18,2.1);soil.Position=Vector3.new(2000+p[1],31.12,2000+p[2]);soil.Color=Color3.fromRGB(89,77,48);soil.Material=Enum.Material.Ground;soil.Anchored=true;soil.CanCollide=false;soil.CanTouch=false;soil.CanQuery=false;soil.Parent=borders
 for j=-2,2 do
  cloneAt(workspace.Forest_Decor_plant_bushDetailed_51,'BorderFoliage',p[1]+j*5.3,p[2],31.2,1.65,j*47,borders)
  if j%2==0 then cloneAt(workspace.MagicalForest_Decor_Flower_Violet_2_35,'BorderViolets',p[1]+j*5.3+1.5,p[2],31.2,2,j*59,borders) end
 end
end
-- Tint only copied lanterns to match the cedar-and-sage garden palette.
for _,m in d.GardenDetails:GetChildren() do if m.Name:match('^GardenLantern_') then
 for _,v in m:GetDescendants() do if v:IsA('BasePart') then
  v.Color=Color3.fromRGB(92,108,83);v.Material=Enum.Material.Metal
  if v:IsA('MeshPart') then v.TextureID='' end
 elseif v:IsA('SurfaceAppearance') then v:Destroy() end end
end end
-- Return sign posts originally belonged to the small wayfinding board. Raise them into the gate.
for _,v in d.GardenDetails:GetChildren() do if v.Name=='ReturnWayfindingPost' then v.Size=Vector3.new(.4,3,.4);v.Position=Vector3.new(v.Position.X,40.5,v.Position.Z) end end
if workspace:FindFirstChild('GardenTreeReview_TEMP') then workspace.GardenTreeReview_TEMP:Destroy() end
game:GetService('ChangeHistoryService'):SetWaypoint('Garden Visual Polish and Labels')
return 'Plot labels, tree variety, planted borders and lanterns refined'
