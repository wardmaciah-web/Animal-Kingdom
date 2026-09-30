assert(not game:GetService('RunService'):IsRunning(), 'Edit mode required')
local result={placeId=game.PlaceId,roots={},parts={},models={},scripts={},spawns={},lighting={},counts={}}
local function vec(v) return {v.X,v.Y,v.Z} end
local function cf(v) return {v:GetComponents()} end
for _,v in ipairs(workspace:GetChildren()) do table.insert(result.roots,{name=v.Name,class=v.ClassName}) end
for _,o in ipairs(game:GetDescendants()) do
 if o:IsA('LuaSourceContainer') and not o:IsDescendantOf(game.CoreGui) then
  local ok,source=pcall(function() return o.Source end)
  if ok then table.insert(result.scripts,{path=o:GetFullName(),class=o.ClassName,source=source,disabled=o:IsA('BaseScript') and o.Disabled or nil}) end
 end
 if o:IsDescendantOf(workspace) then
  result.counts[o.ClassName]=(result.counts[o.ClassName] or 0)+1
  if o:IsA('BasePart') then
   local row={path=o:GetFullName(),class=o.ClassName,p=vec(o.Position),s=vec(o.Size),cf=cf(o.CFrame),collide=o.CanCollide,touch=o.CanTouch,query=o.CanQuery,anchored=o.Anchored,transparency=o.Transparency,material=o.Material.Name,color={o.Color.R,o.Color.G,o.Color.B},attrs=o:GetAttributes()}
   if o:IsA('MeshPart') then row.mesh=o.MeshId;row.texture=o.TextureID;row.fidelity=o.CollisionFidelity.Name end
   if o:IsA('SpawnLocation') then row.neutral=o.Neutral;row.enabled=o.Enabled end
   table.insert(result.parts,row)
  elseif o:IsA('Model') then
   local ok,p,s=pcall(function() return o:GetBoundingBox() end)
   if ok then table.insert(result.models,{path=o:GetFullName(),p=vec(p.Position),s=vec(s),pivot=cf(o:GetPivot()),attrs=o:GetAttributes()}) end
  elseif o:IsA('ParticleEmitter') then
   table.insert(result.spawns,{path=o:GetFullName(),rate=o.Rate,enabled=o.Enabled,lifetime=o.Lifetime.Max})
  end
 end
end
local encoded=game.HttpService:JSONEncode(result)
print('AK_FULL_SNAPSHOT_BEGIN')
for i=1,#encoded,500 do print('AK_FULL_SNAPSHOT_CHUNK '..encoded:sub(i,i+499)) end
print('AK_FULL_SNAPSHOT_END')
