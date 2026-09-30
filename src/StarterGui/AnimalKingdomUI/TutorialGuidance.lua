-- Client guidance observes canonical state; it never awards pets, moves pets or credits money.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local W=require(script.Parent.GameplayWidgets)
local Definitions=require(game.ReplicatedStorage.Shared.Gameplay.Definitions.TutorialDefinitions)
local L=require(game.ReplicatedStorage.Shared.Gameplay.PetLocations)
local M={};M.__index=M
function M.new(root,screen,ctx,bar,quick)
 local self=setmetatable({Root=root,Screen=screen,Ctx=ctx,Bar=bar,Quick=quick,Started=workspace:GetServerTimeNow(),Elapsed=0},M)
 self.Pointer=require(script.Parent.AnimalKingdomUIV2.TutorialPointer).new(root)
 self.Card=W.Surface(root,'TutorialMessage',UDim2.fromOffset(420,66),UDim2.new(.5,0,0,72),'Wood');self.Card.AnchorPoint=Vector2.new(.5,0);self.Card.ZIndex=40;self.Card.Visible=false
 local paper=W.Surface(self.Card,'Parchment',UDim2.new(1,-8,1,-8),UDim2.fromOffset(4,4),'Paper')
 W.Icon(paper,'Pets',UDim2.fromOffset(38,38),UDim2.fromOffset(6,8))
 self.Title=W.Heading(paper,'',UDim2.new(1,-62,0,23),UDim2.fromOffset(48,4),16)
 self.Body=W.Text(paper,'',UDim2.new(1,-62,1,-27),UDim2.fromOffset(48,26),13,W.Color.Ink)
 self.Connection=Run.Heartbeat:Connect(function(dt)self.Elapsed+=dt;if self.Elapsed>=.15 then self.Elapsed=0;self:Tick()end end)
 return self
end
function M:Update(data)
 self.Data=data
 local p=data and data.TutorialProgress
 if p and p.Step>=3 and p.Step<=5 then self:Tick()end
end
function M:Point(target)
 if target and target~=self.LastTarget then
  local ancestor=target.Parent
  while ancestor and ancestor~=self.Screen do
   if ancestor:IsA('ScrollingFrame')then
    local d=target.AbsolutePosition.Y-ancestor.AbsolutePosition.Y
    if d<4 then ancestor.CanvasPosition=Vector2.new(ancestor.CanvasPosition.X,math.max(0,ancestor.CanvasPosition.Y+d-4))
    elseif d+target.AbsoluteSize.Y>ancestor.AbsoluteSize.Y-4 then ancestor.CanvasPosition+=Vector2.new(0,d+target.AbsoluteSize.Y-ancestor.AbsoluteSize.Y+4)end
   end
   ancestor=ancestor.Parent
  end
  if self.Ctx.Manager.Active then self.Ctx.Manager:Focus(self.Ctx.Manager.Panel,target.Name)end
 end
 self.LastTarget=target;self.Pointer:Target(target)
end
function M:Find(name)return self.Root:FindFirstChild(name,true)end
function M:Message(body,title)self.Title.Text=title or self.Title.Text;self.Body.Text=body end
function M:Prompt(prompt)
 for _,gui in ipairs(self.Screen:GetChildren())do
  local ref=gui:FindFirstChild('PromptTarget')
  if ref and ref.Value==prompt and gui.Visible then return gui:FindFirstChild('Interact',true)end
 end
end
function M:CloseMenuGuidance()
 if self.Ctx.Manager.Active then self:Point(self:Find('CloseMenu'));self:Message('Close this menu to follow the arrow.');return true end
 return false
end
function M:Travel(destination)
 self.Pointer:World(nil)
 if self.Ctx.Manager.Active=='Biomes' then self:Point(self:Find(destination=='Meadow' and 'Travel_Meadow' or 'Travel_Plot'))
 elseif self.Ctx.Manager.Active then self:Point(self:Find('Nav_Biomes'))
 else self:Point(self:Find('Nav_Biomes'))end
 self:Message(destination=='Meadow' and 'Open Biomes and travel to the Meadow.' or 'Travel to your Sanctuary.')
end
function M:World(position,prompt,highlight,near)
 if self:CloseMenuGuidance()then self.Pointer:World(nil);return end
 local root=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
 local close=root and (root.Position-position).Magnitude<=(near or 9) and (not prompt or prompt.Enabled)
 self.Pointer:World(close and nil or position,prompt and not prompt.Enabled and .6 or near,highlight)
 self:Point(close and prompt and self:Prompt(prompt) or nil)
 if close and prompt and not self.LastTarget then self:Message('Face the highlighted spot to use its '..(prompt.Name=='GatherPrompt' and 'Search' or 'PLACE')..' prompt.')end
