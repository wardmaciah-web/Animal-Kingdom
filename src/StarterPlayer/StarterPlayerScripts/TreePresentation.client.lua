-- One client owner for extra tree/world cosmetics. Authored geometry, collision,
-- interaction anchors and the existing search shake are never transformed here.
local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local Collection=game:GetService('CollectionService')
local Prompts=game:GetService('ProximityPromptService')
local Run=game:GetService('RunService')
local Sounds=require(RS.Shared.Gameplay.PresentationSounds)
local Quality=require(RS.Shared.WeatherVFXQuality)
local player=Players.LocalPlayer
local Theme=require(game:GetService('StarterGui').AnimalKingdomUI.AnimalKingdomUIV2.Theme)
local folder=Instance.new('Folder');folder.Name='KingdomAmbientVisuals';folder.Parent=workspace
local connections={};local alive=true;local targeted;local burstAt=0;local random=Random.new()
local SPARK='rbxasset://textures/particles/sparkles_main.dds'
local SMOKE='rbxasset://textures/particles/smoke_main.dds'
local colors={Heavy=Color3.fromRGB(218,132,255),Lucky=Color3.fromRGB(149,244,111),Rich=Color3.fromRGB(255,218,85),Fast=Color3.fromRGB(108,226,255),Mastery=Color3.fromRGB(255,167,102)}
local function anchor(name,size)
 local p=Instance.new('Part');p.Name=name;p.Size=size or Vector3.one*.2;p.Transparency=1;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=folder;return p
end
local function emitter(parent,name)
 local e=Instance.new('ParticleEmitter');e.Name=name;e.Texture=SPARK;e.Rate=0;e.Lifetime=NumberRange.new(4,7);e.Speed=NumberRange.new(.5,1.8);e.SpreadAngle=Vector2.new(180,180);e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.07),NumberSequenceKeypoint.new(.25,.18,.06),NumberSequenceKeypoint.new(1,.04)});e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.18),NumberSequenceKeypoint.new(.75,.35),NumberSequenceKeypoint.new(1,1)});e.LightEmission=.65;e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-30,35);e.Parent=parent;return e
end
local air=anchor('LocalCanopyAir',Vector3.new(48,16,48));local motes=emitter(air,'PollenAndDust')
motes.Drag=.3
local burst=anchor('SearchBurst',Vector3.new(8,5,8));local burstEmitter=emitter(burst,'CommittedLeaves');burstEmitter.Lifetime=NumberRange.new(.9,1.8);burstEmitter.Speed=NumberRange.new(4,9);burstEmitter.Acceleration=Vector3.new(0,-2,0);burstEmitter.Size=NumberSequence.new(.32,.08)
local hotAnchor=anchor('HotTreeAir',Vector3.new(7,5,7));local hotUp=emitter(hotAnchor,'HotUpdraft');hotUp.EmissionDirection=Enum.NormalId.Top;hotUp.SpreadAngle=Vector2.new(20,20);hotUp.Speed=NumberRange.new(2,4);hotUp.Acceleration=Vector3.new(0,1,0);hotUp.Lifetime=NumberRange.new(1.7,3);hotUp.Size=NumberSequence.new(.27,.06)
local orbit={}
for i=1,2 do local a=Instance.new('Attachment');a.Name='HotOrbit'..i;a.Parent=hotAnchor;local e=emitter(a,'OrbitGlints');e.Speed=NumberRange.new(.15,.6);e.Lifetime=NumberRange.new(.5,1.1);orbit[i]={Attachment=a,Emitter=e}end
local hotGround=anchor('HotGroundGlow');local ringBeams={}
for i=0,15 do
 local a=Instance.new('Attachment');a.Position=Vector3.new(math.cos(i*math.pi/8)*4.2,0,math.sin(i*math.pi/8)*4.2);a.Parent=hotGround
 local b=Instance.new('Attachment');b.Position=Vector3.new(math.cos((i+1)*math.pi/8)*4.2,0,math.sin((i+1)*math.pi/8)*4.2);b.Parent=hotGround
 local beam=Instance.new('Beam');beam.Name='TrunkHalo';beam.Attachment0=a;beam.Attachment1=b;beam.FaceCamera=true;beam.Width0=.35;beam.Width1=.35;beam.LightEmission=1;beam.Enabled=false;beam.Parent=hotGround;ringBeams[i+1]=beam
