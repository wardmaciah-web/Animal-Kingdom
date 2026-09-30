-- Shared presentation only; Roblox still routes the actual prompt to the server.
local Players=game:GetService('Players')
local PromptService=game:GetService('ProximityPromptService')
local TweenService=game:GetService('TweenService')
local Input=game:GetService('UserInputService')
local RunService=game:GetService('RunService')
local player=Players.LocalPlayer
local screen=player.PlayerGui:WaitForChild('AnimalKingdomUI')
local W=require(screen.AnimalKingdomUIV2.Components)
local views={}
local shown,screenConnections={},{}
local projection
local function permitted()return screen and screen.Parent and screen:GetAttribute('ActiveMenu')==''and not screen:GetAttribute('RewardRevealActive')and not screen:GetAttribute('ModalActive')end
local function project()
 local camera=workspace.CurrentCamera;if not camera then return end
 for _,view in pairs(views)do
  local anchor=view.Anchor
  if anchor.Parent then
   local point=anchor:IsA('Attachment')and anchor.WorldPosition or anchor.Position
   local p,onScreen=camera:WorldToViewportPoint(point+Vector3.new(0,2.6,0))
   view.Gui.Visible=onScreen and permitted()
   if not view.Gui:GetAttribute('LuckyFixedPosition')then view.Gui.Position=UDim2.fromOffset(p.X-screen.AbsolutePosition.X,p.Y-screen.AbsolutePosition.Y)end
  else view.Gui.Visible=false end
 end
end
local function supported(prompt)return prompt:IsA('ProximityPrompt')and(prompt.Name=='LuckyTreePrompt'or prompt.Name=='GatherPrompt'or prompt.Name=='ReturnPrompt'or prompt.Name=='SanctuaryPetSlotPrompt'or prompt.Name=='PawPrompt'or prompt.Name=='TownPrompt')end
local function style(prompt)
 if not supported(prompt)then return end
 prompt.Style=Enum.ProximityPromptStyle.Custom
 prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
end
local function remove(prompt)
 local view=views[prompt];if not view then return end
 if view.Cleanup then view.Cleanup()end
 if view.Tween then view.Tween:Cancel()end
 for _,c in ipairs(view.Connections)do c:Disconnect()end
 view.Gui:Destroy();views[prompt]=nil
 if not next(views)and projection then projection:Disconnect();projection=nil end
