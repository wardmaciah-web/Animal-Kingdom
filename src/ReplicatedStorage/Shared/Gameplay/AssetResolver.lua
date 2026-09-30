local RS=game:GetService("ReplicatedStorage")
local Resolver={Categories={"Pets","Eggs","Trees","Resources","Furniture","Decorations","Seasonal"}}
function Resolver.EnsureFolders()
 assert(game:GetService("RunService"):IsServer(),"Asset folders are server-owned")
 local root=RS:FindFirstChild("Assets")
 if not root then root=Instance.new("Folder");root.Name="Assets";root.Parent=RS end
 for _,category in ipairs(Resolver.Categories) do
  if not root:FindFirstChild(category) then local folder=Instance.new("Folder");folder.Name=category;folder.Parent=root end
 end
 return root
end
local function part(model,name,size,color,offset,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=color;p.Material=Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 p.CFrame=CFrame.new(offset or Vector3.zero);if shape then p.Shape=shape end
 p.Parent=model;return p
end
function Resolver.Label(model,text,color)
 local root=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
 if not root then return end
 local old=root:FindFirstChild("AssetLabel");if old then old:Destroy() end
 local label=Instance.new("BillboardGui");label.Name="AssetLabel";label.Size=UDim2.fromOffset(180,48)
 label.StudsOffsetWorldSpace=Vector3.new(0,3,0);label.MaxDistance=85;label.AlwaysOnTop=false;label.Parent=root
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text
 t.Font=Enum.Font.GothamBold;t.TextSize=14;t.TextColor3=color or Color3.new(1,1,1);t.TextStrokeTransparency=.35;t.Parent=label
end
function Resolver.Create(category,id,label,color)
 local assets=RS:FindFirstChild("Assets");local folder=assets and assets:FindFirstChild(category)
 local template=folder and folder:FindFirstChild(id)
 local model
 if template and (template:IsA("Model") or template:IsA("BasePart")) then
  local clone=template:Clone()
  if clone:IsA("Model") then model=clone else model=Instance.new("Model");clone.Parent=model;model.PrimaryPart=clone end
  if not model:FindFirstChildWhichIsA("BasePart",true) then model:Destroy();model=nil end
 end
 if not model then
  model=Instance.new("Model");model:SetAttribute("Placeholder",true)
  local tint=color or Color3.fromRGB(122,199,139)
  if category=="Trees" then
   model.PrimaryPart=part(model,"Trunk",Vector3.new(1.7,6,1.7),Color3.fromRGB(126,85,53),Vector3.new(0,3,0))
   part(model,"Canopy",Vector3.new(7,6,7),tint,Vector3.new(0,7,0),Enum.PartType.Ball)
  elseif category=="Eggs" then model.PrimaryPart=part(model,"Egg",Vector3.new(3,4.2,3),tint,Vector3.new(0,2.1,0),Enum.PartType.Ball)
  elseif category=="Pets" then
   model.PrimaryPart=part(model,"Body",Vector3.new(2.6,2.4,2.5),tint,Vector3.zero,Enum.PartType.Ball)
   for _,x in ipairs({-.5,.5}) do part(model,"Eye",Vector3.new(.25,.3,.15),Color3.fromRGB(29,39,44),Vector3.new(x,.35,-1.2),Enum.PartType.Ball) end
  else model.PrimaryPart=part(model,"Body",Vector3.new(3,3,3),tint,Vector3.new(0,1.5,0)) end
 end
 model.Name=id
 local particleBudget=4
 for _,v in ipairs(model:GetDescendants()) do
  if v:IsA("BasePart") then v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false
  elseif v:IsA("ParticleEmitter") then
   v.Rate=math.min(v.Rate,particleBudget);particleBudget-=v.Rate
   v.Lifetime=NumberRange.new(math.min(v.Lifetime.Min,2),math.min(v.Lifetime.Max,2))
  elseif v:IsA("LuaSourceContainer") or v:IsA("ProximityPrompt") then v:Destroy() end
 end
 model.PrimaryPart=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
 -- Set an explicit stable pivot; geometry is never authoritative gameplay data.
 if model:GetAttribute("Placeholder") then
  -- A Model with PrimaryPart ignores WorldPivot. Align the part's pivot offset
  -- so generated trees/eggs rest at their logical base instead of half underground.
  model.PrimaryPart.PivotOffset=model.PrimaryPart.CFrame:ToObjectSpace(CFrame.new())
 end
 if label then Resolver.Label(model,label,color) end
 return model
end
return Resolver
