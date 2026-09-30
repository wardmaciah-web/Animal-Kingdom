-- Reusable local presentation. No input capture and no gameplay authority.
local Run=game:GetService('RunService')
local Players=game:GetService('Players')
local W=require(script.Parent.Components)
local M={};M.__index=M
local function visible(o)
 local n=o
 while n and n:IsA('GuiObject')do if not n.Visible then return false end;n=n.Parent end
 return o.Parent~=nil and o.AbsoluteSize.X>0
end
function M.new(root)
 local self=setmetatable({Root=root},M)
 self.Paw=W.New('Frame',{Name='TutorialPaw',Size=UDim2.fromOffset(52,52),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,Visible=false,ZIndex=55},root)
 W.Icon(self.Paw,'Pets',UDim2.fromScale(1,1))
 self.Connection=Run.RenderStepped:Connect(function(dt)self:Render(dt)end)
 return self
end
function M:Target(target)
 if target==self.TargetObject then return end
 if self.Scale and self.Scale.Parent then self.Scale.Scale=1 end
 self.TargetObject=target;self.Scale=target and W.Motion.Scale(target) or nil
 self.Paw:SetAttribute('TargetName',target and target.Name or '')
end
function M:EnsureWorldVisual()
 if self.Arrow then return end
 local model=Instance.new('Model');model.Name='TutorialGroundArrow';model.Parent=workspace;self.Arrow=model
 local anchor=Instance.new('Part');anchor.Name='GuideAnchor';anchor.Size=Vector3.one*.1;anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CastShadow=false;anchor.Parent=model;self.Anchor=anchor
 self.Beams={}
 local function segment(a,b,width0,width1,soft)
  local first=Instance.new('Attachment');first.Position=a;first.Parent=anchor
  local last=Instance.new('Attachment');last.Position=b;last.Parent=anchor
  local beam=Instance.new('Beam');beam.Name=soft and 'DirectionGlow'or 'DirectionRibbon';beam.Attachment0=first;beam.Attachment1=last;beam.Width0=width0;beam.Width1=width1;beam.FaceCamera=true;beam.Segments=8;beam.LightEmission=1;beam.LightInfluence=0;beam.Color=ColorSequence.new(soft and Color3.fromRGB(123,236,213)or Color3.fromRGB(241,255,225));beam.Enabled=false;beam.Parent=anchor
  table.insert(self.Beams,{Beam=beam,Soft=soft})
 end
 -- A tapered short ribbon and two slim chevrons, with a broad low-opacity halo.
 for _,soft in ipairs({true,false})do
  local w=soft and .48 or .14
  segment(Vector3.new(0,0,-.7),Vector3.new(0,0,-3.5),soft and .55 or .20,.02,soft)
  for _,z in ipairs({-2.8,-4.05})do segment(Vector3.new(-.66,0,z+.66),Vector3.new(0,0,z),w,w*.7,soft);segment(Vector3.new(.66,0,z+.66),Vector3.new(0,0,z),w,w*.7,soft)end
 end
 self.Highlight=Instance.new('Highlight');self.Highlight.Name='TutorialEmphasis';self.Highlight.FillColor=Color3.fromRGB(188,255,218);self.Highlight.OutlineColor=Color3.fromRGB(239,255,218);self.Highlight.DepthMode=Enum.HighlightDepthMode.Occluded;self.Highlight.Enabled=false;self.Highlight.Parent=model
 self.GroundAt=0
end
function M:World(position,near,highlight)
 self.Position=position;self.Near=near or 10;self.HighlightTarget=highlight
 if position or highlight then self:EnsureWorldVisual()end
 if self.Highlight then self.Highlight.Adornee=highlight;self.Highlight.Enabled=highlight~=nil end
