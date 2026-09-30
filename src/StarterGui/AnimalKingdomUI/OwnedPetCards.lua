local RS=game:GetService('ReplicatedStorage')
local W=require(script.Parent.GameplayWidgets)
local Definitions=require(RS.Shared.Gameplay.Definitions.PetDefinitions)
local Rarities=require(RS.Shared.Gameplay.Definitions.RarityDefinitions)
local Format=require(RS.Shared.Gameplay.PetNumberFormat)
local M={}
function M.Card(parent,pet,caption,size,position,callback,selected,compact)
 local def=pet and Definitions[pet.PetId]
 local button=W.New('TextButton',{Name='PetSlot_'..(pet and pet.UID or caption),Text='',Size=size,Position=position or UDim2.new(),BackgroundColor3=selected and W.Color.Garden or W.Color.Card,BorderSizePixel=0,ClipsDescendants=true},parent)
 W.Round(button,12);W.Stroke(button,selected and W.Color.Gold or W.Color.Line,selected and 3 or 1.5)
 local wide=compact=='wide'
 local large=compact=='heldLarge'
 local h=wide and 74 or large and 40 or compact and 28 or 64
 if pet and def then W.PetPreview(button,pet,UDim2.new(1,-12,0,h),UDim2.fromOffset(6,compact and 2 or 5))
 else W.Icon(button,'Leaf',UDim2.fromOffset(24,24),UDim2.new(.5,-12,0,compact and 4 or 20))end
 local y=wide and 5 or compact and 30 or 72
 local name=W.Heading(button,def and def.DisplayName or caption,UDim2.new(1,-8,0,compact and 23 or 30),UDim2.fromOffset(4,y),compact and 11 or 14)
 name.TextXAlignment=Enum.TextXAlignment.Center;name.TextScaled=true
 W.New('UITextSizeConstraint',{MinTextSize=8,MaxTextSize=compact and 11 or 14},name)
 if pet then
  local color=def and Rarities[def.Rarity].Color or W.Color.Muted
  local rarity=W.Text(button,def and def.Rarity or 'Archived',UDim2.new(1,-6,0,13),UDim2.fromOffset(3,y+(compact and 23 or 31)),compact and 8 or 10,color:Lerp(W.Color.Ink,.4));rarity.TextXAlignment=Enum.TextXAlignment.Center
  local weight=W.Text(button,Format.Weight(pet.Weight),UDim2.new(1,-6,0,16),UDim2.fromOffset(3,y+(compact and 34 or 45)),compact and 10 or 12);weight.TextXAlignment=Enum.TextXAlignment.Center
  local income=W.Text(button,Format.Income(pet.CoinsPerSecond),UDim2.new(1,-6,0,16),UDim2.fromOffset(3,y+(compact and 50 or 63)),compact and 9 or 12,W.Color.GreenDark);income.TextXAlignment=Enum.TextXAlignment.Center
  if compact and not wide then
   -- Two stat rows remain legible at phone width; share the name/rarity line.
   name.Size=UDim2.new(1,-8,0,22)
   rarity.Position=UDim2.fromOffset(3,51);rarity.Size=UDim2.new(1,-6,0,10);rarity.TextSize=8
   weight.Position=UDim2.fromOffset(3,61);weight.Size=UDim2.new(.5,-3,0,21);weight.TextSize=9
   income.Position=UDim2.new(.5,0,0,61);income.Size=UDim2.new(.5,-3,0,21);income.TextSize=8
   if large then
    name.Position=UDim2.fromOffset(4,40);name:FindFirstChildWhichIsA('UITextSizeConstraint').MaxTextSize=13
    rarity.Position=UDim2.fromOffset(3,63);rarity.TextSize=10
    weight.Position=UDim2.fromOffset(3,75);weight.TextSize=11
    income.Position=UDim2.new(.5,0,0,75);income.TextSize=10
   end
  elseif wide then
   local preview=button:FindFirstChildWhichIsA('ViewportFrame')
   if preview then preview.Size=UDim2.new(.36,-8,1,-12);preview.Position=UDim2.fromOffset(4,6)end
   for _,label in ipairs({name,rarity,weight,income})do
    label.Position=UDim2.new(.36,2,0,label.Position.Y.Offset);label.Size=UDim2.new(.64,-8,0,label.Size.Y.Offset)
   end
   name.TextSize=14;name:FindFirstChildWhichIsA('UITextSizeConstraint').MaxTextSize=14
   rarity.TextSize=10;weight.TextSize=12;income.TextSize=12
  end
  if pet.Locked then local state=W.Text(button,'LOCKED',UDim2.fromOffset(52,16),UDim2.fromOffset(3,2),9,W.Color.Ink);state.Name='LockState' end
  if pet.Favorite then W.Heading(button,'★',UDim2.fromOffset(20,20),UDim2.new(1,-23,0,3),15,W.Color.Gold)end
  button:SetAttribute('OwnedPetInstanceId',pet.UID);button:SetAttribute('PetWeight',pet.Weight);button:SetAttribute('PetLocation',pet.Location)
 else
  if wide then name.Position=UDim2.new(.36,2,0,8);name.Size=UDim2.new(.64,-8,0,28);local icon=button:FindFirstChild('Icon_Leaf');if icon then icon.Position=UDim2.new(.18,-12,.5,-12)end end
  local hint=W.Text(button,'Empty',UDim2.new(1,-8,0,20),UDim2.fromOffset(4,y+28),11,W.Color.Muted);hint.TextXAlignment=Enum.TextXAlignment.Center
  if wide then hint.Position=UDim2.new(.36,2,0,42);hint.Size=UDim2.new(.64,-8,0,22)end
 end
 W.Bind(button,callback)
 return button
end
return M
