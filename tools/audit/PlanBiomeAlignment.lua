assert(not game:GetService('RunService'):IsRunning(),'Edit mode required')
local recovery=assert(game.ServerStorage:FindFirstChild('AK_AuditRecovery_20260917'))
assert(not recovery:FindFirstChild('BiomeAlignmentPlan'),'Alignment already planned')
local plan=Instance.new('Folder');plan.Name='BiomeAlignmentPlan';plan.Parent=recovery
local support=workspace.AnimalKingdomConcreteGround.Position.Y+workspace.AnimalKingdomConcreteGround.Size.Y/2
local common=workspace.Meadow.MeadowFloor.Position.Y+workspace.Meadow.MeadowFloor.Size.Y/2
assert(math.abs(common-support-1.3)<.01,'Unexpected floor evidence')
print('[MapAudit] Common playable floor Y = '..common)
local whole={AncientRuins=true,MagicalForest=true,Sky=true,Prehistoric=true,Volcano=true}
local ids={'Meadow','Forest','Jungle','Desert','Snow','Volcano','Ocean','AncientRuins','MagicalForest','Sky','Prehistoric','Mythical'}
local floorById={}
for _,id in ipairs(ids) do floorById[id]=assert(workspace[id]:FindFirstChild(id..'Floor')) end
local function bounds(o)
 if o:IsA('Model') then return o:GetBoundingBox() elseif o:IsA('BasePart') and not o:IsA('Terrain') then return o.CFrame,o.Size end
end
local candidates={}
local excluded={World=true,PlayerPlots=true,AnimalKingdomFuturePlayerPlots=true,BiomeTeleportPoints=true,AnimalKingdomTown=true,WeatherAdminRoom=true,Terrain=true,GrassFloor=true,AnimalKingdomConcreteGround=true}
local function gather(o)
 if excluded[o.Name] or o:IsA('LuaSourceContainer') then return end
 if o:IsA('Folder') then for _,c in ipairs(o:GetChildren()) do gather(c) end
 elseif o:IsA('Model') or o:IsA('BasePart') then
  if o:IsA('Model') and o:FindFirstChildOfClass('Humanoid') then return end
  local cf,s=bounds(o)
  if cf and s.Magnitude>0 and math.max(s.X,s.Z)<300 and cf.Y+s.Y/2>support and cf.Y-s.Y/2<250 then table.insert(candidates,{o=o,cf=cf,size=s}) end
 end
end
for _,o in ipairs(workspace:GetChildren()) do gather(o) end
local rows={}
for _,id in ipairs(ids) do
 local floor=floorById[id];local original=floor.Position.Y+floor.Size.Y/2
 local offset=common-original;if math.abs(offset)<.001 then offset=0 end
 local group=Instance.new('Folder');group.Name=id;group.Parent=plan
 group:SetAttribute('OriginalSurfaceY',original);group:SetAttribute('CorrectedSurfaceY',common);group:SetAttribute('VerticalOffset',offset);group:SetAttribute('WholeAssembly',whole[id]==true)
 local members={};local partCount=0
 local function add(o)
  local e=Instance.new('ObjectValue');e.Name='Member_'..tostring(#members+1);e.Value=o;e.Parent=group
  e:SetAttribute('OriginalPath',o:GetFullName());e:SetAttribute('OriginalPivot',o:GetPivot())
  local count=o:IsA('BasePart') and 1 or 0
  for _,p in ipairs(o:GetDescendants()) do if p:IsA('BasePart') then count+=1 end end
  partCount+=count;table.insert(members,{name=o:GetFullName(),position={o:GetPivot().Position.X,o:GetPivot().Position.Y,o:GetPivot().Position.Z},parts=count})
 end
 if offset~=0 then
  if whole[id] then
   for _,r in ipairs(candidates) do
    if (r.o==floor.Parent or (math.abs(r.cf.X-floor.Position.X)<=floor.Size.X/2+15 and math.abs(r.cf.Z-floor.Position.Z)<=floor.Size.Z/2+15)) then add(r.o) end
   end
  else add(floor.Parent) end
 end
 table.insert(rows,{biome=id,original=original,corrected=common,offset=offset,wholeAssembly=whole[id]==true,members=members,parts=partCount})
 print(string.format('[MapAudit] Plan %s %.5f -> %.5f offset %.5f roots %d parts %d',id,original,common,offset,#members,partCount))
end
local s=game.HttpService:JSONEncode(rows);print('AK_ALIGNMENT_BEGIN') for i=1,#s,500 do print('AK_ALIGNMENT_CHUNK '..s:sub(i,i+499)) end print('AK_ALIGNMENT_END')