end
function M:Render(dt)
 local t=os.clock();local reduced=W.Motion.Reduced();local pulse=reduced and .15 or (math.sin(t*3)+1)/2
 local target=self.TargetObject
 self.Paw.Visible=target~=nil and target:IsDescendantOf(self.Root.Parent) and visible(target)
 if self.Paw.Visible then
  if self.Scale and self.Scale.Parent then self.Scale.Scale=1+pulse*(reduced and .008 or .055)end
  local p=target.AbsolutePosition-self.Root.AbsolutePosition;local size=target.AbsoluteSize;local safe=self.Root.AbsoluteSize
  local x,y=p.X+size.X*.78,p.Y-25
  if y<28 then y=p.Y+size.Y+27 end
  if y>safe.Y-28 then x=p.X-28;y=p.Y+size.Y/2 end
  local goal=Vector2.new(math.clamp(x,28,math.max(28,safe.X-28)),math.clamp(y+(reduced and 0 or math.sin(t*3)*3),28,math.max(28,safe.Y-28)))
  self.Point=self.Point and self.Point:Lerp(goal,1-math.exp(-dt*(reduced and 30 or 12))) or goal
  self.Point=Vector2.new(math.clamp(self.Point.X,28,math.max(28,safe.X-28)),math.clamp(self.Point.Y,28,math.max(28,safe.Y-28)))
  self.Paw.Position=UDim2.fromOffset(self.Point.X,self.Point.Y);self.Paw.Rotation=reduced and 0 or -12+math.sin(t*3)*3
 end
 local player=Players.LocalPlayer;local char=player.Character;local r=char and char:FindFirstChild('HumanoidRootPart');local h=char and char:FindFirstChildOfClass('Humanoid')
 local delta=r and self.Position and Vector3.new(self.Position.X-r.Position.X,0,self.Position.Z-r.Position.Z)
 local distance=delta and delta.Magnitude or 0
 if self.Highlight then
  local valid=self.HighlightTarget and self.HighlightTarget:IsDescendantOf(workspace)
  self.Highlight.Enabled=valid~=nil and valid~=false
  local close=distance<self.Near+8
  self.Highlight.FillTransparency=close and .76-pulse*.08 or .92-pulse*.035
  self.Highlight.OutlineTransparency=close and .12 or .38
 end
 local shown=delta and h and h.Health>0 and distance>.1
 if not self.Arrow then return end
 local targetFade=shown and math.clamp((distance-self.Near+1)/5,0,1)or 0
 self.ArrowFade=(self.ArrowFade or 0)+(targetFade-(self.ArrowFade or 0))*(1-math.exp(-dt*12))
 for _,entry in ipairs(self.Beams)do
  local beam=entry.Beam;beam.Enabled=self.ArrowFade>.015
  local opacity=(entry.Soft and .16 or .85)*self.ArrowFade
  beam.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1-opacity*.3),NumberSequenceKeypoint.new(.35,1-opacity),NumberSequenceKeypoint.new(1,1-opacity*.85)})
 end
 if not shown then return end
 -- Only heading is interpolated. Horizontal position follows the current foot
 -- immediately, so the guide never trails behind a running character.
 local desired=CFrame.lookAt(Vector3.zero,delta.Unit)
 self.Heading=self.Heading and self.Heading:Lerp(desired,1-math.exp(-dt*16))or desired
 if t>=self.GroundAt then
  self.GroundAt=t+.08
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char,self.Arrow,workspace:FindFirstChild('LocalPetFollowers')or self.Arrow};params.RespectCanCollide=true
  local hit=workspace:Raycast(r.Position+Vector3.new(0,1,0),Vector3.new(0,-20,0),params)
  self.GroundGoal=hit and hit.Position.Y+.13 or r.Position.Y-2.9
 end
 self.GroundY=self.GroundY and self.GroundY+(self.GroundGoal-self.GroundY)*(1-math.exp(-dt*22))or self.GroundGoal
 local bob=reduced and 0 or math.sin(t*2.8)*.055
 local forward=reduced and 0 or math.sin(t*2.8)*.13
 self.Anchor.CFrame=CFrame.new(r.Position.X,self.GroundY+bob,r.Position.Z)*self.Heading*CFrame.new(0,0,forward)
end
function M:Clear()self:Target(nil);self:World(nil);self.Paw.Visible=false end
function M:Destroy()self:Clear();self.Connection:Disconnect();self.Paw:Destroy();if self.Arrow then self.Arrow:Destroy()end end
return M