end
function M:Hold(pet)
 if not pet then return false end
 if pet.Location=='Held' and self.Data.ActiveHeldPetUID~=pet.UID then
  self.Pointer:World(nil)
  self.WaitingHeldUID=pet.UID
  if not self:CloseMenuGuidance()then self:Point(self.Bar.Root:FindFirstChild('HeldSlot_'..pet.LocationSlot));self:Message('Tap your new pet to hold it.')end
  return true
 elseif pet.Location=='Inventory' then
  self.Pointer:World(nil)
  self:Message(L.FirstFree(self.Data,'Held',5) and 'Hold your pet from All Pets to continue.' or 'Store a Held pet to make room, then hold this pet.')
  if self.Ctx.Manager.Active=='Pets'then self:Point(self:Find('Select_'..pet.UID))else self:Point(self:Find('Nav_Pets'))end
  return true
 end
 if pet.Location=='Held' and self.WaitingHeldUID==pet.UID then
  self.WaitingHeldUID=nil;self.Quick:Close()
  if self.Data.TutorialProgress.Step==3 then self.Ctx.Manager:Focus(self.Ctx.Manager.Nav,'Nav_Biomes')end
 end
 return false
end
function M:HideCompletion()
 if self.Completion then
  if self.Ctx.Manager.Modal==self.Completion then self.Ctx.Manager:SetModal(nil)end
  self.Completion:Destroy();self.Completion=nil
 end
end
function M:Finish()
 self.Pointer:Clear();self.Card.Visible=false
 if self.Completion then return end
 if self.Ctx.Manager.Modal then return end
 self.Quick:Close();self.Ctx.Close()
 local frame=W.Surface(self.Root,'TutorialCompletion',UDim2.new(1,-24,0,310),UDim2.fromScale(.5,.48),'Wood');frame.AnchorPoint=Vector2.new(.5,.5);frame.ZIndex=55
 W.New('UISizeConstraint',{MaxSize=Vector2.new(490,310)},frame)
 local paper=W.Surface(frame,'Parchment',UDim2.new(1,-14,1,-14),UDim2.fromOffset(7,7),'Paper')
 W.Icon(paper,'Pets',UDim2.fromOffset(46,46),UDim2.new(.5,-23,0,8))
 local title=W.Heading(paper,'Congratulations!',UDim2.new(1,-24,0,38),UDim2.fromOffset(12,54),28);title.TextXAlignment=Enum.TextXAlignment.Center
 local body=W.Text(paper,Definitions[6].Text,UDim2.new(1,-30,0,88),UDim2.fromOffset(15,96),15);body.TextXAlignment=Enum.TextXAlignment.Center
 local done=W.Button(paper,'COMPLETE TUTORIAL',UDim2.new(1,-28,0,44),UDim2.fromOffset(14,191),function()self.Ctx.Request('TutorialComplete',{})end);done.Name='CompleteTutorial'
 local restart=W.Button(paper,'RESTART TUTORIAL',UDim2.new(1,-28,0,44),UDim2.fromOffset(14,244),function()self.Ctx.Request('TutorialRestart',{})end,W.Color.Wood);restart.Name='RestartTutorial'
 self.Completion=frame;self.Ctx.Manager:SetModal(frame);W.Motion.WindowOpen(frame)
