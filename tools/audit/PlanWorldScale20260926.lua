-- READ ONLY: explicit instance manifest and prospective collision check. Does not transform anything.
local pivot=Vector3.new(-237.352539,9.128930,192.420868)
local factor=.95
local biomes={'Meadow','Forest','Jungle','Desert','Snow','Volcano','Ocean','AncientRuins','MagicalForest','Sky','Prehistoric','Mythical'}
local floors={};for _,id in ipairs(biomes)do local root=workspace:FindFirstChild(id);floors[id]=root and root:FindFirstChild(id..'Floor')end
local function vector(v)return {v.X,v.Y,v.Z}end
local function frame(cf)return {cf:GetComponents()}end
local function bounds(o)
 if o:IsA('BasePart')then return o.CFrame,o.Size end
 if o:IsA('Model') and o:FindFirstChildWhichIsA('BasePart',true)then return o:GetBoundingBox()end
end
local function box(cf,size)
 local low,high=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,x in ipairs({-.5,.5})do for _,y in ipairs({-.5,.5})do for _,z in ipairs({-.5,.5})do
  local p=cf:PointToWorldSpace(size*Vector3.new(x,y,z));low=low:Min(p);high=high:Max(p)
 end end end
 return low,high
end
local function ordinal(o)
 local path={};while o and o~=game do
  local n=0;for _,sibling in ipairs(o.Parent:GetChildren())do if sibling.Name==o.Name then n+=1 end;if sibling==o then break end end
  table.insert(path,1,{Name=o.Name,Ordinal=n});o=o.Parent
 end;return path
end
local function record(o,reason)
 local cf,size=bounds(o);local data={Path=o:GetFullName(),Selector=ordinal(o),Class=o.ClassName,Reason=reason,Attributes={},VectorAttributes={}}
 pcall(function()data.DebugId=o:GetDebugId(32)end)
 pcall(function()data.UniqueId=tostring(o.UniqueId)end)
 for k,v in pairs(o:GetAttributes())do if typeof(v)=='Vector3'then data.VectorAttributes[k]=vector(v)elseif type(v)=='string' or type(v)=='number' or type(v)=='boolean'then data.Attributes[k]=v end end
 if cf then data.BoundsCFrame=frame(cf);data.Size=vector(size)end
 if o:IsA('BasePart')then data.CFrame=frame(o.CFrame);if o:IsA('MeshPart')then data.MeshId=o.MeshId end end
 if o:IsA('Model')then data.Pivot=frame(o:GetPivot());data.ModelScale=o:GetScale()end
 return data
end
local function stand(o)
 if o:IsA('MeshPart')and o.MeshId:find('128975267139927',1,true)then return true end
 for _,p in ipairs(o:GetDescendants())do if p:IsA('MeshPart')and p.MeshId:find('128975267139927',1,true)then return true end end
 return false
end
local excludedNames={PetGardenRealm=true,PlayerPlots=true,Sanctuaries=true,AnimalKingdomFuturePlayerPlots=true,Plot4Reservation=true,AnimalKingdomConcreteGround=true,GrassFloor=true,World=true,AnimalKingdomTown=true,AK_AuditPerimeter=true,Terrain=true}
local eligible,excluded,refs,fixed={},{},{},{}
local function exclude(o,reason,obstacle)
 table.insert(excluded,record(o,reason))
 if obstacle then
  local parts=o:IsA('BasePart') and {o} or o:GetDescendants()
  for _,part in ipairs(parts)do if part:IsA('BasePart')then local lo,hi=box(part.CFrame,part.Size);table.insert(fixed,{Object=part,Low=lo,High=hi})end end
 end
