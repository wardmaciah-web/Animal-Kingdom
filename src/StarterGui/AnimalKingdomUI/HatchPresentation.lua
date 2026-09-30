-- Personal presentation of an already-committed server reward. No reward decisions live here.
local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local Prompts=game:GetService('ProximityPromptService')
local Actions=game:GetService('ContextActionService')
local W=require(script.Parent.GameplayWidgets)
local Viewport=require(script.Parent.AnimalKingdomUIV2.Viewport)
local Pets=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Rarities=require(RS.Shared.Gameplay.Definitions.RarityDefinitions)
local Format=require(RS.Shared.Gameplay.PetNumberFormat)
local Camera=require(RS.Shared.Gameplay.CameraOwnership)
local Sounds=require(RS.Shared.Gameplay.PresentationSounds)
local H={Busy=false};local queue={};local activeClose
local function egg(rarity)
 local model=Instance.new('Model');model.Name='RevealEgg'
 local shell=Instance.new('Part');shell.Name='EggShell';shell.Shape=Enum.PartType.Ball;shell.Size=Vector3.new(2.05,2.8,2.05);shell.Color=W.Color.White;shell.Material=Enum.Material.SmoothPlastic;shell.Anchored=true;shell.CanCollide=false;shell.Parent=model;model.PrimaryPart=shell
 -- A leaf motif and gold flecks belong to the reveal egg, never to a pet template.
 for i=1,7 do
  local spot=Instance.new('Part');spot.Name='ShellMark';spot.Shape=Enum.PartType.Ball;spot.Size=Vector3.new(.18,.3,.035);spot.Color=i%2==0 and W.Color.Gold or rarity.Color:Lerp(W.Color.Green,.5);spot.CFrame=CFrame.new(math.sin(i*2.1)*.65,math.cos(i*1.7)*.75,-.8)*CFrame.Angles(0,0,math.rad(i*25));spot.Anchored=true;spot.CanCollide=false;spot.Parent=model
 end
 local points={Vector3.new(-.45,.43,-.96),Vector3.new(-.08,.21,-1.025),Vector3.new(-.23,-.02,-1.03),Vector3.new(.17,-.24,-1.01),Vector3.new(.05,-.49,-.94)}
 for i=2,#points do
  local a,b=points[i-1],points[i];local crack=Instance.new('Part');crack.Name='Crack';crack.Size=Vector3.new(.035,.035,(b-a).Magnitude);crack.CFrame=CFrame.lookAt((a+b)/2,b);crack.Color=W.Color.Gold;crack.Material=Enum.Material.Neon;crack.Transparency=1;crack.Anchored=true;crack.CanCollide=false;crack.Parent=model
 end
 return model
