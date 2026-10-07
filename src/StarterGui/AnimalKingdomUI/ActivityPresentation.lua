-- Shares TutorialGuidance's existing pointer. No second directional arrow.
local Players=game:GetService('Players')
local Collection=game:GetService('CollectionService')
local RS=game.ReplicatedStorage
local W=require(script.Parent.GameplayWidgets)
local Bridge=require(script.Parent.RemoteBridge)
local Tween=game:GetService('TweenService')
local Sounds=require(RS.Shared.Gameplay.PresentationSounds)
local M={};M.__index=M
local function position(t)return t and Vector3.new(t[1],t[2],t[3])end
function M.new(ctx,screen)
 local self=setmetatable({Ctx=ctx,Screen=screen,Connections={},Previous={},SeenWorld={}},M)
 ctx.ActivityGuidance=function(pointer)self:Guide(pointer)end
 local function refresh()if ctx.ActiveName=='Challenges'then ctx.Refresh()end end
 table.insert(self.Connections,Players.LocalPlayer:GetAttributeChangedSignal('ActivityOffers'):Connect(refresh))
 task.spawn(function()
  local world=RS:WaitForChild('KingdomWorld',30)
  if world and not self.Destroyed then table.insert(self.Connections,world:GetAttributeChangedSignal('State'):Connect(function()self:WorldNotice(world);if ctx.ActiveName=='Challenges'or ctx.ActiveName=='Biomes'then ctx.Refresh()end end));self:WorldNotice(world)end
 end)
 table.insert(self.Connections,Players.LocalPlayer:GetAttributeChangedSignal('AKReducedMotion'):Connect(function()self:RemoveMarker()end))
 table.insert(self.Connections,screen:GetAttributeChangedSignal('ActiveMenu'):Connect(function()self:Attention(ctx.Data)end))
 return self
end
function M:RemoveMarker()
 if self.Marker then self.Marker:Destroy();self.Marker=nil;self.MarkerKey=nil end
end
function M:Notice(payload)payload.World=true;self.Ctx.Notify(payload)end
function M:WorldNotice(world)
 local ok,state=pcall(RS.Parent.HttpService.JSONDecode,RS.Parent.HttpService,world:GetAttribute('State')or '{}')
 if not ok then return end
 local hot=state.Hot
 if hot and not self.SeenWorld[hot.Id]then
  for id,at in pairs(self.SeenWorld)do if workspace:GetServerTimeNow()-at>600 then self.SeenWorld[id]=nil end end
  self.SeenWorld[hot.Id]=workspace:GetServerTimeNow()
  self:Notice({Id='Hot:'..hot.Id,CoalesceKey='HotTree',ExpiresAt=hot.EndsAt,Title='HOT TREE',Message=(hot.Biome or '')..' • '..(hot.Variant or '')..' Tree',Detail='Legendary+ pets guaranteed • normal search costs apply',Category='HotTree',Priority=55})
 end
 self:Attention(self.Ctx.Data)
end
function M:Attention(d)
 if not d then return end
 local p=Players.LocalPlayer;local menu=self.Screen:GetAttribute('ActiveMenu');local stock=RS:FindFirstChild('KingdomShopStock');local rotation=stock and stock:GetAttribute('Rotation')
 if menu=='Shop'then self.ViewedRotation=rotation end
 p:SetAttribute('AKTownShopUnread',d.TutorialCompleted and rotation~=nil and rotation~=self.ViewedRotation)
 if menu=='Index'then self.UnreadDiscovery=false end
 p:SetAttribute('AKTownIndexUnread',self.UnreadDiscovery==true)
 local ready=false;for _,trip in ipairs(d.GardenExpeditions or {})do if trip.ReadyAt and trip.ReadyAt<=workspace:GetServerTimeNow()then ready=true end end
 p:SetAttribute('AKTownGardenReady',ready)
 local available=false;local ok,offers=pcall(game.HttpService.JSONDecode,game.HttpService,p:GetAttribute('ActivityOffers')or '[]')
 if ok then for _,offer in ipairs(offers)do if offer.Eligible then available=true;break end end end
 p:SetAttribute('AKTownActivitiesAvailable',d.TutorialCompleted and available and not(d.Activities and d.Activities.Route)and menu~='Challenges')