end
function M:Tick()
 local d=self.Data;local p=d and d.TutorialProgress;local player=Players.LocalPlayer
 local char=player.Character;local root=char and char:FindFirstChild('HumanoidRootPart');local hum=char and char:FindFirstChildOfClass('Humanoid')
 local enabled=d and not d.TutorialCompleted and p and p.FlowVersion==2 and player:GetAttribute('ProfileReady') and player:GetAttribute('HasPlot') and root and hum and hum.Health>0
 local active=enabled and p.Step~=6 and not self.Screen:GetAttribute('RewardRevealActive')
 if self.Screen:GetAttribute('OnboardingActive')~=(active==true)then self.Screen:SetAttribute('OnboardingActive',active==true)end
 self.Card.Visible=active==true and not self.Ctx.Manager.Modal
 if not enabled then
  self:HideCompletion()
  if self.Ctx.ActivityGuidance then self.Ctx.ActivityGuidance(self.Pointer)else self.Pointer:Clear()end
  return
 end
 local pet=L.Find(d,p.PetUID)
 local step=p.Step
 -- Pets and TutorialProgress can arrive in separate profile updates. Clear the old
 -- PLACE target as soon as canonical placement arrives, before its prompt changes to PICK UP.
 if step>=3 and step<=5 and pet then
  if pet.Location=='Sanctuary' then
   local sanctuaries=workspace:FindFirstChild('Sanctuaries');local own=sanctuaries and sanctuaries:FindFirstChild(tostring(player.UserId))
   local interactions=own and own:FindFirstChild('SlotInteractions')
   local slot=interactions and interactions:FindFirstChild('Slot_'..tostring(pet.LocationSlot))
   if not slot then self.Pointer:Clear();self:Message('Your Sanctuary is getting ready…');return end
   step=5
  elseif step==5 then step=4 end
 end
 if step~=self.LastStep then
  if self.LastStep==1 and step==2 and self.Ctx.Manager.Active=='Biomes' then self.Ctx.Close()end
  if step==1 then self.OpenedWelcome=false end
  self.LastStep=step;self.Pointer:Clear();self.LastTarget=nil
 end
 if step==6 then self:Finish();return else self:HideCompletion()end
 if not self.Card.Visible then self.Pointer:Clear();return end
 local compact=self.Root.AbsoluteSize.X<900 or self.Root.AbsoluteSize.Y<580
 self.Card.Size=UDim2.fromOffset(math.min(420,self.Root.AbsoluteSize.X-16),66)
 self.Card.Position=UDim2.new(.5,0,0,compact and 0 or 72)
 self.Title.Text=Definitions[step].Title;self.Body.Text=Definitions[step].Text
 if step==1 then
  self.Pointer:World(nil)
  if not self.OpenedWelcome then self.OpenedWelcome=true;if self.Ctx.Manager.Active~='Biomes'then self.Ctx.Open('Biomes')end end
  self:Point(self:Find(self.Ctx.Manager.Active=='Biomes' and 'Travel_Meadow' or 'Nav_Biomes'))
  if #d.Pets>0 then self:Message('Travel to the Meadow and search for a pet.')end
 elseif step==2 then
  if pet then
   self.Pointer:World(nil);self:Point(nil);self:Message('Meet your new companion, then continue!')
   local now=workspace:GetServerTimeNow()
   local closed=self.Screen:GetAttribute('LastFinishedRevealUID')==pet.UID or (p.RevealReadyAt or now)<self.Started or now>(p.RevealReadyAt or now)+15
   if closed and now>=(p.RevealReadyAt or math.huge) and os.clock()>(self.AckAt or 0)then self.AckAt=os.clock()+1.5;self.Ctx.Request('TutorialRevealDone',{UID=pet.UID})end
  elseif player:GetAttribute('CurrentBiome')~='Meadow' or player:GetAttribute('InGarden') then self:Travel('Meadow')
  else
   local ref=player:FindFirstChild('TutorialTreeTarget');local tree=ref and ref.Value
   local prompt=tree and tree:FindFirstChild('GatherPrompt',true)
   local anchor=prompt and prompt.Parent
   if tree and anchor and tree:GetAttribute('ResourceState')=='AVAILABLE' then
    local position=anchor:IsA('Attachment')and anchor.WorldPosition or anchor.Position
    self:Message("Search "..prompt.ObjectText.." to meet a companion.")
    self:World(position,prompt,tree,11)
   else self.Pointer:World(nil);self:Point(nil);self:Message('Finding an available Meadow tree…')end
  end
 elseif step==3 then
  if not self:Hold(pet)then self:Travel('Plot')end
 elseif step==4 then
  if self:Hold(pet)then return end
  local sanctuaries=workspace:FindFirstChild('Sanctuaries');local own=sanctuaries and sanctuaries:FindFirstChild(tostring(player.UserId));local interactions=own and own:FindFirstChild('SlotInteractions')
  local slot=interactions and interactions:FindFirstChild('Slot_'..tostring(p.SlotId))
  if slot and not L.At(d,'Sanctuary',p.SlotId) then
   local prompt=slot:FindFirstChild('SanctuaryPetSlotPrompt')
   -- Prompt state may lag the pet snapshot. Never emphasize normal PICK UP/SWAP UI.
   if prompt and prompt.ActionText~='PLACE' then self.Pointer:Clear();self.LastTarget=nil;return end
   if (root.Position-slot.Position).Magnitude>180 or player:GetAttribute('InGarden')then self:Travel('Plot')else self:World(slot.Position,prompt,slot,8)end
  else self.Pointer:Clear();self.LastTarget=nil;self:Message('Finding an empty Sanctuary slot…')end
 elseif step==5 then
  local plots=workspace:FindFirstChild('PlayerPlots');local pad
  if plots then for _,plot in ipairs(plots:GetChildren())do if plot:GetAttribute('OwnerUserId')==player.UserId then pad=plot:FindFirstChild('IncomeCollector');break end end end
  if pad then
   if (root.Position-pad.Position).Magnitude>180 or player:GetAttribute('InGarden')then self:Travel('Plot')
   else
    self:World(pad.Position,nil,pad,8)
    if not self.Ctx.Manager.Active and (root.Position-pad.Position).Magnitude<=12 then
     self:Message((pad:GetAttribute('CollectibleCoins')or 0)>=1 and 'Step onto the collection pad to claim your coins!' or (d.Currencies.Coins>=9000000000000000 and 'Your coin wallet is full. Spend coins, then return to collect.' or 'Your pet is still earning — give it a moment!'))
    end
   end
  else self:Point(nil);self:Message('Your collection pad is getting ready…')end
 end
end
function M:Destroy()
 self.Connection:Disconnect();self.Pointer:Destroy();self:HideCompletion();self.Card:Destroy();self.Screen:SetAttribute('OnboardingActive',false)
end
return M
