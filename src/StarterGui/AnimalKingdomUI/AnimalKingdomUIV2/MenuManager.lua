local Gui=game:GetService('GuiService')
local Input=game:GetService('UserInputService')
local Actions=game:GetService('ContextActionService')
local Motion=require(script.Parent.Motion)
local M={};M.__index=M
local function visible(o,root)
 local n=o
 while n and n~=root.Parent do if n:IsA('GuiObject') and not n.Visible then return false end;n=n.Parent end
 return true
end
function M.new(screen,panel,nav,onOpen,onClose)
 local self=setmetatable({Screen=screen,Panel=panel,Nav=nav,OnOpen=onOpen,OnClose=onClose,Active=nil,Modal=nil},M)
 local function back(_,state)
  if state~=Enum.UserInputState.Begin or Input:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
  if self.BackOverlay and self.BackOverlay() then return Enum.ContextActionResult.Sink end
  if self.Active then if self.BackScreen and self.BackScreen(self.Active) then return Enum.ContextActionResult.Sink end;self:Close();return Enum.ContextActionResult.Sink end
  return Enum.ContextActionResult.Pass
 end
 Actions:BindActionAtPriority('AnimalKingdomBack',back,false,2100,Enum.KeyCode.ButtonB)
 Actions:BindActionAtPriority('AnimalKingdomMenuInteraction',function()
  return (self.Active or self.Modal)and not Input:GetFocusedTextBox()and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
 end,false,2200,Enum.KeyCode.E,Enum.KeyCode.ButtonX)
 self.input=Input.InputBegan:Connect(function(key,processed)
  if not processed and key.KeyCode==Enum.KeyCode.Escape then back('',Enum.UserInputState.Begin) end
 end)
 self.last=Input.LastInputTypeChanged:Connect(function(kind)if kind.Name:find('Gamepad') then self:Focus(self.Modal or self.Popover or (self.Active and panel or nav)) end end)
 self.selection=Gui:GetPropertyChangedSignal('SelectedObject'):Connect(function()
  local chosen=Gui.SelectedObject;if not chosen or not chosen:IsDescendantOf(screen) then return end
  local ancestor=chosen.Parent
  while ancestor and ancestor~=screen do
   if ancestor:IsA('ScrollingFrame') then
    if ancestor.ScrollingDirection~=Enum.ScrollingDirection.Y then
     local dx=chosen.AbsolutePosition.X-ancestor.AbsolutePosition.X
     if dx<4 then ancestor.CanvasPosition=Vector2.new(math.max(0,ancestor.CanvasPosition.X+dx-4),ancestor.CanvasPosition.Y)
     elseif dx+chosen.AbsoluteSize.X>ancestor.AbsoluteSize.X-6 then ancestor.CanvasPosition+=Vector2.new(dx+chosen.AbsoluteSize.X-ancestor.AbsoluteSize.X+6,0)end
    end
    local delta=chosen.AbsolutePosition.Y-ancestor.AbsolutePosition.Y
    if delta<4 then ancestor.CanvasPosition=Vector2.new(ancestor.CanvasPosition.X,math.max(0,ancestor.CanvasPosition.Y+delta-4))
    elseif delta+chosen.AbsoluteSize.Y>ancestor.AbsoluteSize.Y-6 then ancestor.CanvasPosition+=Vector2.new(0,delta+chosen.AbsoluteSize.Y-ancestor.AbsoluteSize.Y+6) end
   end
   ancestor=ancestor.Parent
  end
 end)
 return self
end
function M:Graph(root)
 local buttons={}
 for _,o in ipairs(root:GetDescendants()) do if o:IsA('GuiButton') and o.Selectable and o.Active and visible(o,root) then table.insert(buttons,o) end end
 table.sort(buttons,function(a,b) local p,q=a.AbsolutePosition,b.AbsolutePosition;if math.abs(p.Y-q.Y)<10 then return p.X<q.X end;return p.Y<q.Y end)
 for i,b in ipairs(buttons) do
  local center=b.AbsolutePosition+b.AbsoluteSize/2
  for direction,v in pairs({Up=Vector2.new(0,-1),Down=Vector2.new(0,1),Left=Vector2.new(-1,0),Right=Vector2.new(1,0)}) do
   local best,score=nil,math.huge
   for _,other in ipairs(buttons) do if other~=b then
    local d=other.AbsolutePosition+other.AbsoluteSize/2-center;local forward=d:Dot(v);local side=math.abs(d:Dot(Vector2.new(-v.Y,v.X)))
    if forward>8 then local s=forward+side*3;if s<score then best=other;score=s end end
   end end
   b['NextSelection'..direction]=best or ((direction=='Up' or direction=='Left') and buttons[i-1] or buttons[i+1]) or b
  end
 end
 return buttons
end
function M:Focus(root,preferred)
 task.defer(function()
  if not root or not root.Parent then return end
  local list=self:Graph(root);local selected
  if preferred then for _,b in ipairs(list) do if b.Name==preferred then selected=b;break end end end
  if Input:GetLastInputType().Name:find('Gamepad') or (Gui.SelectedObject and Gui.SelectedObject:IsDescendantOf(self.Screen)) then Gui.SelectedObject=selected or list[1] end
 end)
end
function M:Open(name)
 if self.Active==name then self:Close();return end
 self.Active=name;self.Screen:SetAttribute('ActiveMenu',name)
 self.OnOpen(name);Motion.WindowOpen(self.Panel);self:Focus(self.Panel)
end
function M:Close()
 if not self.Active then return end
 local previous=self.Active;self.Active=nil;self.Screen:SetAttribute('ActiveMenu','')
 Motion.WindowClose(self.Panel,function()
  if not self.Active then self.OnClose(previous);self:Focus(self.Nav,'Nav_'..previous)end
 end)
end
function M:SetPopover(root) self.Popover=root;if root then self:Focus(root)end end
function M:SetModal(root) self.Modal=root;self.Screen:SetAttribute('ModalActive',root~=nil);self:Focus(root or (self.Active and self.Panel or self.Nav)) end
function M:Destroy()
 self.input:Disconnect();self.last:Disconnect();self.selection:Disconnect()
 local replacement=game.Players.LocalPlayer.PlayerGui:FindFirstChild(self.Screen.Name)
 if not replacement or replacement==self.Screen then Actions:UnbindAction('AnimalKingdomBack');Actions:UnbindAction('AnimalKingdomMenuInteraction')end
end
return M
