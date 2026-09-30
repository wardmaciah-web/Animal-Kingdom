local W=require(script.Parent.GameplayWidgets)
local Cards=require(script.Parent.OwnedPetCards)
local Locations=require(game.ReplicatedStorage.Shared.Gameplay.PetLocations)
local M={};M.__index=M
function M.new(parent,selectPet)
 local self=setmetatable({SelectPet=selectPet},M)
 self.Root=W.New('Frame',{Name='HeldPets',BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,1),Size=UDim2.fromOffset(540,96),Position=UDim2.new(.5,0,1,-108)},parent)
 return self
end
function M:Update(data)
 self.Data=data;if not data then return end
 local signature={self.Large and 'large' or 'compact',data.ActiveHeldPetUID or ''}
 for i=1,5 do local pet=Locations.At(data,'Held',i);table.insert(signature,pet and (pet.UID..':'..tostring(pet.Weight)..':'..tostring(pet.CoinsPerSecond)..':'..tostring(pet.Favorite)..':'..tostring(pet.Locked)) or '-')end
 signature=table.concat(signature,'|');if signature==self.Signature then return end;self.Signature=signature
 self.Root:ClearAllChildren()
 for i=1,5 do
  local pet=Locations.At(data,'Held',i)
  local b=Cards.Card(self.Root,pet,'Slot '..i,UDim2.new(.2,-6,1,0),UDim2.new((i-1)*.2,3,0,0),function()if pet then self.SelectPet(pet)end end,pet~=nil and pet.UID==data.ActiveHeldPetUID,self.Large and 'heldLarge' or true)
  b.Name='HeldSlot_'..i;b:SetAttribute('PetUID',pet and pet.UID or '')
 end
 return true
end
function M:Resize(size,active,reveal)
 self.Root.Visible=not active and not reveal
 local compact=size.X<900 or size.Y<580
 local portrait=compact and size.X<500
 local wasLarge=self.Large;self.Large=not compact
 -- Keep the new bar below the existing right-side row and between touch controls.
 self.Root.Size=UDim2.fromOffset(portrait and size.X-24 or compact and math.max(310,math.min(430,size.X-300)) or 540,compact and 86 or 96)
 self.Root.Position=UDim2.new(.5,0,1,portrait and -150 or compact and -4 or -108)
 if self.Large~=wasLarge and self.Data then self:Update(self.Data)end
end
return M