end
local function add(o,reason)
 local r=record(o,reason);r.DescendantGeometry={}
 local all=o:GetDescendants()
 for _,p in ipairs(all)do if p:IsA('BasePart') or next(p:GetAttributes())~=nil or p:IsA('SpecialMesh')then
  local child=record(p,'Member of selected root')
  if p:IsA('SpecialMesh')then child.Scale=vector(p.Scale);child.Offset=vector(p.Offset)end
  table.insert(r.DescendantGeometry,child)
 end end
 table.insert(eligible,r);refs[#eligible]=o
end
local function visit(o)
 local name=o.Name;local lower=name:lower()
 local character=o:IsA('Model') and o:FindFirstChildWhichIsA('Humanoid')
 local plot=o:GetAttribute('Feature')=='PlayerPlot' or o:GetAttribute('Reserved')==true
 local protected=excludedNames[name] or lower:find('garden') or lower:find('sanctuary') or lower:find('plotitems_') or lower:find('weather') or lower:find('town') or lower:find('plaza') or lower:find('walkway') or lower:find('follower') or lower:find('petdisplay') or character or plot
 if protected then exclude(o,'Protected system/shared support/reference',name=='PlayerPlots' or name=='Plot4Reservation' or name=='AnimalKingdomFuturePlayerPlots' or lower:find('town') or lower:find('plaza') or lower:find('walkway'));return end
 if o:IsA('Model') or o:IsA('BasePart')then
  if stand(o)then exclude(o,'Sanctuary structure mesh association',true);return end
  if floors[name] and o==floors[name].Parent then add(o,'Actual playable biome floor');return end
  if o.Parent==workspace:FindFirstChild('BiomeTeleportPoints')then add(o,'Active biome destination marker');return end
  local biome=o:GetAttribute('BiomeId') or o:GetAttribute('Biome');local floor=floors[biome]
  local cf,size=bounds(o)
  if floor and cf then
   local center=floor.CFrame:PointToObjectSpace(cf.Position)
   if math.abs(center.X)<=floor.Size.X/2+25 and math.abs(center.Z)<=floor.Size.Z/2+25 and math.abs(center.Y)<200 then add(o,'Explicit biome attribute and matching physical region');return end
  end
  exclude(o,'Unproven environment membership; conservatively excluded',false);return
 end
 if o:IsA('Folder')then for _,child in ipairs(o:GetChildren())do visit(child)end else exclude(o,'Non-environment runtime/service object',false)end
end
for _,o in ipairs(workspace:GetChildren())do visit(o)end
local conflicts={}
local function overlap(lo,hi,other)
 local dx=math.min(hi.X,other.High.X)-math.max(lo.X,other.Low.X)
 local dy=math.min(hi.Y,other.High.Y)-math.max(lo.Y,other.Low.Y)
 local dz=math.min(hi.Z,other.High.Z)-math.max(lo.Z,other.Low.Z)
 return dx>.05 and dy>.05 and dz>.05,dx*math.max(0,dy)*dz
end
for i,o in ipairs(refs)do
 local rootPivot=o:GetPivot();local scaledPivot=CFrame.new(pivot+(rootPivot.Position-pivot)*factor)*rootPivot.Rotation
 local parts=o:IsA('BasePart') and {o} or o:GetDescendants()
 for _,part in ipairs(parts)do if part:IsA('BasePart') and part.CanCollide then
  local target=CFrame.new(pivot+(part.Position-pivot)*factor)*part.CFrame.Rotation
  local lo,hi=box(target,part.Size*factor);local oldLo,oldHi=box(part.CFrame,part.Size)
  for _,obstacle in ipairs(fixed)do
   local hit,volume=overlap(lo,hi,obstacle);local was,oldVolume=overlap(oldLo,oldHi,obstacle)
   if hit and (not was or volume>oldVolume+1)then conflicts[#conflicts+1]={EligibleRoot=i,Moving=record(part,'Prospective new/increased overlap'),Fixed=record(obstacle.Object,'Excluded fixed geometry'),OverlapVolume=volume,PreviousOverlapVolume=was and oldVolume or 0,ProposedCFrame=frame(target),ProposedSize=vector(part.Size*factor)}end
  end
 end end
end
return {Factor=factor,Pivot=vector(pivot),Applied=false,TransformedCount=0,Eligible=eligible,Excluded=excluded,Conflicts=conflicts,Rollback='Before any future transform, resolve Selector + UniqueId to exact instances, verify every original CFrame/Size/model scale, then retain those exact references. Restore original ModelScale/Pivot and BasePart CFrame/Size plus Vector3 attributes. This dry run changes nothing.'}