end
local hotLight=Instance.new('PointLight');hotLight.Range=17;hotLight.Brightness=1.4;hotLight.Shadows=false;hotLight.Enabled=false;hotLight.Parent=hotGround
local hotHighlight=Instance.new('Highlight');hotHighlight.Name='HotTreeSilhouette';hotHighlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hotHighlight.Enabled=false;hotHighlight.Parent=folder
local hotGui=Instance.new('BillboardGui');hotGui.Name='HotTreeLabel';hotGui.Adornee=hotAnchor;hotGui.Size=UDim2.fromOffset(186,92);hotGui.StudsOffsetWorldSpace=Vector3.new(0,5,0);hotGui.MaxDistance=185;hotGui.AlwaysOnTop=false;hotGui.LightInfluence=0;hotGui.Parent=hotAnchor
local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBold;label.TextSize=21;label.TextColor3=Color3.new(1,1,1);label.TextStrokeColor3=Color3.fromRGB(28,23,31);label.TextStrokeTransparency=.08;label.Parent=hotGui
local labelTree;local labelRadius=8
local luckyAnchor=anchor('LuckyAreaGlow',Vector3.new(12,7,12));local luckyGlints=emitter(luckyAnchor,'LuckyGreenGold');luckyGlints.Color=ColorSequence.new(Color3.fromRGB(141,241,148),Color3.fromRGB(255,226,124));luckyGlints.LightEmission=1
local zones={}
for i=1,3 do
 local fire=anchor('ForestFireflyPocket'..i,Vector3.new(14,5,14));local e=emitter(fire,'Fireflies');e.Color=ColorSequence.new(Color3.fromRGB(217,255,133));e.LightEmission=1;e.Size=NumberSequence.new(.13,.05);e.Speed=NumberRange.new(.2,.65);e.Acceleration=Vector3.new(.2,.06,.15)
 local ground=anchor('ForestMistPocket'..i,Vector3.new(18,1,18));local mist=emitter(ground,'LowForestMist');mist.Texture=SMOKE;mist.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,6),NumberSequenceKeypoint.new(.6,12,3),NumberSequenceKeypoint.new(1,15)});mist.Lifetime=NumberRange.new(7,11);mist.Speed=NumberRange.new(.25,.6);mist.Acceleration=Vector3.new(.15,0,0);mist.LightEmission=0;mist.Color=ColorSequence.new(Color3.fromRGB(174,195,174));mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.88),NumberSequenceKeypoint.new(.65,.91),NumberSequenceKeypoint.new(1,1)})
 zones[i]={Anchor=fire,Fireflies=e,Ground=ground,Mist=mist}
end
-- Reusable procedural 2D petals/leaves. No mesh/model/texture asset is created.
-- Thirty-six pooled billboards give readable drifting silhouettes near the player.
local foliage={}
for i=1,36 do
 local a=anchor('DriftingFoliage'..i)
 local ui=Instance.new('BillboardGui');ui.Name='Foliage';ui.Size=UDim2.fromScale(.65,.95);ui.AlwaysOnTop=false;ui.LightInfluence=.3;ui.MaxDistance=90;ui.Enabled=false;ui.Parent=a
 local leaf=Instance.new('Frame');leaf.Name='Leaf';leaf.AnchorPoint=Vector2.new(.5,.5);leaf.Position=UDim2.fromScale(.5,.5);leaf.Size=UDim2.fromScale(.55,.85);leaf.BackgroundTransparency=.12;leaf.BorderSizePixel=0;leaf.Rotation=random:NextNumber(-90,90);leaf.Parent=ui
 local round=Instance.new('UICorner');round.CornerRadius=UDim.new(.5,0);round.Parent=leaf
 local vein=Instance.new('Frame');vein.Name='Vein';vein.Size=UDim2.new(0,1,.64,0);vein.Position=UDim2.fromScale(.5,.18);vein.BorderSizePixel=0;vein.BackgroundTransparency=.48;vein.BackgroundColor3=Color3.fromRGB(241,255,199);vein.Parent=leaf
 local art=Instance.new('ImageLabel');art.Name='ExistingLeafArt';art.BackgroundTransparency=1;art.Size=UDim2.fromScale(1.4,1.15);art.Position=UDim2.fromScale(-.2,-.075);art.Image=Theme.Assets.Icons;art.ImageRectOffset=Vector2.new(7,775);art.ImageRectSize=Vector2.new(242,242);art.ScaleType=Enum.ScaleType.Fit;art.Parent=leaf
 foliage[i]={Anchor=a,Gui=ui,Leaf=leaf,Vein=vein,Art=art,Seed=random:NextNumber(0,20),Age=100,Life=1}