end
function M:Update(d)
 if not d then return end
 local previous=self.Previous;local nextState={};local a=d.Activities or {};local ready=self.HasSnapshot and d.TutorialCompleted
 local j=a.Journey
 if j then
  nextState.Journey={Id=j.Id,Step=j.Step,Entries={}}
  for i,g in ipairs(j.Entries)do
   nextState.Journey.Entries[i]=g.Progress
   local old=previous.Journey
   if ready and old and old.Id==j.Id and g.Progress>(old.Entries[i]or 0)then
    local complete=g.Progress>=g.Target;local following=j.Entries[i+1]
    self:Notice({Id=g.Id..':'..g.Progress,CoalesceKey=j.Id,Category='Journey',Priority=complete and 78 or 35,Complete=complete,
     Title=complete and '✓ JOURNEY STEP COMPLETE'or 'DAILY JOURNEY',Message=g.Text,
     Detail=complete and(following and 'NEXT: '..following.Text or 'Journey complete • claim in Activities')or(g.Progress..' / '..g.Target)})
   end
  end
 end
 local r=a.Route
 if r then
  nextState.Route={Id=r.Id,Progress=r.Progress,Step=r.Step,Completed=r.Completed}
  local old=previous.Route;local changed=not old or old.Id~=r.Id or r.Progress>old.Progress
  if ready and changed then
   local category=r.Kind=='Paw'and 'Paw'or r.Kind=='Adventure'and 'Adventure'or 'Rush'
   local title=category=='Paw'and 'PAWPRINT HUNT'or category=='Adventure'and 'BIOME ADVENTURE'or 'TREE RUSH'
   local complete=r.Completed;local body=r.Name
   if r.Kind=='Adventure'then body=({'Search '..(r.Targets[1].Name or 'the marked tree'),'Find a pet at least '..(r.Ratio or 1.25)..'× base weight','Place an eligible pet in Sanctuary'})[r.Step]or r.Name end
   self:Notice({Id=r.Id..':'..r.Progress,CoalesceKey=r.Id,Category=category,Priority=complete and 80 or 42,Complete=complete,Title=complete and('✓ '..title..' COMPLETE')or title,Message=body,Detail=complete and 'Claim your reward in Activities'or((r.Kind=='Paw'and '🐾 'or '')..r.Progress..' / '..r.Target)})
   if old and old.Id==r.Id and r.Kind=='Paw'and r.Progress>old.Progress and self.Marker then self:PawFound()end
  end
 end
 local count=0;for _,value in pairs(d.PetIndex or {})do if value then count+=1 end end
 if previous.Species and count>previous.Species then self.UnreadDiscovery=true end
 nextState.Species=count;self.Previous=nextState;self.HasSnapshot=true;self:Attention(d)
end
function M:PawFound()
 local marker=self.Marker;if not marker then return end
 self.Marker=nil;self.MarkerKey=nil
 local prompt=marker:FindFirstChild('PawPrompt');if prompt then prompt.Enabled=false end
 local e=marker:FindFirstChild('PawShimmer');if e then e.Rate=0;e:Emit(W.Motion.Reduced()and 5 or 22)end
 Sounds.Play('UIClaim',marker)
 local ui=marker:FindFirstChild('Pawprint');if ui then local scale=ui:FindFirstChildOfClass('UIScale');if scale then Tween:Create(scale,TweenInfo.new(.4),{Scale=W.Motion.Reduced()and 1 or 1.35}):Play()end end
 game:GetService('Debris'):AddItem(marker,.65)
