-- One bounded client animation loop for every Sanctuary. Server placement and income stay authoritative.
local Collection=game:GetService('CollectionService')
local RunService=game:GetService('RunService')
local Players=game:GetService('Players')
local Geometry=require(game.ReplicatedStorage.Shared.Gameplay.PetVisualGeometry)
local entries,pending={},{}
local function initialize(model)
 if not model:IsA('Model') or entries[model] then return true end
  if not model.Parent then return true end
  local bounds=Geometry.Measure(model);if not bounds then return false end
  local phase=0;for i=1,#model.Name do phase=(phase+string.byte(model.Name,i)*i)%997 end
  local e={Model=model,Bounds=bounds,Base=model:GetAttribute('DisplayBasePivot') or model:GetPivot(),Phase=phase/997*math.pi*2,Labels={}}
  e.BaseBounds=Geometry.RotateBounds(bounds,e.Base.Rotation)
  local aura=Instance.new('Highlight');aura.Name='AKCollectibleAura';aura.Adornee=model;aura.FillTransparency=1;aura.OutlineTransparency=.45;aura.OutlineColor=Color3.fromRGB(220,185,106);aura.DepthMode=Enum.HighlightDepthMode.Occluded;aura.Enabled=false;aura.Parent=model;e.Aura=aura
  e.LabelDistance=math.max(48,bounds.Size.Magnitude+32)
  e.YawAmplitude=math.min(.018,.12/math.max(.1,Vector2.new(bounds.Size.X,bounds.Size.Z).Magnitude*.5))
  local function label(d)if d:IsA('BillboardGui')then d.Enabled=false;d.MaxDistance=e.LabelDistance;table.insert(e.Labels,d)end end
  for _,d in ipairs(model:GetDescendants())do label(d)end
  e.LabelConnection=model.DescendantAdded:Connect(label)
  e.Connection=model:GetAttributeChangedSignal('DisplayBasePivot'):Connect(function()
   e.Base=model:GetAttribute('DisplayBasePivot') or model:GetPivot()
   e.BaseBounds=Geometry.RotateBounds(e.Bounds,e.Base.Rotation)
  end)
  entries[model]=e;return true
end
local function add(model)if model:IsA('Model')and not entries[model]then pending[model]=true end end
local function remove(model)pending[model]=nil;local e=entries[model];if e then e.Connection:Disconnect();e.LabelConnection:Disconnect();if e.Aura then e.Aura:Destroy()end;entries[model]=nil end end
Collection:GetInstanceAddedSignal('SanctuaryDisplayPet'):Connect(add)
Collection:GetInstanceRemovedSignal('SanctuaryDisplayPet'):Connect(remove)
for _,m in ipairs(Collection:GetTagged('SanctuaryDisplayPet'))do add(m)end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.05 then return end;elapsed=0
 local initialized=0
 for model in pairs(pending)do if initialized>=8 then break end;if initialize(model)then pending[model]=nil;initialized+=1 end end
 local camera=workspace.CurrentCamera;if not camera then return end
 local now=os.clock();local nearest,score=nil,math.huge
 local reduced=Players.LocalPlayer:GetAttribute('AKReducedMotion')==true
 for model,e in pairs(entries)do
  if not model.Parent then remove(model);continue end
  local bounds=e.BaseBounds
  local lower=e.Base.Position+bounds.Min;local upper=e.Base.Position+bounds.Max
  local view=camera.CFrame.Position
  local nearestPoint=Vector3.new(math.clamp(view.X,lower.X,upper.X),math.clamp(view.Y,lower.Y,upper.Y),math.clamp(view.Z,lower.Z,upper.Z))
  local distance=(view-nearestPoint).Magnitude
  local foot=e.Base.Position+Vector3.new(bounds.Center.X,bounds.Min.Y,bounds.Center.Z)
  local point,onScreen=camera:WorldToViewportPoint(foot)
  -- A giant's model pivot may be far overhead. Selection follows the physical
  -- footprint; its label still remains above the actual measured model.
  if (onScreen or distance<12) and distance<48 then
   local center=Vector2.new(point.X,point.Y)-camera.ViewportSize/2
   local rank=center.Magnitude+distance*2
   if rank<score then nearest=e;score=rank end
  end
  if not reduced and onScreen and distance<140 then
   local rate=distance<70 and .05 or .16
   if not e.Next or now>=e.Next then
    e.Next=now+rate
    -- Yaw around the grounded bounding center. No vertical float or synchronized bounce.
    local yaw=math.sin(now*.7+e.Phase)*e.YawAmplitude
    local rotation=e.Base.Rotation*CFrame.Angles(0,yaw,0)
    local old=Geometry.RotateBounds(e.Bounds,e.Base.Rotation)
    local surface=e.Base.Position+Vector3.new(old.Center.X,old.Min.Y,old.Center.Z)
    model:PivotTo(Geometry.GroundCFrame(e.Bounds,surface,rotation,0))
   end
  elseif e.Next then model:PivotTo(e.Base);e.Next=nil end
 end
 for _,e in pairs(entries)do if e.Aura then e.Aura.Enabled=e==nearest;e.Aura.OutlineTransparency=reduced and .4 or .35+.15*math.sin(now*1.4)end;for _,label in ipairs(e.Labels)do label.Enabled=e==nearest end end
end)
