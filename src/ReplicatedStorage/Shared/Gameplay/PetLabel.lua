local Geometry=require(script.Parent.PetVisualGeometry)
local Format=require(script.Parent.PetNumberFormat)
local Definitions=require(script.Parent.Definitions.PetDefinitions)
local Rarities=require(script.Parent.Definitions.RarityDefinitions)
local M={}
function M.Position(model)
 local root=model.PrimaryPart;local anchor=root and root:FindFirstChild('PetInformationAnchor')
 if not anchor then return end
 local bounds=Geometry.Measure(model,root.CFrame)
 if bounds then anchor.Position=Vector3.new(bounds.Center.X,bounds.Max.Y+.45,bounds.Center.Z)end
end
function M.Attach(model,pet,context)
 local def=Definitions[pet.PetId];local root=model.PrimaryPart
 if not root or not def or context=='Preview' then return end
 local anchor=Instance.new('Attachment');anchor.Name='PetInformationAnchor';anchor.Parent=root
 local gui=Instance.new('BillboardGui');gui.Name='PetInformation';gui.Adornee=anchor
 gui.Size=UDim2.fromOffset(166,65);gui.MaxDistance=context=='Display' and 38 or 42;gui.AlwaysOnTop=false;gui.Parent=root
 local panel=Instance.new('Frame');panel.Size=UDim2.fromScale(1,1);panel.BackgroundColor3=Color3.fromRGB(58,40,26);panel.BackgroundTransparency=.15;panel.BorderSizePixel=0;panel.Parent=gui
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,9);corner.Parent=panel
 local stroke=Instance.new('UIStroke');stroke.Color=Rarities[def.Rarity].Color;stroke.Transparency=.35;stroke.Thickness=1;stroke.Parent=panel
 for i,row in ipairs({{'PetName',def.DisplayName,Rarities[def.Rarity].Color},{'PetWeight',Format.Weight(pet.Weight or def.BaseWeight),Color3.fromRGB(255,245,220)},{'PetIncome',Format.Income(pet.CoinsPerSecond or 0),Color3.fromRGB(197,235,155)}})do
  local label=Instance.new('TextLabel');label.Name=row[1];label.BackgroundTransparency=1;label.Size=UDim2.new(1,-12,0,19);label.Position=UDim2.fromOffset(6,3+(i-1)*20)
  label.Text=row[2];label.TextColor3=row[3];label.TextScaled=true;label.Font=i==1 and Enum.Font.FredokaOne or Enum.Font.GothamMedium;label.TextStrokeTransparency=.7;label.Parent=panel
  local limit=Instance.new('UITextSizeConstraint');limit.MinTextSize=10;limit.MaxTextSize=14;limit.Parent=label
 end
 M.Position(model)
end
return M