end
function M:Paw(r,index,target)
 local key=r.Id..':'..index
 if self.MarkerKey==key then self.Marker.Position=position(target.Position);return self.Marker end
 self:RemoveMarker()
 local anchor=Instance.new('Part');anchor.Name='PersonalPawprint';anchor.Size=Vector3.new(3.4,.05,3.4);anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CastShadow=false;anchor.Position=position(target.Position);anchor.Parent=workspace
 local ground=W.New('SurfaceGui',{Name='GroundPaw',Face=Enum.NormalId.Top,CanvasSize=Vector2.new(160,160),LightInfluence=0,AlwaysOnTop=false},anchor)
 local disc=W.New('Frame',{Size=UDim2.fromScale(.96,.96),Position=UDim2.fromScale(.02,.02),BackgroundColor3=Color3.fromRGB(102,236,207),BackgroundTransparency=.78},ground);W.Round(disc,80);W.Stroke(disc,Color3.fromRGB(176,255,233),2)
 W.Icon(ground,'Pets',UDim2.fromScale(.78,.78),UDim2.fromScale(.11,.11))
 local ui=W.New('BillboardGui',{Name='Pawprint',Adornee=anchor,Size=UDim2.fromOffset(82,95),StudsOffsetWorldSpace=Vector3.new(0,3.5,0),MaxDistance=145,AlwaysOnTop=true},anchor)
 local scale=W.New('UIScale',{Scale=1},ui)
 W.Icon(ui,'Pets',UDim2.fromOffset(62,62),UDim2.fromOffset(10,0))
 local label=W.Text(ui,index..' / 6',UDim2.new(1,0,0,28),UDim2.fromOffset(0,64),18,Color3.fromRGB(218,255,244));label.TextXAlignment=Enum.TextXAlignment.Center;label.TextStrokeTransparency=.15
 if not W.Motion.Reduced()then local pulse=Tween:Create(scale,TweenInfo.new(1.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Scale=1.13});pulse:Play();anchor.Destroying:Once(function()pulse:Cancel()end)end
 local e=Instance.new('ParticleEmitter');e.Name='PawShimmer';e.Texture='rbxasset://textures/particles/sparkles_main.dds';e.Color=ColorSequence.new(Color3.fromRGB(151,255,219));e.Size=NumberSequence.new(.16);e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.25),NumberSequenceKeypoint.new(1,1)});e.Lifetime=NumberRange.new(1,2);e.Speed=NumberRange.new(.6,1.5);e.SpreadAngle=Vector2.new(40,40);e.Rate=W.Motion.Reduced()and 1 or 7;e.LightEmission=.8;e.Parent=anchor
 local prompt=Instance.new('ProximityPrompt');prompt.Name='PawPrompt';prompt.ActionText='DISCOVER PAWPRINT';prompt.ObjectText='Your trail • '..index..'/6';prompt.MaxActivationDistance=8;prompt.HoldDuration=.15;prompt.RequiresLineOfSight=false;prompt.Parent=anchor
 prompt.Triggered:Connect(function()Bridge.Request('PawDiscover',{Id=r.Id,Index=index})end)
 self.Marker=anchor;self.MarkerKey=key;return anchor
end
function M:Guide(pointer)
 self.Pointer=pointer
 local d=self.Ctx.Data;local r=d and d.Activities and d.Activities.Route;local s=self.Screen
 local p=Players.LocalPlayer;local hum=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
 if not d or not d.TutorialCompleted or not hum or hum.Health<=0 or s:GetAttribute('RewardRevealActive')or s:GetAttribute('ModalActive')or s:GetAttribute('OnboardingActive')or not r or r.Completed or r.EndsAt<=workspace:GetServerTimeNow()then pointer:Clear();self:RemoveMarker();return end
 if s:GetAttribute('ActiveMenu')~=''then pointer:Clear();self:RemoveMarker();return end
 pointer:Target(nil)
 if r.Kind=='Adventure'and r.Step==3 then
  self:RemoveMarker();pointer:World(nil)
  local sanctuaries=workspace:FindFirstChild('Sanctuaries');local own=sanctuaries and sanctuaries:FindFirstChild(tostring(p.UserId));local interactions=own and own:FindFirstChild('SlotInteractions')
  local slot=interactions and interactions:FindFirstChildWhichIsA('BasePart')
  if slot then pointer:World(slot.Position,8,nil)end
  return
 end
 local index=r.Kind=='Adventure'and 1 or math.min(r.Progress+1,#r.Targets);local target=r.Targets[index]
 if not target then pointer:Clear();return end
 if r.Kind=='Paw'and index<=6 then
  local anchor=self:Paw(r,index,target);pointer:World(anchor.Position,6,nil)
 else
  self:RemoveMarker();local tree
  for _,candidate in ipairs(Collection:GetTagged('GatherableTree'))do if candidate:GetAttribute('ActivityTreeId')==target.TreeId and candidate:IsDescendantOf(workspace)then tree=candidate;break end end
  if tree and tree:GetAttribute('ResourceState')=='AVAILABLE'then pointer:World(position(target.Position),6,tree)else pointer:Clear()end
 end
end
function M:Destroy()
 self.Destroyed=true;self.Ctx.ActivityGuidance=nil;self:RemoveMarker()
 for _,c in ipairs(self.Connections)do c:Disconnect()end
end
return M