end
local function show(prompt,kind)
 if not supported(prompt)then return end
 remove(prompt)
 if not screen or not screen.Parent then return end
 local anchor=prompt.Parent
 if anchor:IsA('Model')then anchor=anchor.PrimaryPart or anchor:FindFirstChildWhichIsA('BasePart',true)end
 if not anchor then return end
 -- Screen-space cards keep the tap target in the same safe-area coordinate
 -- space as the rest of the HUD. One connection projects only shown prompts.
 local gui=W.New('Frame',{Name='KingdomPrompt',Size=UDim2.fromOffset(252,88),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,ZIndex=4,Visible=false},screen)
 local ref=Instance.new('ObjectValue');ref.Name='PromptTarget';ref.Value=prompt;ref.Parent=gui
 local card=W.Surface(gui,'PromptCard',UDim2.new(1,-4,1,-4),UDim2.fromOffset(2,2),'Wood')
 local key=kind==Enum.ProximityPromptInputType.Touch and 'Tap' or kind==Enum.ProximityPromptInputType.Gamepad and 'X' or 'E'
 local button=W.Button(card,key,UDim2.fromOffset(48,48),UDim2.fromOffset(12,16),nil,W.Color.Green);button.Name='Interact';button.TextSize=22;button.Selectable=false
 local objectText=W.Heading(card,prompt.ObjectText,UDim2.new(1,-82,0,25),UDim2.fromOffset(72,13),15,W.Color.White)
 local actionText=W.Text(card,prompt.ActionText:gsub('SEARCH','Search'):gsub('SHAKE TREE','Search tree'),UDim2.new(1,-82,0,32),UDim2.fromOffset(72,37),12,W.Color.White)
 local track,fill=W.ProgressBar(card,0,UDim2.new(1,-30,0,4),UDim2.fromOffset(15,74))
 local entry={Gui=gui,Anchor=anchor,Connections={}};views[prompt]=entry
 if prompt.Name=='LuckyTreePrompt'then
  objectText.Name='LuckyPromptTitle';button.Selectable=true
  entry.Cleanup=require(screen.LuckyTreePresentation).Attach(screen,prompt,gui,button,actionText,kind)
 end
 if not projection then projection=RunService.RenderStepped:Connect(project)end;project()
 local function connect(signal,fn)table.insert(entry.Connections,signal:Connect(fn))end
 if prompt.Name=='SanctuaryPetSlotPrompt' then
  gui:SetAttribute('SanctuarySlotId',prompt:GetAttribute('SlotId'))
  connect(prompt:GetPropertyChangedSignal('ActionText'),function()actionText.Text=prompt.ActionText end)
  connect(prompt:GetPropertyChangedSignal('ObjectText'),function()objectText.Text=prompt.ObjectText end)
 end
 -- A touch/click starts the same short hold as E/X; a quick tap must not cancel it.
 connect(button.Activated,function()
  if not permitted()or not prompt.Enabled then return end
  prompt:InputHoldBegin()
  task.delay(prompt.HoldDuration+.03,function()if prompt.Parent then prompt:InputHoldEnd()end end)
 end)
 connect(prompt.PromptButtonHoldBegan,function()
  if entry.Tween then entry.Tween:Cancel()end
  fill.Size=UDim2.fromScale(0,1)
  entry.Tween=TweenService:Create(fill,TweenInfo.new(prompt.HoldDuration,Enum.EasingStyle.Linear),{Size=UDim2.fromScale(1,1)});entry.Tween:Play()
 end)
 connect(prompt.PromptButtonHoldEnded,function()if entry.Tween then entry.Tween:Cancel()end;fill.Size=UDim2.fromScale(0,1)end)
 connect(prompt.Triggered,function()
  W.Motion.ButtonPress(card)
  if prompt.Name=='LuckyTreePrompt' and permitted()then require(screen.LuckyTreePresentation).Try(screen,prompt)end
 end)
 connect(prompt.Destroying,function()shown[prompt]=nil;remove(prompt)end)
end
PromptService.PromptShown:Connect(function(prompt,kind)if supported(prompt)then shown[prompt]=kind;show(prompt,kind)end end)
PromptService.PromptHidden:Connect(function(prompt)shown[prompt]=nil;remove(prompt)end)
local function bindScreen(nextScreen)
 for _,c in ipairs(screenConnections)do c:Disconnect()end;table.clear(screenConnections)
 for prompt in pairs(views)do remove(prompt)end
 screen=nextScreen;W=require(screen:WaitForChild('AnimalKingdomUIV2'):WaitForChild('Components'))
 for _,attribute in ipairs({'ActiveMenu','RewardRevealActive','ModalActive'})do
  screenConnections[#screenConnections+1]=screen:GetAttributeChangedSignal(attribute):Connect(project)
 end
 screenConnections[#screenConnections+1]=screen.Destroying:Connect(function()
  for prompt in pairs(views)do remove(prompt)end;screen=nil
 end)
 for prompt,kind in pairs(shown)do if prompt.Parent then show(prompt,kind)else shown[prompt]=nil end end
end
bindScreen(screen)
local added=player.PlayerGui.ChildAdded:Connect(function(child)if child.Name=='AnimalKingdomUI' and child:IsA('ScreenGui')then bindScreen(child)end end)
for _,object in ipairs(workspace:GetDescendants())do style(object)end
workspace.DescendantAdded:Connect(style)
script.Destroying:Once(function()added:Disconnect();for _,c in ipairs(screenConnections)do c:Disconnect()end;for prompt in pairs(views)do remove(prompt)end end)
