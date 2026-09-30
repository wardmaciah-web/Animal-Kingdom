-- Small actions on the existing five Held slots; the canonical server still decides every change.
local Input=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local W=require(script.Parent.GameplayWidgets)
local L=require(game.ReplicatedStorage.Shared.Gameplay.PetLocations)
local Sell=require(game.ReplicatedStorage.Shared.Gameplay.SellValueCalculator)
local Bridge=require(script.Parent.RemoteBridge)
local M={};M.__index=M
function M.new(root,screen,bar,manager)
 local self=setmetatable({Root=root,Screen=screen,Bar=bar,Manager=manager,Connections={}},M)
 self.Card=W.Surface(root,'HeldPetActions',UDim2.fromOffset(190,116),nil,'Wood');self.Card.ZIndex=45;self.Card.Visible=false
 self.Sell=W.Button(self.Card,'SELL HELD PET',UDim2.new(1,-16,0,44),UDim2.fromOffset(8,8),function()self:Action('SellPets',{Mode='Held',UID=self.UID})end,W.Color.Red);self.Sell.Name='SellHeldPet';self.Sell.TextSize=13
 self.Store=W.Button(self.Card,'STORE PET',UDim2.new(1,-16,0,44),UDim2.fromOffset(8,62),function()self:Action('MovePet',{UID=self.UID,Location='Inventory',Slot=0})end);self.Store.Name='StoreHeldPet'
 self.Connections[#self.Connections+1]=Bridge.Completed:Connect(function(r)
  if r.Action=='Equip' and self.PendingUID then
   if r.Success then self.SelectionAccepted=true else self:Close()end
   self:Update(self.Data)
  elseif r.Success and self.ActionPending==r.Action then self:Close()end
  if self.ActionPending==r.Action then self.ActionPending=nil end
 end)
 self.Connections[#self.Connections+1]=Input.InputBegan:Connect(function(input)
  if not self.Card.Visible or (input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch)then return end
  local point=Vector2.new(input.Position.X,input.Position.Y)
  local function inside(o)local p=o.AbsolutePosition;local s=o.AbsoluteSize;return point.X>=p.X and point.Y>=p.Y and point.X<=p.X+s.X and point.Y<=p.Y+s.Y end
  if not inside(self.Card) and not inside(self.Bar.Root)then self:Close()end
 end)
 self.Connections[#self.Connections+1]=Run.RenderStepped:Connect(function()self:Position()end)
 self.Connections[#self.Connections+1]=screen:GetAttributeChangedSignal('RewardRevealActive'):Connect(function()if screen:GetAttribute('RewardRevealActive')then self:Close()end end)
 return self
end
function M:Select(pet)
 self:Close();self.PendingUID=pet.UID
 if self.Data and self.Data.ActiveHeldPetUID==pet.UID then self.UID=pet.UID;self.PendingUID=nil;self:Update(self.Data);return end
 if not Bridge.Request('Equip',{UID=pet.UID,Equipped=true})then self.PendingUID=nil end
end
function M:Action(action,payload)
 if not self.UID or self.Data.ActiveHeldPetUID~=self.UID then self:Close();return end
 if Bridge.Request(action,payload) then self.ActionPending=action end
end
function M:Update(data)
 self.Data=data
 if data and self.PendingUID and self.SelectionAccepted and data.ActiveHeldPetUID==self.PendingUID then self.UID=self.PendingUID;self.PendingUID=nil;self.SelectionAccepted=nil end
 local pet=data and self.UID and L.Find(data,self.UID)
 if self.UID and (not pet or pet.Location~='Held' or data.ActiveHeldPetUID~=self.UID)then self:Close();return end
 if not pet or self.Manager.Active or self.Screen:GetAttribute('RewardRevealActive')then return end
 self.Slot=pet.LocationSlot;W.Disabled(self.Sell,not Sell.Eligible(pet,'Held',data))
 if not self.Card.Visible then W.Motion.WindowOpen(self.Card);self.Manager:SetPopover(self.Card)end
 self:Position()
end
function M:Position()
 if not self.Card.Visible then return end
 local slot=self.Bar.Root:FindFirstChild('HeldSlot_'..tostring(self.Slot))
 if not slot or not self.Bar.Root.Visible then self:Close();return end
 local p=slot.AbsolutePosition-self.Root.AbsolutePosition
 self.Card.Position=UDim2.fromOffset(math.clamp(p.X+slot.AbsoluteSize.X/2-95,8,math.max(8,self.Root.AbsoluteSize.X-198)),math.max(8,p.Y-124))
end
function M:Close()
 local was=self.Card.Visible or self.PendingUID~=nil
 self.Card.Visible=false;self.UID=nil;self.PendingUID=nil;self.SelectionAccepted=nil;self.ActionPending=nil
 if self.Manager.Popover==self.Card then self.Manager:SetPopover(nil);self.Manager:Focus(self.Manager.Nav,'HeldSlot_'..tostring(self.Slot))end
 return was
end
function M:Destroy()self:Close();for _,c in ipairs(self.Connections)do c:Disconnect()end;self.Card:Destroy()end
return M
