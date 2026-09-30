assert(not game:GetService('RunService'):IsRunning(),'Edit mode required')
local recovery=game.ServerStorage.AK_AuditRecovery_20260917
local plan=assert(recovery:FindFirstChild('BiomeAlignmentPlan'))
assert(not plan:GetAttribute('Applied'),'Already applied')
local function archive(o,reason)
 o:SetAttribute('AuditOriginalPath',o:GetFullName());o:SetAttribute('AuditReason',reason);o.Parent=recovery
 print('[MapAudit] Archived '..o.Name..' — '..reason)
end
-- These stray imports lie ~90 studs above concrete outside their named biome.
for _,o in ipairs(workspace:GetChildren()) do
 if o:IsA('Model') then
  local cf,size=o:GetBoundingBox()
  if (o.Name=='Prehistoric_Decor_Root_5_40' or o.Name=='Prehistoric_Decor_log_large_79' or o.Name=='Prehistoric_Decor_Root_5_58' or o.Name=='Mythical_Decor_Root_6_71') and (cf.Y>90 or cf.Y<-50) then
   archive(o,'Misplaced import far above/below world and outside named biome; retained for reuse')
  end
 end
end
local partCount,rootCount=0,0
for _,group in ipairs(plan:GetChildren()) do
 local offset=group:GetAttribute('VerticalOffset');local delta=Vector3.new(0,offset,0)
 for _,entry in ipairs(group:GetChildren()) do
  local o=entry.Value
  if o and o:IsDescendantOf(workspace) and not o.Name:find('Reservation',1,true) and o:GetAttribute('EditorReferenceOnly')~=true then
   local parts={}
   if o:IsA('BasePart') then table.insert(parts,{o,o.CFrame}) end
   for _,p in ipairs(o:GetDescendants()) do if p:IsA('BasePart') then table.insert(parts,{p,p.CFrame}) end end
   o:PivotTo(entry:GetAttribute('OriginalPivot')+delta)
   for _,row in ipairs(parts) do
    assert((row[1].Position-row[2].Position-delta).Magnitude<.005,'Relative translation failed '..row[1]:GetFullName())
   end
   entry:SetAttribute('Applied',true);partCount+=#parts;rootCount+=1
  else entry:SetAttribute('Excluded',true) end
 end
 local floor=workspace[group.Name][group.Name..'Floor']
 assert(math.abs(floor.Position.Y+floor.Size.Y/2-group:GetAttribute('CorrectedSurfaceY'))<.001,'Floor mismatch '..group.Name)
 floor.Anchored=true;floor.CanCollide=true
 print(string.format('[MapAudit] Aligned %s original %.5f corrected %.5f offset %.5f',group.Name,group:GetAttribute('OriginalSurfaceY'),floor.Position.Y+floor.Size.Y/2,offset))
end
plan:SetAttribute('Applied',true)
workspace:SetAttribute('AK_CommonPlayableFloorY',workspace.Meadow.MeadowFloor.Position.Y+workspace.Meadow.MeadowFloor.Size.Y/2)
print(string.format('[MapAudit] BIOME_ALIGNMENT_PASS %d whole roots / %d parts; all internal relative positions preserved',rootCount,partCount))
local helperCount,anchored=0,0
for _,o in ipairs(workspace:GetDescendants()) do
 if o:IsA('BasePart') and not o:IsA('Terrain') then
  local ancestor=o:FindFirstAncestorOfClass('Model')
  local char=ancestor and ancestor:FindFirstChildOfClass('Humanoid')
  if o.Name=='RootPart' and o.Transparency==1 and o:GetFullName():find('MagicalForest',1,true) and not char then
   o:SetAttribute('AuditOriginalCanCollide',o.CanCollide);o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;helperCount+=1
  end
  if not o.Anchored and not char and not o:FindFirstAncestorOfClass('Tool') and o:GetAttribute('AK_Dynamic')~=true then
   o:SetAttribute('AuditOriginallyUnanchored',true);o.Anchored=true;anchored+=1
  end
 end
end
-- Ground the isolated, unsupported imported shrub, preserving its full shape.
for _,o in ipairs(workspace:GetChildren()) do
 if o:IsA('Model') and o.Name=='Forest_Decor_plant_bushDetailed_11' then
  local box,size=o:GetBoundingBox();local bottom=box.Y-size.Y/2
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={o};params.RespectCanCollide=true
  local hit=workspace:Raycast(Vector3.new(box.X,bottom+.1,box.Z),Vector3.new(0,-100,0),params)
  assert(hit and (hit.Instance==workspace.Forest.ForestFloor or hit.Instance==workspace.AnimalKingdomConcreteGround),'Shrub support requires review')
  o:SetAttribute('AuditOriginalPivot',o:GetPivot());o:PivotTo(o:GetPivot()+Vector3.new(0,hit.Position.Y-bottom,0))
  print('[MapAudit] Grounded '..o.Name..' offset '..(hit.Position.Y-bottom))
 end
end
local duplicate
for _,o in ipairs(workspace:GetChildren()) do
 if o:IsA('Model') and o.Name=='AK_AncientRuins_StylizedTree' then
  local box,size=o:GetBoundingBox()
  if math.abs(box.X+729.45355)<.01 and math.abs(box.Z-382.03613)<.01 then
   if duplicate then
    local a,b=duplicate:GetBoundingBox();assert((a.Position-box.Position).Magnitude<.01 and (b-size).Magnitude<.01)
    archive(o,'Exact coincident duplicate of retained Ancient Ruins tree')
   else duplicate=o end
  end
 end
end
-- Markers must match the corrected physical surfaces, without changing their X/Z.
local markers=workspace:FindFirstChild('BiomeTeleportPoints')
if markers then for _,p in ipairs(markers:GetChildren()) do
 if p:IsA('BasePart') then
  local id=p:GetAttribute('BiomeId') or p.Name:gsub('Spawn$','')
  local biome=workspace:FindFirstChild(id);local floor=biome and biome:FindFirstChild(id..'Floor')
  if floor then p.Position=Vector3.new(p.Position.X,floor.Position.Y+floor.Size.Y/2+.1,p.Position.Z) end
 end
end end
print(string.format('[MapAudit] Geometry fixes: %d invisible tree helpers, %d static parts anchored',helperCount,anchored))