end
local ready={}
for i=1,3 do local h=Instance.new('Highlight');h.Name='ReadyCanopy'..i;h.FillTransparency=1;h.OutlineTransparency=.9;h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Enabled=false;h.Parent=folder;ready[i]=h end
local townAnchor=anchor('TownAttention',Vector3.new(4,2,4));local townEmitter=emitter(townAnchor,'LocationSparkle');townEmitter.Lifetime=NumberRange.new(1,2);townEmitter.Speed=NumberRange.new(.5,1.2)
local townHighlight=Instance.new('Highlight');townHighlight.Name='TownAttention';townHighlight.FillTransparency=.93;townHighlight.OutlineTransparency=.35;townHighlight.DepthMode=Enum.HighlightDepthMode.Occluded;townHighlight.Enabled=false;townHighlight.Parent=folder
local trees={};local state={};local biome;local quality=1;local reduced=false;local wind=1;local density=1;local targetWind=1;local targetDensity=1;local currentHot;local townTarget;local time=0;local zoneOrigin;local lastBiome;local tickAt=0
local function root()local c=player.Character;return c and c:FindFirstChild('HumanoidRootPart')end
local function treePosition(tree)
 local prompt=tree:FindFirstChild('GatherPrompt',true);local p=prompt and prompt.Parent
 if p then if p:IsA('Attachment')then return p.WorldPosition elseif p:IsA('BasePart')then return p.Position end end
 return tree:IsA('Model')and tree:GetPivot().Position or tree.Position
end
local function groundAt(position,b)
 local area=workspace:FindFirstChild(b or '');local floor=area and area:FindFirstChild((b or '')..'Floor')
 if floor and floor:IsA('BasePart')then return Vector3.new(position.X,floor.Position.Y+floor.Size.Y*.5+.14,position.Z)end
 return position-Vector3.new(0,2.8,0)
end
local function refreshTrees()
 table.clear(trees)
 for _,tree in ipairs(Collection:GetTagged('GatherableTree'))do if tree:IsDescendantOf(workspace)and(tree:GetAttribute('BiomeId')=='Meadow'or tree:GetAttribute('BiomeId')=='Forest')then table.insert(trees,tree)end end