end
local shownUIDs,shownOrder={},{}
function H.Play(screen,result,reduced,ctx)
 local entry=result.Results and result.Results[1];if not entry or not entry.Pet or shownUIDs[entry.Pet.UID] then return end
 if H.Busy then if #queue<8 then table.insert(queue,{screen,result,reduced,ctx})end;return end
 shownUIDs[entry.Pet.UID]=true;table.insert(shownOrder,entry.Pet.UID)
 if #shownOrder>128 then shownUIDs[table.remove(shownOrder,1)]=nil end
 H.Busy=true
 screen:SetAttribute('RewardRevealActive',true)
 local previousPrompts=Prompts.Enabled;Prompts.Enabled=false
 Actions:BindActionAtPriority('CompanionSearchLock',function()return Enum.ContextActionResult.Sink end,false,3000,Enum.KeyCode.E)
 local d=Pets[entry.Pet.PetId];local rarity=d and Rarities[d.Rarity] or Rarities.Common
 local shade=W.New('TextButton',{Name='CompanionReveal',Text='',Size=UDim2.fromScale(1,1),BackgroundColor3=W.Color.WoodDark,BackgroundTransparency=.24,BorderSizePixel=0,AutoButtonColor=false,Selectable=false,Active=true,ZIndex=60},screen)
 local panel=W.Surface(shade,'RevealCard',UDim2.new(.92,0,.93,0),UDim2.fromScale(.5,.5),'Wood');panel.AnchorPoint=Vector2.new(.5,.5);W.New('UISizeConstraint',{MaxSize=Vector2.new(860,650)},panel);W.Decorate(panel)
 local stageInset=ctx and ctx.Compact and 12 or 24
 local stage=W.New('Frame',{Name='SpotlightStage',Size=UDim2.new(1,-stageInset*2,1,-stageInset*2),Position=UDim2.fromOffset(stageInset,stageInset),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ClipsDescendants=true},panel);W.Round(stage,16);W.Gradient(stage,Color3.fromRGB(112,100,67),Color3.fromRGB(40,58,43));W.Stroke(stage,W.Color.Gold,2)
 -- A soft local spotlight treatment, with the viewport doing the actual model lighting.
 local haze=W.Image(stage,'rbxasset://textures/glow.png',UDim2.fromScale(.82,.9),UDim2.fromScale(.09,-.05));haze.Name='SoftSpotlight';haze.ImageColor3=W.Color.Gold;haze.ImageTransparency=.38
 local glow=W.Image(stage,'rbxasset://textures/glow.png',UDim2.fromScale(.6,.14),UDim2.fromScale(.2,.61));glow.Name='RarityStageGlow';glow.ImageColor3=rarity.Color;glow.ImageTransparency=.3;glow.ScaleType=Enum.ScaleType.Stretch
 local title=W.Heading(stage,'A COMPANION IS WAITING…',UDim2.new(1,-36,0,40),UDim2.fromOffset(18,7),ctx and ctx.Compact and 18 or 26,W.Color.White);title.TextXAlignment=Enum.TextXAlignment.Center;title.TextStrokeTransparency=.5
 local viewSize=UDim2.new(1,-30,1,-170);local viewPos=UDim2.fromOffset(15,39)
 local petView=W.PetPreview(stage,entry.Pet,viewSize,viewPos);petView.Name='EarnedPet';petView.ImageTransparency=1;petView.Ambient=Color3.fromRGB(245,245,240);petView.LightColor=Color3.fromRGB(255,250,239);petView.LightDirection=Vector3.new(-.35,-.6,-1)
 Viewport.Showcase(petView)
 local eggView=W.Viewport(stage,egg(rarity),viewSize,viewPos);eggView.Name='HatchingEgg'
 local details=W.New('Frame',{Name='CompanionDetails',Size=UDim2.new(1,-32,0,83),Position=UDim2.new(0,16,1,-132),BackgroundTransparency=1,Visible=false},stage)
 local name=W.Heading(details,d and d.DisplayName or 'Companion',UDim2.new(1,0,0,29),nil,ctx and ctx.Compact and 19 or 26,W.Color.White);name.TextXAlignment=Enum.TextXAlignment.Center
 local text=W.Text(details,(d and d.Rarity or '')..'  •  '..Format.Weight(entry.Pet.Weight)..'  •  '..Format.Income(entry.Pet.CoinsPerSecond),UDim2.new(1,0,0,25),UDim2.fromOffset(0,29),13,rarity.Color:Lerp(W.Color.White,.55));text.TextXAlignment=Enum.TextXAlignment.Center
 local record=entry.WeightRecord
 local recordText=record and (record.First and string.format('First recorded weight: %.2f kg',record.Weight) or string.format('%.2f kg • Previous best: %.2f kg',record.Weight,record.Previous))
 local destinationText=entry.Destination=='Held'  and 'ADDED TO HELD PETS' or 'SENT TO PET INVENTORY'
 local destination=W.Text(details,recordText or destinationText,UDim2.new(1,0,0,22),UDim2.fromOffset(0,55),12,W.Color.White);destination.TextXAlignment=Enum.TextXAlignment.Center
 local closed,ready=false,false;local born=os.clock()
 local duration=reduced and .45 or math.clamp(tonumber(result.Duration) or 1.3,.6,30)
 shade:SetAttribute('HatchDuration',duration)
 local continueButton,equipButton,skipButton
 local function close(immediate)
  if closed then return end;closed=true
  Actions:UnbindAction('CompanionSearchLock');Prompts.Enabled=previousPrompts;Camera.RestorePlayer()
  if ctx and not immediate then ctx.Notify(destinationText)end
  screen:SetAttribute('LastFinishedRevealUID',entry.Pet.UID)
  H.Busy=false;screen:SetAttribute('RewardRevealActive',false);activeClose=nil;if ctx then ctx.RevealBack=nil;ctx.Manager:SetModal(nil)end
  local function dispose()if shade.Parent then shade:Destroy()end end
  if immediate then dispose()else W.Motion.ModalClose(panel,dispose)end
  if #queue>0 then local item=table.remove(queue,1);task.delay(.2,function()H.Play(table.unpack(item))end)end
 end
 local function showcase()
  if closed or ready then return end;ready=true
  if not Viewport.Ready(petView) and os.clock()-born<8 then
   ready=false;title.Text='YOUR COMPANION IS ARRIVING…';task.delay(.15,showcase);return
  end
  if eggView.Parent then eggView:Destroy()end
  title.Text=(record and not record.First and 'NEW WEIGHT RECORD!' or entry.NewDiscovery and 'NEW DISCOVERY!' or 'NEW COMPANION!')..((entry.Pet.WeightQuality or '')~='' and (' • '..entry.Pet.WeightQuality) or '')
  Sounds.Play('EggCrack',screen)
  petView.ImageTransparency=0;W.Motion.PetReveal(petView);details.Visible=true
  if not reduced then Viewport.Turntable(petView,10)end
  continueButton.Visible=true;equipButton.Visible=ctx~=nil and not entry.AutoDeleted;skipButton.Visible=false
  Sounds.Play(rarity.Order>=5 and 'LegendaryFound' or 'PetReveal',screen)
  if ctx then ctx.Manager:Focus(shade,'ContinueReward')end
  shade:SetAttribute('Phase','Showcase')
 end
 continueButton=W.Button(stage,'CONTINUE',UDim2.new(.46,0,0,44),UDim2.new(.03,0,1,-51),function()close(false)end);continueButton.Name='ContinueReward';continueButton.Visible=false
 equipButton=W.Button(stage,entry.Destination=='Held' and 'HOLD PET' or 'OPEN PETS',UDim2.new(.46,0,0,44),UDim2.new(.51,0,1,-51),function()
  if closed or not ctx then return end
  close(false);task.delay(.22,function()if entry.Destination=='Held' then ctx.ViewPet(entry.Pet) else ctx.Open('Pets') end end)
 end,W.Color.Wood);equipButton.Name='EquipReward';equipButton.Visible=false
 skipButton=W.CreamSecondaryButton(stage,'Skip animation',UDim2.fromOffset(158,44),UDim2.new(.5,-79,1,-53),function()if os.clock()-born>.35 then showcase()end end);skipButton.Name='SkipHatch'
 if ctx and ctx.Short then
  title.Size=UDim2.new(.51,-20,0,38);title.Position=UDim2.new(.49,8,0,10);title.TextSize=16
  for _,view in ipairs({petView,eggView})do view.Size=UDim2.new(.49,-8,1,-20);view.Position=UDim2.fromOffset(5,10)end
  haze.Size=UDim2.fromScale(.5,.94);haze.Position=UDim2.fromScale(0,0)
  glow.Size=UDim2.fromScale(.4,.14);glow.Position=UDim2.fromScale(.04,.78)
  details.Size=UDim2.new(.49,-14,0,70);details.Position=UDim2.new(.51,0,.27,0);name.TextSize=18;name.Size=UDim2.new(1,0,0,24);text.TextSize=11;text.Position=UDim2.fromOffset(0,24);destination.Position=UDim2.fromOffset(0,48);destination.TextSize=10
  continueButton.Size=UDim2.new(.235,-8,0,44);continueButton.Position=UDim2.new(.51,0,1,-54);continueButton.TextSize=13
  equipButton.Size=UDim2.new(.235,-8,0,44);equipButton.Position=UDim2.new(.755,0,1,-54);equipButton.TextSize=13
  skipButton.Size=UDim2.new(.46,-8,0,44);skipButton.Position=UDim2.new(.51,0,1,-54)
 end
 activeClose=function()close(true)end
 if ctx then ctx.RevealBack=function()if ready then close(false)elseif os.clock()-born>.35 then showcase()end end;ctx.Manager:SetModal(shade)end
 shade:SetAttribute('PetTypeId',entry.Pet.PetId);shade:SetAttribute('OwnedPetInstanceId',entry.Pet.UID);shade:SetAttribute('Phase','Egg')
 Viewport.Animate(eggView,function(model,base,t)
  if closed or ready then return false end
  if t>=duration then task.defer(showcase);return false end
  t=t/duration*1.3 -- Normalize animation beats to the authoritative duration.
  local wobble=not reduced and math.sin(t*(t<.55 and 15 or 28))*math.rad(t<.55 and 8 or 17) or 0
  local lift=not reduced and (t>.98 and math.sin(math.min(1,(t-.98)/.28)*math.pi)*.32 or math.sin(t*math.pi)*.06) or 0
  model:PivotTo(CFrame.new(0,lift,0)*base*CFrame.Angles(0,0,wobble))
  if t>.72 then for _,part in ipairs(model:GetChildren())do if part.Name=='Crack'then part.Transparency=0 end end end
 end)
 W.Motion.ModalOpen(panel)
 -- A failed viewport must never trap input or gate ownership of the server reward.
 task.delay(duration+1,showcase)
end
function H.Cleanup()table.clear(queue);if activeClose then activeClose()end end
Players.LocalPlayer.CharacterRemoving:Connect(H.Cleanup)
local deathConnection
local function watchCharacter(character)
 if deathConnection then deathConnection:Disconnect();deathConnection=nil end
 task.spawn(function()
  local humanoid=character:WaitForChild('Humanoid',8)
  if humanoid and character==Players.LocalPlayer.Character then deathConnection=humanoid.Died:Connect(H.Cleanup)end
 end)
end
Players.LocalPlayer.CharacterAdded:Connect(watchCharacter)
if Players.LocalPlayer.Character then watchCharacter(Players.LocalPlayer.Character)end
return H