end
refreshTrees();connections[#connections+1]=Collection:GetInstanceAddedSignal('GatherableTree'):Connect(refreshTrees);connections[#connections+1]=Collection:GetInstanceRemovedSignal('GatherableTree'):Connect(refreshTrees)
connections[#connections+1]=Prompts.PromptShown:Connect(function(p)targeted=p:FindFirstAncestorWhichIsA('Model')end)
connections[#connections+1]=Prompts.PromptHidden:Connect(function(p)if targeted==p:FindFirstAncestorWhichIsA('Model')then targeted=nil end end)
local function spawnLeaf(item,r,initial)
 local camera=workspace.CurrentCamera;local look=camera and camera.CFrame.LookVector or r.CFrame.LookVector
 local heading=Vector3.new(look.X,0,look.Z);heading=heading.Magnitude>.1 and heading.Unit or Vector3.zAxis
 local origin=r.Position+heading*random:NextNumber(8,25)+Vector3.new(random:NextNumber(-23,23),0,random:NextNumber(-18,18))
 local meadow=biome=='Meadow';local y=groundAt(origin,biome).Y+random:NextNumber(initial and 3 or 11,initial and 16 or 19)
 item.Start=Vector3.new(origin.X,y,origin.Z);item.Age=0;item.Life=random:NextNumber(7,12);item.Velocity=Vector3.new(random:NextNumber(.5,1.5),random:NextNumber(-1.35,-.65),random:NextNumber(-.4,.6))
 item.Leaf.BackgroundColor3=meadow and(random:NextNumber()<.7 and Color3.fromRGB(255,180+random:NextInteger(0,35),210)or Color3.fromRGB(173,219,123))or Color3.fromRGB(random:NextInteger(146,195),random:NextInteger(151,192),random:NextInteger(64,105))
 item.IsLeaf=not meadow or random:NextNumber()>.72;item.Art.Visible=item.IsLeaf;item.Art.ImageColor3=meadow and Color3.fromRGB(225,255,190)or Color3.fromRGB(235,223,167);item.Vein.Visible=false;if not item.IsLeaf then item.Leaf.BackgroundColor3=Color3.fromRGB(255,random:NextInteger(185,220),216)end
 local size=random:NextNumber(.35,.65);item.Gui.Size=UDim2.fromScale(size,size*1.4);item.Gui.Enabled=true
end
local function updateZones(r)
 if biome~='Forest'then zoneOrigin=nil;return end
 if zoneOrigin and(r.Position-zoneOrigin).Magnitude<32 then return end
 zoneOrigin=r.Position;local candidates={}
 for _,tree in ipairs(trees)do if tree.Parent and tree:GetAttribute('BiomeId')=='Forest'then local p=treePosition(tree);table.insert(candidates,{Tree=tree,Position=p,Distance=(p-r.Position).Magnitude})end end
 table.sort(candidates,function(a,b)return a.Distance<b.Distance end)
 for i,z in ipairs(zones)do
  local c=candidates[math.min(#candidates,1+(i-1)*2)]
  if c then local direction=Vector3.new(math.cos(i*2.2),0,math.sin(i*2.2));local p=groundAt(c.Position+direction*13,'Forest');z.Anchor.Position=p+Vector3.new(0,3,0);z.Ground.Position=p+Vector3.new(0,.3,0)end
 end
end
local function chooseTown(r)
 local entries=workspace:FindFirstChild('KingdomTownInteractions');local gui=player.PlayerGui:FindFirstChild('AnimalKingdomUI')
 if not entries or gui and gui:GetAttribute('OnboardingActive')then return end
 local eligibility={Shop=player:GetAttribute('AKTownShopUnread'),Activities=player:GetAttribute('AKTownActivitiesAvailable'),Index=player:GetAttribute('AKTownIndexUnread'),Garden=player:GetAttribute('AKTownGardenReady'),Biomes=(player:GetAttribute('LuckyTreeEndsAt')or 0)>workspace:GetServerTimeNow()or state.Hot~=nil or state.Invitation and state.Invitation.Kind=='Rush'}
 local priority={Garden=90,Index=85,Shop=65,Biomes=55,Activities=45};local best;local score=-math.huge
 for id,eligible in pairs(eligibility)do local a=entries:FindFirstChild(id);if eligible and a then local distance=(a.Position-r.Position).Magnitude;local s=(priority[id]or 0)-distance*.6;if distance<125 and s>score then score=s;best=a end end end
 return best
end
local function tick(r,now)
 local world=RS:FindFirstChild('KingdomWorld');local ok,s=pcall(game.HttpService.JSONDecode,game.HttpService,world and world:GetAttribute('State')or '{}');state=ok and s or {}
 reduced=player:GetAttribute('AKReducedMotion')==true;quality=math.min(Quality.Resolve().qualityScale,reduced and .35 or 1)
 biome=player:GetAttribute('CurrentBiome');local town=workspace:FindFirstChild('KingdomTownInteractions');local shop=town and town:FindFirstChild('Activities')
 local inTown=shop and(r.Position-shop.Position).Magnitude<150
 if player:GetAttribute('InGarden')then biome='Garden'elseif inTown then biome='Town'elseif biome=='Town'then biome=nil end
 local weather=RS:FindFirstChild('WeatherState');local event=weather and weather:GetAttribute('Phase')=='Event'and weather:GetAttribute('EventId')or ''
 local micro=state.Micro;local active=micro and micro.Biome==biome and micro.EndsAt>now
 local delicate,fireflies,mist=1,1,1;targetWind=1;targetDensity=1
 if event=='RainyDay'then delicate=.22;fireflies=.25;targetWind=1.35
 elseif event=='Thunderstorm'then delicate=.08;fireflies=.1;mist=.4;targetWind=2
 elseif event=='Snowfall'then delicate=.1;fireflies=.15;mist=.15
 elseif event=='Windy'then targetWind=2;delicate=.75
 elseif event=='Foggy'then mist=0;delicate=.55
 elseif event=='SunnySkies'then delicate=1.3
 elseif event~=''then delicate=.4;fireflies=.6;mist=.3 end
 if active and(event==''or event=='SunnySkies')then targetWind=micro.Id=='Fireflies'and 1.15 or 1.8;targetDensity=micro.Id=='Fireflies'and 1.15 or 1.6;if micro.Id=='Fireflies'then fireflies=2.5 end end
 if biome~=lastBiome then for _,item in ipairs(foliage)do item.Age=100 end;zoneOrigin=nil;lastBiome=biome end
 updateZones(r)
 air.Position=r.Position+Vector3.new(0,5,0);motes.Color=ColorSequence.new(biome=='Meadow'and Color3.fromRGB(255,240,182)or Color3.fromRGB(216,231,176))
 motes.Rate=(biome=='Meadow'and 24 or biome=='Forest'and 11 or biome=='Town'and 5 or 0)*quality*delicate*density
 motes.Acceleration=Vector3.new(.45*wind,.05,.17*wind)
 for _,z in ipairs(zones)do
  local visible=biome=='Forest'and(z.Anchor.Position-r.Position).Magnitude<90
  z.Fireflies.Rate=visible and 5*quality*fireflies or 0;z.Mist.Rate=visible and .9*quality*mist or 0
 end
 local candidates={};currentHot=nil
 for _,tree in ipairs(trees)do if tree:IsDescendantOf(workspace)then
  local pos=treePosition(tree);local distance=(pos-r.Position).Magnitude
  if distance<245 and(tree:GetAttribute('HotTreeEndsAt')or 0)>now then currentHot={Tree=tree,Position=groundAt(pos,tree:GetAttribute('BiomeId')),Distance=distance,Color=colors[tree:GetAttribute('HotTreeVariant')]or colors.Rich}end
  if distance<85 and tree:GetAttribute('ResourceState')=='AVAILABLE'then table.insert(candidates,{Tree=tree,Distance=tree==targeted and -1 or distance})end
 end end
 table.sort(candidates,function(a,b)return a.Distance<b.Distance end)
 for i,h in ipairs(ready)do h.Adornee=candidates[i]and candidates[i].Tree;h.Enabled=h.Adornee~=nil;h.OutlineColor=Color3.fromRGB(202,237,167)end
 hotHighlight.Enabled=currentHot~=nil;hotHighlight.Adornee=currentHot and currentHot.Tree;hotGui.Enabled=currentHot~=nil;hotLight.Enabled=currentHot~=nil and currentHot.Distance<115
 hotUp.Rate=0;for _,o in ipairs(orbit)do o.Emitter.Rate=0 end
 for _,b in ipairs(ringBeams)do b.Enabled=currentHot~=nil and currentHot.Distance<150 end
 if currentHot then
  local c=currentHot;hotAnchor.Position=c.Position+Vector3.new(0,3,0);hotGround.Position=c.Position+Vector3.new(0,.08,0);hotHighlight.FillColor=c.Color;hotHighlight.OutlineColor=c.Color:Lerp(Color3.new(1,1,1),.45);hotLight.Color=c.Color;hotUp.Color=ColorSequence.new(c.Color)
  if labelTree~=c.Tree then
   labelTree=c.Tree;local size=c.Tree:IsA('Model')and c.Tree:GetExtentsSize()or c.Tree.Size
   labelRadius=Vector2.new(size.X,size.Z).Magnitude*.5+1
   local radius=math.clamp(math.min(size.X,size.Z)*.5+1,6,16)
   for i,b in ipairs(ringBeams)do b.Attachment0.Position=Vector3.new(math.cos((i-1)*math.pi/8)*radius,0,math.sin((i-1)*math.pi/8)*radius);b.Attachment1.Position=Vector3.new(math.cos(i*math.pi/8)*radius,0,math.sin(i*math.pi/8)*radius)end
  end
  local remaining=math.max(0,math.ceil(c.Tree:GetAttribute('HotTreeEndsAt')-now));label.Text='HOT TREE\n'..string.upper(c.Tree:GetAttribute('HotTreeVariant'))..'\n'..math.floor(remaining/60)..':'..string.format('%02d',remaining%60)
  local available=c.Tree:GetAttribute('ResourceState')=='AVAILABLE'
  hotHighlight.Enabled=available
  if available and c.Distance<115 then hotUp.Rate=10*quality;for _,o in ipairs(orbit)do o.Emitter.Rate=3*quality;o.Emitter.Color=ColorSequence.new(c.Color)end end
  for _,b in ipairs(ringBeams)do b.Color=ColorSequence.new(c.Color)end
 end
 luckyGlints.Rate=0
 if(player:GetAttribute('LuckyTreeEndsAt')or 0)>now then for _,tree in ipairs(workspace:GetChildren())do if tree:GetAttribute('LuckyEventId')then local pos=tree:IsA('Model')and tree:GetPivot().Position or tree.Position;if(pos-r.Position).Magnitude<120 then luckyAnchor.Position=groundAt(pos,player:GetAttribute('LuckyTreeBiome'))+Vector3.new(0,5,0);luckyGlints.Rate=8*quality end;break end end end
 townTarget=chooseTown(r);townHighlight.Enabled=townTarget~=nil;townEmitter.Rate=townTarget and 4*quality or 0
 if townTarget then townAnchor.Position=townTarget.Position+Vector3.new(0,1,0);local path=townTarget:GetAttribute('ExistingLandmark');townHighlight.Adornee=path and workspace:FindFirstChild(path:gsub('^Workspace%.',''));townHighlight.OutlineColor=Color3.fromRGB(255,226,154);townEmitter.Color=ColorSequence.new(Color3.fromRGB(255,231,157))end
 local rate=motes.Rate+hotUp.Rate+luckyGlints.Rate+townEmitter.Rate
 for _,o in ipairs(orbit)do rate+=o.Emitter.Rate end;for _,z in ipairs(zones)do rate+=z.Fireflies.Rate+z.Mist.Rate end
 -- Hard cap all continuous emitters, including concurrent special/Town attention.
 if rate>96*quality then local scale=96*quality/rate;for _,e in ipairs(folder:GetDescendants())do if e:IsA('ParticleEmitter')then e.Rate*=scale end end;rate=96*quality end
 folder:SetAttribute('ParticleRateBudget',rate);folder:SetAttribute('EffectScale',quality);folder:SetAttribute('ActiveBiome',biome);folder:SetAttribute('TownAttention',townTarget and townTarget.Name or '')
end
connections[#connections+1]=RS:WaitForChild('AnimalKingdomRemotes'):WaitForChild('GatherVisual').OnClientEvent:Connect(function(_,position,_,tree,phase)
 local r=root();if not r or typeof(position)~='Vector3'or(r.Position-position).Magnitude>115 or not tree or not tree:IsDescendantOf(workspace)then return end
 if phase~='Committed'then local point=tree:FindFirstChild('AKTreeInteraction',true)or tree:FindFirstChild('LuckyInteraction',true);if point then Sounds.Play('TreeRustle',point);Sounds.Play('TreeShake',point)end end
 if os.clock()-burstAt<.25 then return end;burstAt=os.clock()
 burst.Position=groundAt(position,tree:GetAttribute('BiomeId'))+Vector3.new(0,5,0);burstEmitter.Color=ColorSequence.new(tree:GetAttribute('BiomeId')=='Forest'and Color3.fromRGB(177,192,103)or Color3.fromRGB(255,194,207));burstEmitter:Emit(math.max(5,math.floor((phase=='Committed'and 42 or 14)*quality)))
 -- Reuse a few existing foliage visuals for a readable leaf burst.
 for i=1,math.min(8,math.ceil(8*quality))do local leaf=foliage[i];spawnLeaf(leaf,r,true);leaf.Start=burst.Position+Vector3.new(random:NextNumber(-4,4),random:NextNumber(-1,3),random:NextNumber(-4,4));leaf.Velocity=Vector3.new(random:NextNumber(-2,2),-1.5,random:NextNumber(-2,2));leaf.Life=3 end
end)
connections[#connections+1]=Run.RenderStepped:Connect(function(dt)
 if not alive then return end;local r=root();if not r then return end
 time+=dt;local now=workspace:GetServerTimeNow()
 wind+=(targetWind-wind)*(1-math.exp(-dt*1.4));density+=(targetDensity-density)*(1-math.exp(-dt*1.4))
 if now>=tickAt then tickAt=now+.2;tick(r,now)end
 local pulse=reduced and .5 or .5+.5*math.sin(time*math.pi)
 if currentHot then hotHighlight.FillTransparency=currentHot.Distance>155 and .82 or .54+pulse*.13;hotHighlight.OutlineTransparency=.04+pulse*.12;hotLight.Brightness=.9+pulse*.7 end
 -- Put the depth-tested label in front of the canopy, never inside its mesh.
 -- Reuse the billboard and smooth its offset as the camera moves around the tree.
 local camera=workspace.CurrentCamera
 if currentHot and camera then
  local delta=camera.CFrame.Position-hotAnchor.Position;local flat=Vector3.new(delta.X,0,delta.Z)
  local offset=(flat.Magnitude>.1 and flat.Unit or Vector3.zAxis)*math.min(labelRadius,math.max(0,flat.Magnitude-6))+Vector3.new(0,5,0)
  hotGui.StudsOffsetWorldSpace=hotGui.StudsOffsetWorldSpace:Lerp(offset,1-math.exp(-dt*12))
 end
 for _,b in ipairs(ringBeams)do b.Transparency=NumberSequence.new(.28+pulse*.18)end
 for i,o in ipairs(orbit)do local t=reduced and i*math.pi or time*.85+i*math.pi;o.Attachment.Position=Vector3.new(math.cos(t)*4,math.sin(t*.6)*.4,math.sin(t)*4)end
 for i,h in ipairs(ready)do h.OutlineTransparency=reduced and .92 or h.Adornee==targeted and .53 or .88+.055*math.sin(time*(biome=='Forest'and 1.2 or 1.8)+i)end
 townHighlight.OutlineTransparency=reduced and .45 or .32+.18*pulse
 local count=(biome=='Meadow'or biome=='Forest')and math.min(36,math.ceil(24*quality*density))or biome=='Town'and math.ceil(5*quality)or 0
 for i,item in ipairs(foliage)do
  if i>count then item.Gui.Enabled=false;continue end
  if item.Age>=item.Life or(item.Anchor.Position-r.Position).Magnitude>85 then spawnLeaf(item,r,item.Age==100)end
  item.Age+=dt;local age=item.Age;local phase=item.Seed+age*(reduced and .4 or 1.3)
  local drift=item.Velocity*age;local sway=reduced and .15 or .7
  item.Anchor.Position=item.Start+Vector3.new(drift.X*wind+math.sin(phase)*sway,drift.Y,drift.Z*wind+math.cos(phase*.8)*sway)
  item.Leaf.Rotation=item.Seed*30+(reduced and 0 or age*28+math.sin(phase)*20)
  local camera=workspace.CurrentCamera;local nearFade=camera and math.clamp(((item.Anchor.Position-camera.CFrame.Position).Magnitude-5)/5,0,1)or 1
  local fade=math.min(1,age/.6,(item.Life-age)/1.3)*nearFade;item.Leaf.BackgroundTransparency=item.IsLeaf and 1 or 1-.8*math.max(0,fade);item.Art.ImageTransparency=1-.9*math.max(0,fade)
  if item.Anchor.Position.Y<groundAt(item.Anchor.Position,biome).Y+.2 then item.Age=item.Life end
 end
 folder:SetAttribute('VisibleFoliage',count)
end)
script.Destroying:Connect(function()alive=false;for _,c in ipairs(connections)do c:Disconnect()end;folder:Destroy()end)
